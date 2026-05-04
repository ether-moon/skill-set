#!/bin/bash
# Peer Review Script for consulting-peer-llms skill
# Executes multiple LLM CLI tools in parallel and writes per-CLI responses to
# a persistent output directory. Stdout stays bounded (status only) so that
# consumers can never lose response data through truncation, paging, or
# pipes such as `tail`/`head`/`grep`.
# Compatible with Bash 3.2+ (macOS default) and Linux.

set -e

# ============================================================================
# Configuration
# ============================================================================

TIMEOUT="${TIMEOUT:-1200s}"  # 20 minutes default timeout

# Output directory for per-CLI response files. Override with PEER_REVIEW_DIR.
# Files inside are not deleted by this script — callers read them with their
# Read tool and may clean up afterward.
OUTPUT_DIR="${PEER_REVIEW_DIR:-/tmp/peer-review-$$}"

# CLI registry: "id|command-template"
# - {PROMPT} is replaced with the review prompt (single argument)
# - {OUT} is replaced with the output file path
# - If the template contains {OUT}, the CLI writes directly to the file;
#   otherwise stdout is redirected to the output file.
# - The binary name is the first token of the template.
# Add a new CLI by appending one row — no other changes required.
CLI_REGISTRY=(
    "gemini|gemini -p {PROMPT}"
    "codex|codex exec -o {OUT} {PROMPT}"
    "claude|claude -p {PROMPT}"
)

# Resolve timeout command: timeout (Linux) or gtimeout (macOS via coreutils)
TIMEOUT_CMD=""
if command -v timeout &> /dev/null; then
    TIMEOUT_CMD="timeout"
elif command -v gtimeout &> /dev/null; then
    TIMEOUT_CMD="gtimeout"
fi

# ============================================================================
# Helpers
# ============================================================================

# Run a command with timeout if available, otherwise run directly
run_cmd() {
    if [ -n "$TIMEOUT_CMD" ]; then
        "$TIMEOUT_CMD" "$TIMEOUT" "$@"
    else
        "$@"
    fi
}

# ============================================================================
# CLI Registry Lookup
# ============================================================================

# Echo the command template for a given CLI id; return 1 if unknown.
cli_template() {
    local cli="$1"
    local entry id
    for entry in "${CLI_REGISTRY[@]}"; do
        id="${entry%%|*}"
        if [ "$id" = "$cli" ]; then
            echo "${entry#*|}"
            return 0
        fi
    done
    return 1
}

# Echo the binary name (first token of template) for a given CLI id.
cli_binary() {
    local template
    template=$(cli_template "$1") || return 1
    echo "${template%% *}"
}

# ============================================================================
# CLI Detection and Selection
# ============================================================================

# Usage: get_target_clis [cli1] [cli2] ...
# If no arguments, returns all registered CLIs whose binary is installed.
get_target_clis() {
    local requested_clis=("$@")
    local target_clis=()
    local entry id binary cli

    if [ ${#requested_clis[@]} -eq 0 ]; then
        for entry in "${CLI_REGISTRY[@]}"; do
            id="${entry%%|*}"
            binary="${entry#*|}"
            binary="${binary%% *}"
            if command -v "$binary" &> /dev/null; then
                target_clis+=("$id")
            fi
        done
    else
        for cli in "${requested_clis[@]}"; do
            binary=$(cli_binary "$cli") || binary="$cli"
            if command -v "$binary" &> /dev/null; then
                target_clis+=("$cli")
            else
                echo "Warning: $cli not found, skipping" >&2
            fi
        done
    fi

    echo "${target_clis[@]}"
}

# ============================================================================
# CLI Execution
# ============================================================================

# Build argv from a template, substituting {PROMPT} and {OUT}.
# Sets globals: BUILT_ARGS (array) and TEMPLATE_HAS_OUT (0/1).
# Bash 3.2 has no reference parameters, so globals keep this simple.
build_cli_args() {
    local template="$1"
    local prompt="$2"
    local output_file="$3"

    BUILT_ARGS=()
    TEMPLATE_HAS_OUT=0

    # Word-split the template on IFS via `read` to avoid pathname expansion.
    local parts=()
    read -ra parts <<< "$template"
    local part
    for part in "${parts[@]}"; do
        case "$part" in
            '{PROMPT}') BUILT_ARGS+=("$prompt") ;;
            '{OUT}')    BUILT_ARGS+=("$output_file"); TEMPLATE_HAS_OUT=1 ;;
            *)          BUILT_ARGS+=("$part") ;;
        esac
    done
}

# Execute a single CLI with the given prompt.
# Stdout goes to $output_file (or via the CLI's own {OUT} flag).
# Stderr is captured to a sibling ${output_file}.err so that empty responses
# and failures remain diagnosable.
execute_cli() {
    local cli="$1"
    local prompt="$2"
    local output_file="$3"
    local err_file="${output_file}.err"

    # Start every invocation with empty files. Shell-redirect mode (`>`) already
    # truncates, but {OUT}-mode CLIs (e.g. `codex exec -o`) write through the
    # path themselves — if they fail before writing, content from a prior run
    # under the same PEER_REVIEW_DIR would otherwise linger and the status
    # block would point the agent at stale data.
    : > "$output_file"
    : > "$err_file"

    local template
    if ! template=$(cli_template "$cli"); then
        run_cmd "$cli" "$prompt" > "$output_file" 2>"$err_file"
        return $?
    fi

    build_cli_args "$template" "$prompt" "$output_file"

    if [ "$TEMPLATE_HAS_OUT" = "1" ]; then
        run_cmd "${BUILT_ARGS[@]}" >/dev/null 2>"$err_file"
    else
        run_cmd "${BUILT_ARGS[@]}" >"$output_file" 2>"$err_file"
    fi
}

# Print a short status line for a single CLI after it has been collected.
# $1=cli  $2=status (OK|EMPTY|FAILED)  $3=output_file  $4=err_file
print_cli_status() {
    local cli="$1" status="$2" output_file="$3" err_file="$4"
    local lines=0 err_summary=""

    if [ -s "$output_file" ]; then
        lines=$(wc -l < "$output_file" | tr -d ' ')
    fi
    if [ "$status" != "OK" ] && [ -s "$err_file" ]; then
        # First line of stderr — keep status block compact.
        err_summary=$(head -n1 "$err_file" | tr -d '\r')
    fi

    if [ -n "$err_summary" ]; then
        printf '  %-7s %-7s %s  (%d lines, stderr: %s)\n' \
            "$cli" "$status" "$output_file" "$lines" "$err_summary"
    else
        printf '  %-7s %-7s %s  (%d lines)\n' \
            "$cli" "$status" "$output_file" "$lines"
    fi
}

# Execute all CLIs in parallel, then print a bounded status block.
# Per-CLI response bodies are NEVER streamed through stdout — consumers must
# read them via the file paths printed below. This is the design that makes
# the pipeline truncation-proof.
# Usage: execute_all_clis <prompt> <cli1> [cli2] ...
execute_all_clis() {
    local prompt="$1"
    shift
    local clis=("$@")
    local pids=()
    local files=()
    local cli output_file

    mkdir -p "$OUTPUT_DIR"

    # Launch all CLIs in parallel
    for cli in "${clis[@]}"; do
        output_file="$OUTPUT_DIR/${cli}.txt"
        files+=("$output_file")
        execute_cli "$cli" "$prompt" "$output_file" &
        pids+=($!)
    done

    # Wait for completion and collect statuses
    local i=0 pid err_file status
    local -a statuses
    for cli in "${clis[@]}"; do
        pid="${pids[$i]}"
        output_file="${files[$i]}"
        err_file="${output_file}.err"

        if wait "$pid"; then
            if [ -s "$output_file" ]; then
                status="OK"
            else
                status="EMPTY"
            fi
        else
            status="FAILED"
        fi
        statuses+=("$cli|$status|$output_file|$err_file")
        i=$((i + 1))
    done

    # Bounded status block — agent reads each response file with the Read tool.
    echo "PEER_REVIEW_DIR=$OUTPUT_DIR"
    echo "Responses (read each file individually — do NOT pipe through head/tail/grep):"
    local entry s_cli s_status s_out s_err
    for entry in "${statuses[@]}"; do
        s_cli="${entry%%|*}"
        local rest="${entry#*|}"
        s_status="${rest%%|*}"
        rest="${rest#*|}"
        s_out="${rest%%|*}"
        s_err="${rest#*|}"
        print_cli_status "$s_cli" "$s_status" "$s_out" "$s_err"
    done
}

# ============================================================================
# Main Entry Points
# ============================================================================

# Check which CLIs are available
check_available_clis() {
    echo "Checking available CLI tools..."
    local entry id binary
    for entry in "${CLI_REGISTRY[@]}"; do
        id="${entry%%|*}"
        binary="${entry#*|}"
        binary="${binary%% *}"
        if command -v "$binary" &> /dev/null; then
            echo "  $id: installed"
        else
            echo "  $id: not found"
        fi
    done

    if [ -n "$TIMEOUT_CMD" ]; then
        echo "  timeout: $TIMEOUT_CMD"
    else
        echo "  timeout: not found (CLIs will run without timeout)"
    fi
}

# Print usage
usage() {
    echo "Usage: peer-review.sh [command] [options]"
    echo ""
    echo "Commands:"
    echo "  check     - Check which CLI tools are available"
    echo "  execute   - Execute review with specified CLIs"
    echo ""
    echo "Examples:"
    echo "  peer-review.sh check"
    echo "  peer-review.sh execute 'Review prompt here' gemini codex"
    echo ""
    echo "Output:"
    echo "  Each CLI's response is written to \$PEER_REVIEW_DIR/<cli>.txt"
    echo "  (default /tmp/peer-review-\$\$). Stdout prints status only."
}

# Main
case "${1:-}" in
    check)
        check_available_clis
        ;;
    execute)
        shift
        prompt="$1"
        shift
        clis=($(get_target_clis "$@"))

        if [ ${#clis[@]} -eq 0 ]; then
            echo "Error: No CLI tools available" >&2
            exit 1
        fi

        echo "Executing with CLIs: ${clis[*]}"
        execute_all_clis "$prompt" "${clis[@]}"
        ;;
    *)
        usage
        ;;
esac

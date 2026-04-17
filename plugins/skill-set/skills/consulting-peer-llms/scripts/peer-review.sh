#!/bin/bash
# Peer Review Script for consulting-peer-llms skill
# Executes multiple LLM CLI tools in parallel and collects results
# Compatible with Bash 3.2+ (macOS default) and Linux

set -e

# ============================================================================
# Configuration
# ============================================================================

TIMEOUT="${TIMEOUT:-1200s}"  # 20 minutes default timeout

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

# Portable uppercase
to_upper() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

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
# Stdout goes to $output_file (or $output_file via {OUT} flag).
# Stderr is always captured to a sibling ${output_file}.err so that
# empty responses and failures remain diagnosable.
execute_cli() {
    local cli="$1"
    local prompt="$2"
    local output_file="$3"
    local err_file="${output_file}.err"

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

# Execute all CLIs in parallel
# Usage: execute_all_clis <prompt> <cli1> [cli2] ...
execute_all_clis() {
    local prompt="$1"
    shift
    local clis=("$@")
    local pids=()
    local files=()
    local cli output_file

    # Launch all CLIs in parallel
    for cli in "${clis[@]}"; do
        output_file="/tmp/${cli}-review-$$.txt"
        files+=("$output_file")
        execute_cli "$cli" "$prompt" "$output_file" &
        pids+=($!)
    done

    # Wait and collect results
    local i=0 pid err_file cli_upper
    for cli in "${clis[@]}"; do
        pid="${pids[$i]}"
        output_file="${files[$i]}"
        err_file="${output_file}.err"
        cli_upper=$(to_upper "$cli")

        echo "=== ${cli_upper} REVIEW ==="
        if wait "$pid"; then
            if [ -s "$output_file" ]; then
                cat "$output_file"
            else
                echo "[Empty response from $cli]"
                if [ -s "$err_file" ]; then
                    echo "[stderr]"
                    cat "$err_file"
                fi
            fi
        else
            echo "[$cli CLI failed or timed out]"
            if [ -s "$err_file" ]; then
                echo "[stderr]"
                cat "$err_file"
            fi
        fi
        echo ""
        echo "=== END ${cli_upper} REVIEW ==="
        echo ""

        rm -f "$output_file" "$err_file"
        i=$((i + 1))
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

#!/bin/bash
# Peer Review Script for consulting-peer-llms skill
# Executes multiple LLM CLI tools in parallel and collects results
# Compatible with Bash 3.2+ (macOS default) and Linux

set -e

# ============================================================================
# Configuration
# ============================================================================

TIMEOUT="${TIMEOUT:-1200s}"  # 20 minutes default timeout

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
# CLI Detection and Selection
# ============================================================================

# Usage: get_target_clis [cli1] [cli2] ...
# If no arguments, returns all installed CLIs from default set
get_target_clis() {
    local requested_clis=("$@")
    local default_clis=("gemini" "codex" "claude")
    local target_clis=()

    if [ ${#requested_clis[@]} -eq 0 ]; then
        # No arguments - use defaults that are installed
        for cli in "${default_clis[@]}"; do
            if command -v "$cli" &> /dev/null; then
                target_clis+=("$cli")
            fi
        done
    else
        # Use specified CLIs (skip if not installed)
        for cli in "${requested_clis[@]}"; do
            if command -v "$cli" &> /dev/null; then
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

# Execute a single CLI with the given prompt
# Usage: execute_cli <cli_name> <prompt> <output_file>
execute_cli() {
    local cli="$1"
    local prompt="$2"
    local output_file="$3"

    case "$cli" in
        gemini)  run_cmd gemini -p "$prompt" > "$output_file" 2>/dev/null ;;
        codex)   run_cmd codex exec "$prompt" > "$output_file" 2>/dev/null ;;
        claude)  run_cmd claude -p "$prompt" > "$output_file" 2>/dev/null ;;
        *)       run_cmd "$cli" "$prompt" > "$output_file" 2>/dev/null ;;
    esac
}

# Execute all CLIs in parallel
# Usage: execute_all_clis <prompt> <cli1> [cli2] ...
execute_all_clis() {
    local prompt="$1"
    shift
    local clis=("$@")
    local pids=()
    local files=()

    # Launch all CLIs in parallel
    for cli in "${clis[@]}"; do
        local output_file="/tmp/${cli}-review-$$.txt"
        files+=("$output_file")

        execute_cli "$cli" "$prompt" "$output_file" &
        pids+=($!)
    done

    # Wait and collect results
    local i=0
    for cli in "${clis[@]}"; do
        local pid="${pids[$i]}"
        local output_file="${files[$i]}"
        local cli_upper
        cli_upper=$(to_upper "$cli")

        if wait "$pid"; then
            if [ -s "$output_file" ]; then
                echo "=== ${cli_upper} REVIEW ==="
                cat "$output_file"
                echo ""
                echo "=== END ${cli_upper} REVIEW ==="
                echo ""
            else
                echo "=== ${cli_upper} REVIEW ==="
                echo "[Empty response from $cli]"
                echo "=== END ${cli_upper} REVIEW ==="
                echo ""
            fi
        else
            echo "=== ${cli_upper} REVIEW ==="
            echo "[$cli CLI failed or timed out]"
            echo "=== END ${cli_upper} REVIEW ==="
            echo ""
        fi

        # Cleanup
        rm -f "$output_file"
        i=$((i + 1))
    done
}

# ============================================================================
# Main Entry Points
# ============================================================================

# Check which CLIs are available
check_available_clis() {
    echo "Checking available CLI tools..."
    local default_clis=("gemini" "codex" "claude")

    for cli in "${default_clis[@]}"; do
        if command -v "$cli" &> /dev/null; then
            echo "  $cli: installed"
        else
            echo "  $cli: not found"
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

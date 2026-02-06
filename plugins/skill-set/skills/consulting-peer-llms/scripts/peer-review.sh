#!/bin/bash
# Peer Review Script for consulting-peer-llms skill
# Executes multiple LLM CLI tools in parallel and collects results

set -e

# ============================================================================
# Configuration
# ============================================================================

TIMEOUT="${TIMEOUT:-1200s}"  # 20 minutes default timeout

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
# Git Context
# ============================================================================

# Get base SHA for comparison
get_base_sha() {
    git rev-parse origin/main 2>/dev/null || \
    git rev-parse origin/master 2>/dev/null || \
    echo "HEAD~1"
}

# Get current SHA
get_current_sha() {
    git rev-parse HEAD
}

# Get changed files summary
get_changes_summary() {
    local base_sha="$1"
    local current_sha="$2"

    echo "Changed files:"
    git diff --name-only "$base_sha..$current_sha" 2>/dev/null || echo "(no changes)"
    echo ""
    echo "Change summary:"
    git diff --stat "$base_sha..$current_sha" 2>/dev/null || echo "(no stats)"
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
        gemini)
            timeout "$TIMEOUT" gemini -p "$prompt" > "$output_file" 2>/dev/null
            ;;
        codex)
            timeout "$TIMEOUT" codex exec "$prompt" > "$output_file" 2>/dev/null
            ;;
        claude)
            timeout "$TIMEOUT" claude -p "$prompt" > "$output_file" 2>/dev/null
            ;;
        *)
            # Generic execution for unknown CLIs
            timeout "$TIMEOUT" "$cli" "$prompt" > "$output_file" 2>/dev/null
            ;;
    esac
}

# Execute all CLIs in parallel
# Usage: execute_all_clis <prompt> <cli1> [cli2] ...
# Returns: Associative array of results via temp files
execute_all_clis() {
    local prompt="$1"
    shift
    local clis=("$@")

    declare -A pids
    declare -A files

    # Launch all CLIs in parallel
    for cli in "${clis[@]}"; do
        local output_file="/tmp/${cli}-review-$$.txt"
        files[$cli]="$output_file"

        execute_cli "$cli" "$prompt" "$output_file" &
        pids[$cli]=$!
    done

    # Wait and collect results
    for cli in "${clis[@]}"; do
        local pid="${pids[$cli]}"
        local output_file="${files[$cli]}"

        if wait "$pid"; then
            if [ -s "$output_file" ]; then
                echo "=== ${cli^^} REVIEW ==="
                cat "$output_file"
                echo ""
                echo "=== END ${cli^^} REVIEW ==="
                echo ""
            else
                echo "=== ${cli^^} REVIEW ==="
                echo "[Empty response from $cli]"
                echo "=== END ${cli^^} REVIEW ==="
                echo ""
            fi
        else
            echo "=== ${cli^^} REVIEW ==="
            echo "[$cli CLI failed or timed out]"
            echo "=== END ${cli^^} REVIEW ==="
            echo ""
        fi

        # Cleanup
        rm -f "$output_file"
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
}

# Print usage
usage() {
    echo "Usage: peer-review.sh [command] [options]"
    echo ""
    echo "Commands:"
    echo "  check     - Check which CLI tools are available"
    echo "  context   - Get git context (base SHA, current SHA, changes)"
    echo "  execute   - Execute review with specified CLIs"
    echo ""
    echo "Examples:"
    echo "  peer-review.sh check"
    echo "  peer-review.sh context"
    echo "  peer-review.sh execute 'Review prompt here' gemini codex"
}

# Main
case "${1:-}" in
    check)
        check_available_clis
        ;;
    context)
        base=$(get_base_sha)
        current=$(get_current_sha)
        echo "Base SHA: $base"
        echo "Current SHA: $current"
        echo ""
        get_changes_summary "$base" "$current"
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

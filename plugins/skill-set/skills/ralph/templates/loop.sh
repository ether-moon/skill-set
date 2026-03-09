#!/bin/bash
# Ralph Loop — external bash loop with fresh context per iteration
# Based on Geoffrey Huntley's Ralph Wiggum technique
#
# REFERENCE ONLY: This template is kept for documentation purposes.
# The ralph skill now executes loops directly via Task subagents.
# This script serves as reference for users who prefer external bash execution.
#
# Usage: ./loop.sh [plan|max_iterations]
#   ./loop.sh              # build mode, unlimited (Ctrl+C to stop)
#   ./loop.sh 20           # build mode, max 20 iterations
#   ./loop.sh plan         # plan mode, unlimited

set -euo pipefail

# Parse arguments
if [ "${1:-}" = "plan" ]; then
    MODE="plan"
    PROMPT_FILE="{{PROMPT_PLAN_FILE}}"
    MAX_ITERATIONS=${2:-0}
elif [[ "${1:-}" =~ ^[0-9]+$ ]]; then
    MODE="build"
    PROMPT_FILE="{{PROMPT_BUILD_FILE}}"
    MAX_ITERATIONS=$1
else
    MODE="build"
    PROMPT_FILE="{{PROMPT_BUILD_FILE}}"
    MAX_ITERATIONS=0
fi

ITERATION=0
STUCK_COUNT=0
SPEC_FILE="{{SPEC_FILE}}"
MODEL="{{MODEL}}"
CURRENT_BRANCH=$(git branch --show-current)

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Ralph Loop"
echo "   Mode:   $MODE"
echo "   Branch: $CURRENT_BRANCH"
echo "   Spec:   $SPEC_FILE"
echo "   Model:  $MODEL"
[ "$MAX_ITERATIONS" -gt 0 ] && echo "   Max:    $MAX_ITERATIONS iterations"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Pre-flight checks
command -v claude >/dev/null 2>&1 || { echo "ERROR: claude CLI not found in PATH"; exit 1; }
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "ERROR: not inside a git repository"; exit 1; }
[ -f "$PROMPT_FILE" ] || { echo "ERROR: $PROMPT_FILE not found"; exit 1; }

while true; do
    # Check iteration limit
    if [ "$MAX_ITERATIONS" -gt 0 ] && [ "$ITERATION" -ge "$MAX_ITERATIONS" ]; then
        echo "Reached max iterations: $MAX_ITERATIONS"; break
    fi

    ITERATION=$((ITERATION + 1))
    echo ""
    echo "==========================================="
    echo "  Iteration $ITERATION"
    echo "==========================================="

    # Save current HEAD for progress detection
    PREV_HEAD=$(git rev-parse HEAD 2>/dev/null || echo "none")
    PREV_SPEC_HASH=$(md5sum "$SPEC_FILE" 2>/dev/null | cut -d' ' -f1 || echo "none")

    # Run Claude with fresh context
    cat "$PROMPT_FILE" | claude -p \
        --dangerously-skip-permissions \
        --model "$MODEL" \
        --verbose

    # Circuit breaker: detect no progress via git commits and spec changes
    CURR_HEAD=$(git rev-parse HEAD 2>/dev/null || echo "none")
    CURR_SPEC_HASH=$(md5sum "$SPEC_FILE" 2>/dev/null | cut -d' ' -f1 || echo "none")

    if [ "$CURR_HEAD" = "$PREV_HEAD" ] && [ "$CURR_SPEC_HASH" = "$PREV_SPEC_HASH" ]; then
        STUCK_COUNT=$((STUCK_COUNT + 1))
        echo "  Warning: No progress detected ($STUCK_COUNT consecutive)"
        if [ "$STUCK_COUNT" -ge 3 ]; then
            echo "STUCK: No progress for 3 consecutive iterations. Stopping."
            echo "Review the spec, then restart."
            break
        fi
    else
        STUCK_COUNT=0
    fi

    # Brief cooldown for API rate limits
    sleep 2
done

echo ""
echo "========================================"
echo "  Ralph Loop Complete"
echo "  Mode:       $MODE"
echo "  Iterations: $ITERATION"
echo "  Spec:       $SPEC_FILE"
echo "========================================"

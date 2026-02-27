#!/bin/bash
# Ralph Loop — external bash loop with fresh context per iteration
# Based on Geoffrey Huntley's Ralph Wiggum technique
#
# Usage: ./ralph/loop.sh [max_iterations]
#   ./ralph/loop.sh          # unlimited (Ctrl+C to stop)
#   ./ralph/loop.sh 20       # max 20 iterations

set -euo pipefail

MAX_ITERATIONS=${1:-0}
ITERATION=0
STUCK_COUNT=0
PREV_REMAINING=0
PROMPT_FILE="ralph/PROMPT_build.md"
PLAN_FILE="{{PLAN_FILE}}"
MODEL="{{MODEL}}"
CURRENT_BRANCH=$(git branch --show-current)

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Ralph Loop"
echo "   Branch: $CURRENT_BRANCH"
echo "   Plan:   $PLAN_FILE"
echo "   Model:  $MODEL"
[ "$MAX_ITERATIONS" -gt 0 ] && echo "   Max:    $MAX_ITERATIONS iterations"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Pre-flight checks
command -v claude >/dev/null 2>&1 || { echo "ERROR: claude CLI not found in PATH"; exit 1; }
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "ERROR: not inside a git repository"; exit 1; }
for f in "$PROMPT_FILE" "$PLAN_FILE"; do
    [ -f "$f" ] || { echo "ERROR: $f not found"; exit 1; }
done

while true; do
    # Check iteration limit
    if [ "$MAX_ITERATIONS" -gt 0 ] && [ "$ITERATION" -ge "$MAX_ITERATIONS" ]; then
        echo "Reached max iterations: $MAX_ITERATIONS"; break
    fi

    # Count tasks (anchored to line-start checkbox pattern)
    REMAINING=$(grep -c '^[[:space:]]*[-*][[:space:]]\[ \]' "$PLAN_FILE" 2>/dev/null || echo 0)
    BLOCKED=$(grep -c '^[[:space:]]*[-*][[:space:]]\[!\]' "$PLAN_FILE" 2>/dev/null || echo 0)
    DONE=$(grep -c '^[[:space:]]*[-*][[:space:]]\[x\]' "$PLAN_FILE" 2>/dev/null || echo 0)

    if [ "$REMAINING" -eq 0 ]; then
        echo "All tasks complete! ($DONE done, $BLOCKED blocked)"
        break
    fi

    ITERATION=$((ITERATION + 1))
    echo ""
    echo "==========================================="
    echo "  Iteration $ITERATION — $REMAINING remaining, $DONE done, $BLOCKED blocked"
    echo "==========================================="

    # Run Claude with fresh context
    cat "$PROMPT_FILE" | claude -p \
        --dangerously-skip-permissions \
        --model "$MODEL" \
        --verbose

    # Circuit breaker: detect no progress
    NEW_REMAINING=$(grep -c '^[[:space:]]*[-*][[:space:]]\[ \]' "$PLAN_FILE" 2>/dev/null || echo 0)
    if [ "$ITERATION" -gt 1 ] && [ "$NEW_REMAINING" -eq "$PREV_REMAINING" ]; then
        STUCK_COUNT=$((STUCK_COUNT + 1))
        echo "  Warning: No progress detected ($STUCK_COUNT consecutive)"
        if [ "$STUCK_COUNT" -ge 3 ]; then
            echo "STUCK: No progress for 3 consecutive iterations. Stopping."
            echo "Review the plan and blocked tasks, then restart."
            break
        fi
    else
        STUCK_COUNT=0
    fi
    PREV_REMAINING=$NEW_REMAINING

    # Brief cooldown for API rate limits
    sleep 2
done

# Recompute final stats
REMAINING=$(grep -c '^[[:space:]]*[-*][[:space:]]\[ \]' "$PLAN_FILE" 2>/dev/null || echo 0)
BLOCKED=$(grep -c '^[[:space:]]*[-*][[:space:]]\[!\]' "$PLAN_FILE" 2>/dev/null || echo 0)
DONE=$(grep -c '^[[:space:]]*[-*][[:space:]]\[x\]' "$PLAN_FILE" 2>/dev/null || echo 0)

echo ""
echo "========================================"
echo "  Completed $ITERATION iterations"
echo "  Done:    $DONE"
echo "  Blocked: $BLOCKED"
echo "  Remaining: $REMAINING"
echo "========================================"

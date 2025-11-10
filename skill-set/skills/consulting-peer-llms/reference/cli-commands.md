# CLI Commands Reference

Detailed information about executing Gemini and Codex CLI tools for peer review.

## Command Format

Both CLIs accept prompts, but with different syntax:

```bash
# Gemini: positional argument (no subcommand needed)
gemini "your prompt text here"

# Codex: requires exec subcommand
codex exec "your prompt text here"
```

## Parallel Execution Pattern

### Basic Pattern

```bash
# Execute both in background
gemini "$PROMPT" > /tmp/gemini-review.txt 2>&1 &
GEMINI_PID=$!

codex exec "$PROMPT" > /tmp/codex-review.txt 2>&1 &
CODEX_PID=$!

# Wait for both to complete
wait $GEMINI_PID
GEMINI_EXIT=$?

wait $CODEX_PID
CODEX_EXIT=$?
```

### With Error Handling

```bash
#!/bin/bash

# Generate prompt
PROMPT=$(cat <<'EOF'
Your structured review prompt here...
EOF
)

# Create temp directory
TEMP_DIR=$(mktemp -d)
GEMINI_OUTPUT="$TEMP_DIR/gemini-review.txt"
CODEX_OUTPUT="$TEMP_DIR/codex-review.txt"

# Execute in parallel
gemini "$PROMPT" > "$GEMINI_OUTPUT" 2>&1 &
GEMINI_PID=$!

codex exec "$PROMPT" > "$CODEX_OUTPUT" 2>&1 &
CODEX_PID=$!

# Wait and capture exit codes
wait $GEMINI_PID
GEMINI_EXIT=$?

wait $CODEX_PID
CODEX_EXIT=$?

# Read results with error handling
if [ $GEMINI_EXIT -eq 0 ] && [ -s "$GEMINI_OUTPUT" ]; then
    GEMINI_RESULT=$(cat "$GEMINI_OUTPUT")
else
    GEMINI_RESULT="[Gemini CLI failed with exit code $GEMINI_EXIT or returned empty response]"
fi

if [ $CODEX_EXIT -eq 0 ] && [ -s "$CODEX_OUTPUT" ]; then
    CODEX_RESULT=$(cat "$CODEX_OUTPUT")
else
    CODEX_RESULT="[Codex CLI failed with exit code $CODEX_EXIT or returned empty response]"
fi

# Cleanup
rm -rf "$TEMP_DIR"

# Output results
echo "=== Gemini Review ==="
echo "$GEMINI_RESULT"
echo ""
echo "=== Codex Review ==="
echo "$CODEX_RESULT"
```

## Exit Code Handling

### Standard Exit Codes

| Exit Code | Meaning | Action |
|-----------|---------|--------|
| 0 | Success | Use output |
| 1 | General error | Report failure, continue with other CLI |
| 2 | Misuse (bad args) | Check prompt format |
| 126 | Not executable | Check CLI installation |
| 127 | Not found | Check PATH, install CLI |
| 130 | Interrupted (Ctrl+C) | User cancellation |

### Checking for Success

```bash
if [ $GEMINI_EXIT -eq 0 ] && [ -s /tmp/gemini-review.txt ]; then
    # Success: exit code 0 AND non-empty output
    GEMINI_RESULT=$(cat /tmp/gemini-review.txt)
else
    # Failure: log details for debugging
    GEMINI_RESULT="[Gemini CLI failed]"
    echo "DEBUG: Gemini exit code: $GEMINI_EXIT" >&2
    echo "DEBUG: Output size: $(wc -c < /tmp/gemini-review.txt)" >&2
fi
```

## Prompt Escaping

### Heredoc for Long Prompts

**Recommended** for multi-line prompts:

```bash
PROMPT=$(cat <<'EOF'
# Code Review Request

## What Was Implemented
User authentication with JWT tokens

## Requirements
- Secure login/logout
- Token refresh
- Permission validation

## Changes
...
EOF
)

gemini "$PROMPT"
```

The `'EOF'` (single quotes) prevents variable expansion in the heredoc.

### Escaping Special Characters

If passing prompt directly (not via heredoc):

```bash
# Escape double quotes
gemini "Review this \"important\" function"

# Escape dollar signs
gemini "Check variable \$USER usage"

# Escape backticks
gemini "Examine \`git status\` output"
```

**Better:** Use heredoc to avoid escaping issues.

## Timeout Handling

### Using timeout Command

Prevent CLIs from hanging indefinitely:

```bash
# Kill after 60 seconds
timeout 60s gemini "$PROMPT" > /tmp/gemini-review.txt 2>&1 &
GEMINI_PID=$!

timeout 60s codex exec "$PROMPT" > /tmp/codex-review.txt 2>&1 &
CODEX_PID=$!

wait $GEMINI_PID
GEMINI_EXIT=$?

wait $CODEX_PID
CODEX_EXIT=$?

# Exit code 124 means timeout
if [ $GEMINI_EXIT -eq 124 ]; then
    echo "Gemini CLI timed out after 60 seconds" >&2
fi
```

### Adjusting Timeout

Based on typical response times:
- **Quick reviews** (small changes): 30s timeout
- **Standard reviews** (moderate changes): 60s timeout
- **Complex reviews** (large refactors): 120s timeout

## Output Redirection

### Capturing stdout and stderr

```bash
# Both to same file
gemini "$PROMPT" > /tmp/output.txt 2>&1

# Separate files
gemini "$PROMPT" > /tmp/stdout.txt 2> /tmp/stderr.txt

# Discard stderr
gemini "$PROMPT" 2>/dev/null
```

### Why Capture stderr

CLIs may output:
- Progress messages
- Warning messages
- Error details

Capturing stderr helps with debugging when things fail.

## Verification Commands

### Check CLI Availability

```bash
# Check if installed
which gemini
which codex

# Check version
gemini --version
codex --version

# Test basic execution
gemini "test prompt" >/dev/null 2>&1 && echo "Gemini: OK" || echo "Gemini: FAIL"
codex "test prompt" >/dev/null 2>&1 && echo "Codex: OK" || echo "Codex: FAIL"
```

### Pre-flight Check Script

```bash
#!/bin/bash

check_cli() {
    local cli_name=$1

    if ! command -v $cli_name &> /dev/null; then
        echo "ERROR: $cli_name not found in PATH"
        return 1
    fi

    if ! $cli_name --version &> /dev/null; then
        echo "WARNING: $cli_name found but --version failed"
        return 2
    fi

    echo "OK: $cli_name is available"
    return 0
}

check_cli gemini
GEMINI_STATUS=$?

check_cli codex
CODEX_STATUS=$?

if [ $GEMINI_STATUS -ne 0 ] && [ $CODEX_STATUS -ne 0 ]; then
    echo "FATAL: Both CLIs unavailable"
    exit 1
elif [ $GEMINI_STATUS -ne 0 ] || [ $CODEX_STATUS -ne 0 ]; then
    echo "WARNING: One CLI unavailable, will continue with available one"
fi
```

## Performance Optimization

### Parallel vs Sequential

**Parallel execution** (recommended):
```bash
gemini "$PROMPT" > /tmp/gemini.txt 2>&1 &
codex exec "$PROMPT" > /tmp/codex.txt 2>&1 &
wait
```

Time: ~max(gemini_time, codex_time) = 10-20 seconds typical

**Sequential execution** (slower):
```bash
gemini "$PROMPT" > /tmp/gemini.txt
codex exec "$PROMPT" > /tmp/codex.txt
```

Time: gemini_time + codex_time = 20-40 seconds typical

**Savings: ~50% faster with parallel execution**

### Resource Limits

If system resources are constrained:

```bash
# Limit CPU usage (nice)
nice -n 10 gemini "$PROMPT" &
nice -n 10 codex exec "$PROMPT" &

# Limit memory (ulimit)
ulimit -v 2000000  # 2GB virtual memory limit
gemini "$PROMPT" &
codex exec "$PROMPT" &
```

## Temporary File Management

### Best Practices

```bash
# Use mktemp for unique temp files
TEMP_DIR=$(mktemp -d)
GEMINI_FILE="$TEMP_DIR/gemini-review.txt"
CODEX_FILE="$TEMP_DIR/codex-review.txt"

# Execute CLIs
gemini "$PROMPT" > "$GEMINI_FILE" 2>&1 &
codex exec "$PROMPT" > "$CODEX_FILE" 2>&1 &
wait

# Process results
# ...

# Always cleanup
rm -rf "$TEMP_DIR"
```

### Cleanup on Error

```bash
# Setup trap for cleanup
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Now temp files will be cleaned up even if script fails
```

## Troubleshooting

### "command not found"

```bash
# Check PATH
echo $PATH

# Find CLI location
find / -name gemini 2>/dev/null
find / -name codex 2>/dev/null

# Add to PATH if needed
export PATH=$PATH:/path/to/cli/directory
```

### "permission denied"

```bash
# Check permissions
ls -l $(which gemini)
ls -l $(which codex)

# Make executable
chmod +x /path/to/gemini
chmod +x /path/to/codex
```

### Empty Output

```bash
# Check if CLI produces output
gemini "simple test" 2>&1 | tee /tmp/debug.txt
echo "Exit code: $?"
echo "Output length: $(wc -c < /tmp/debug.txt)"

# Verify output file
ls -lh /tmp/gemini-review.txt
cat /tmp/gemini-review.txt
```

### Authentication Issues

Some CLIs may require authentication:

```bash
# Check for auth errors in stderr
gemini "$PROMPT" 2>&1 | grep -i "auth\|token\|login"

# Set auth environment variables if needed
export GEMINI_API_KEY="your-key"
export CODEX_API_KEY="your-key"
```

## Example: Complete Implementation

```bash
#!/bin/bash
set -euo pipefail

# Configuration
TIMEOUT=60s
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Generate prompt
PROMPT=$(cat <<'EOF'
# Code Review Request
## What Was Implemented
{context here}
EOF
)

# Execute with timeout and error handling
echo "Executing peer LLM reviews in parallel..."

timeout $TIMEOUT gemini "$PROMPT" > "$TEMP_DIR/gemini.txt" 2>&1 &
GEMINI_PID=$!

timeout $TIMEOUT codex exec "$PROMPT" > "$TEMP_DIR/codex.txt" 2>&1 &
CODEX_PID=$!

# Wait and capture results
wait $GEMINI_PID
GEMINI_EXIT=$?

wait $CODEX_PID
CODEX_EXIT=$?

# Process results
echo "=== Gemini Review ==="
if [ $GEMINI_EXIT -eq 0 ] && [ -s "$TEMP_DIR/gemini.txt" ]; then
    cat "$TEMP_DIR/gemini.txt"
elif [ $GEMINI_EXIT -eq 124 ]; then
    echo "[Gemini timed out after ${TIMEOUT}]"
else
    echo "[Gemini failed with exit code $GEMINI_EXIT]"
fi

echo ""
echo "=== Codex Review ==="
if [ $CODEX_EXIT -eq 0 ] && [ -s "$TEMP_DIR/codex.txt" ]; then
    cat "$TEMP_DIR/codex.txt"
elif [ $CODEX_EXIT -eq 124 ]; then
    echo "[Codex timed out after ${TIMEOUT}]"
else
    echo "[Codex failed with exit code $CODEX_EXIT]"
fi

# Report overall status
if [ $GEMINI_EXIT -ne 0 ] && [ $CODEX_EXIT -ne 0 ]; then
    echo ""
    echo "ERROR: Both CLIs failed"
    exit 1
fi

exit 0
```

## Integration with SKILL.md

When implementing the skill, use this pattern:

1. Generate prompt using template from `prompt-template.md`
2. Execute CLIs in parallel using pattern from this document
3. Capture raw outputs
4. Present raw outputs to user
5. Synthesize final report using both outputs

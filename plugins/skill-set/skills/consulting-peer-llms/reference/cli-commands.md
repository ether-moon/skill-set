# CLI Commands Reference

Detailed information about executing peer LLM CLI tools for review. Supports dynamic CLI selection via command arguments.

## Supported CLIs

**CRITICAL: Use non-interactive (one-shot) flags.** Without these flags, CLIs enter interactive/REPL mode.

| CLI | Non-Interactive Command | Flag | Notes |
|-----|------------------------|------|-------|
| gemini | `gemini -p "prompt"` | `-p` / `--prompt` | Without `-p`, enters interactive mode |
| codex | `codex exec "prompt"` | `exec` subcommand | Alias: `codex e "prompt"` |
| claude | `claude -p "prompt"` | `-p` / `--print` | Without `-p`, enters interactive REPL |

```bash
# Gemini: MUST use -p flag for non-interactive mode
gemini -p "your prompt text here"

# Codex: use exec subcommand
codex exec "your prompt text here"

# Claude: MUST use -p flag for non-interactive mode
claude -p "your prompt text here"
```

### Useful output options

```bash
# Gemini: plain text output
gemini -p "prompt" -o text

# Codex: save last message to file
codex exec -o /tmp/response.txt "prompt"

# Claude: text output format
claude -p --output-format text "prompt"
```

## Dynamic CLI Detection

### Determine Target CLIs

```bash
# Parse command arguments
REQUESTED_CLIS=("$@")

if [ ${#REQUESTED_CLIS[@]} -eq 0 ]; then
  # No arguments - default to standard set
  TARGET_CLIS=("gemini" "codex" "claude")
  echo "Using default CLIs: ${TARGET_CLIS[*]}"
else
  # Arguments provided - use specified CLIs
  TARGET_CLIS=("${REQUESTED_CLIS[@]}")
  echo "Using specified CLIs: ${TARGET_CLIS[*]}"
fi
```

## Parallel Execution Pattern

### Dynamic Parallel Execution

```bash
# Prepare result storage
declare -A CLI_RESULTS
declare -A CLI_PIDS
declare -A CLI_FILES

# Launch all target CLIs in parallel
for cli in "${TARGET_CLIS[@]}"; do
  OUTPUT_FILE="/tmp/${cli}-review.txt"
  CLI_FILES[$cli]="$OUTPUT_FILE"

  # Execute based on CLI type
  case "$cli" in
    gemini)
      gemini -p "$PROMPT" > "$OUTPUT_FILE" 2>&1 &
      ;;
    codex)
      codex exec "$PROMPT" > "$OUTPUT_FILE" 2>&1 &
      ;;
    claude)
      claude -p "$PROMPT" > "$OUTPUT_FILE" 2>&1 &
      ;;
    *)
      echo "Warning: Unknown CLI $cli, attempting generic execution"
      "$cli" "$PROMPT" > "$OUTPUT_FILE" 2>&1 &
      ;;
  esac

  CLI_PIDS[$cli]=$!
done

# Wait for all CLIs and collect results
for cli in "${TARGET_CLIS[@]}"; do
  wait ${CLI_PIDS[$cli]}
  EXIT_CODE=$?
  OUTPUT_FILE="${CLI_FILES[$cli]}"

  if [ $EXIT_CODE -eq 0 ] && [ -s "$OUTPUT_FILE" ]; then
    CLI_RESULTS[$cli]=$(cat "$OUTPUT_FILE")
  else
    CLI_RESULTS[$cli]="[${cli} CLI failed or returned empty response]"
  fi
done

# Cleanup
for cli in "${TARGET_CLIS[@]}"; do
  rm -f "${CLI_FILES[$cli]}"
done

# Display results
for cli in "${TARGET_CLIS[@]}"; do
  echo "=== ${cli^} Review ==="
  echo "${CLI_RESULTS[$cli]}"
  echo ""
done
```

### Legacy Static Pattern (for reference)

```bash
# Execute both in background
gemini -p "$PROMPT" > /tmp/gemini-review.txt 2>&1 &
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
gemini -p "$PROMPT" > "$GEMINI_OUTPUT" 2>&1 &
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

gemini -p "$PROMPT"
```

The `'EOF'` (single quotes) prevents variable expansion in the heredoc.

### Escaping Special Characters

If passing prompt directly (not via heredoc):

```bash
# Escape double quotes
gemini -p "Review this \"important\" function"

# Escape dollar signs
gemini -p "Check variable \$USER usage"

# Escape backticks
gemini -p "Examine \`git status\` output"
```

**Better:** Use heredoc to avoid escaping issues.

## Timeout Handling

### Using timeout Command

Prevent CLIs from hanging indefinitely:

```bash
# Use 1200s (20 minutes) timeout
timeout 1200s gemini -p "$PROMPT" > /tmp/gemini-review.txt 2>&1 &
GEMINI_PID=$!

timeout 1200s codex exec "$PROMPT" > /tmp/codex-review.txt 2>&1 &
CODEX_PID=$!

wait $GEMINI_PID
GEMINI_EXIT=$?

wait $CODEX_PID
CODEX_EXIT=$?

# Exit code 124 means timeout
if [ $GEMINI_EXIT -eq 124 ]; then
    echo "Gemini CLI timed out after 300 seconds" >&2
fi
```

### Recommended Timeout

**Use 1200s (20 minutes) for all reviews:**
```bash
# Fixed 1200s timeout
timeout 1200s gemini -p "$PROMPT" > /tmp/gemini-review.txt 2>/dev/null &
GEMINI_PID=$!

timeout 1200s codex exec "$PROMPT" > /tmp/codex-review.txt 2>/dev/null &
CODEX_PID=$!

wait $GEMINI_PID
GEMINI_EXIT=$?

wait $CODEX_PID
CODEX_EXIT=$?

# Exit code 124 means timeout
if [ $GEMINI_EXIT -eq 124 ]; then
    echo "Gemini CLI timed out after 600 seconds" >&2
fi
if [ $CODEX_EXIT -eq 124 ]; then
    echo "Codex CLI timed out after 600 seconds" >&2
fi
```

This timeout is sufficient for most reviews, including complex architectural changes.

### Troubleshooting Persistent Timeouts

If still timing out after 1200s (exit code 124):

**1. Test CLI responsiveness:**
```bash
# Test with simple prompt
time gemini -p "Hello, respond with OK"
time codex exec "Hello, respond with OK"

# If this takes >10 seconds, CLI has startup/auth issues
```

**2. Reduce prompt complexity:**
```bash
# Instead of full git diff
DIFF_SUMMARY=$(git diff --stat HEAD~1..HEAD | head -20)

# Instead of all conversation
RECENT_CONTEXT="Last 3 exchanges summary"

# Shorter prompt = faster response
```

**3. Check system resources:**
```bash
# CPU usage
top -l 1 | grep "CPU usage"

# Memory available
vm_stat | grep "Pages free"

# Network latency (if cloud-based CLIs)
ping -c 3 api.anthropic.com
```

**4. Split the review:**
```bash
# Instead of reviewing everything at once, split by concern
timeout 1200s gemini -p "Review security issues only: $CHANGES" > /tmp/gemini-security.txt &
timeout 1200s codex exec "Review performance issues only: $CHANGES" > /tmp/codex-performance.txt &
wait

# Then combine results
```

## Output Redirection

### Capturing stdout and stderr

```bash
# Both to same file (captures logs/errors - use for debugging)
gemini -p "$PROMPT" > /tmp/output.txt 2>&1

# Separate files (clean output in stdout)
gemini -p "$PROMPT" > /tmp/stdout.txt 2> /tmp/stderr.txt

# Discard stderr (recommended for production/clean output)
gemini -p "$PROMPT" > /tmp/output.txt 2>/dev/null
```

### Why Capture stderr

CLIs may output:
- Progress messages
- Warning messages
- Error details

Capturing stderr helps with debugging when things fail.



## Performance Optimization

### Parallel vs Sequential

**Parallel execution** (recommended):
```bash
gemini -p "$PROMPT" > /tmp/gemini.txt 2>&1 &
codex exec "$PROMPT" > /tmp/codex.txt 2>&1 &
wait
```

Time: ~max(gemini_time, codex_time) = 10-20 seconds typical

**Sequential execution** (slower):
```bash
gemini -p "$PROMPT" > /tmp/gemini.txt
codex exec "$PROMPT" > /tmp/codex.txt
```

Time: gemini_time + codex_time = 20-40 seconds typical

**Savings: ~50% faster with parallel execution**

### Resource Limits

If system resources are constrained:

```bash
# Limit CPU usage (nice)
nice -n 10 gemini -p "$PROMPT" &
nice -n 10 codex exec "$PROMPT" &

# Limit memory (ulimit)
ulimit -v 2000000  # 2GB virtual memory limit
gemini -p "$PROMPT" &
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
gemini -p "$PROMPT" > "$GEMINI_FILE" 2>&1 &
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



### Empty Output

```bash
# Check if CLI produces output
gemini -p "simple test" 2>&1 | tee /tmp/debug.txt
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
gemini -p "$PROMPT" 2>&1 | grep -i "auth\|token\|login"

# Set auth environment variables if needed
export GEMINI_API_KEY="your-key"
export CODEX_API_KEY="your-key"
```

## Example: Complete Dynamic Implementation

```bash
#!/bin/bash
set -euo pipefail

# Configuration
TIMEOUT=1200s
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Parse arguments to determine target CLIs
REQUESTED_CLIS=("$@")

if [ ${#REQUESTED_CLIS[@]} -eq 0 ]; then
  # No arguments - default to standard set
  TARGET_CLIS=("gemini" "codex" "claude")
  echo "Auto-detected CLIs: ${TARGET_CLIS[*]}"
else
  # Arguments provided - use specified
  TARGET_CLIS=("${REQUESTED_CLIS[@]}")
  echo "Using specified CLIs: ${TARGET_CLIS[*]}"
fi

# Generate prompt
PROMPT=$(cat <<'EOF'
# Code Review Request
## What Was Implemented
{context here}
EOF
)

# Execute all target CLIs in parallel
echo "Executing peer LLM reviews in parallel..."

declare -A CLI_PIDS
declare -A CLI_FILES

for cli in "${TARGET_CLIS[@]}"; do
  OUTPUT_FILE="$TEMP_DIR/${cli}.txt"
  CLI_FILES[$cli]="$OUTPUT_FILE"

  case "$cli" in
    gemini)
      timeout $TIMEOUT gemini -p "$PROMPT" > "$OUTPUT_FILE" 2>&1 &
      ;;
    codex)
      timeout $TIMEOUT codex exec "$PROMPT" > "$OUTPUT_FILE" 2>&1 &
      ;;
    claude)
      timeout $TIMEOUT claude -p "$PROMPT" > "$OUTPUT_FILE" 2>&1 &
      ;;
    *)
      timeout $TIMEOUT "$cli" "$PROMPT" > "$OUTPUT_FILE" 2>&1 &
      ;;
  esac

  CLI_PIDS[$cli]=$!
done

# Wait and display results
ALL_FAILED=true

for cli in "${TARGET_CLIS[@]}"; do
  wait ${CLI_PIDS[$cli]}
  EXIT_CODE=$?
  OUTPUT_FILE="${CLI_FILES[$cli]}"

  echo ""
  echo "=== ${cli^} Review ==="

  if [ $EXIT_CODE -eq 0 ] && [ -s "$OUTPUT_FILE" ]; then
    cat "$OUTPUT_FILE"
    ALL_FAILED=false
  elif [ $EXIT_CODE -eq 124 ]; then
    echo "[${cli} timed out after ${TIMEOUT}]"
  else
    echo "[${cli} failed with exit code $EXIT_CODE]"
  fi
done

# Report overall status
if [ "$ALL_FAILED" = true ]; then
    echo ""
    echo "ERROR: All CLIs failed"
    exit 1
fi

exit 0
```

**Usage examples:**
```bash
# Auto-detect all installed CLIs
./review.sh

# Use specific CLI
./review.sh gemini

# Use multiple CLIs
./review.sh gemini codex

# Use all three
./review.sh gemini codex claude
```

## Integration with SKILL.md

When implementing the skill, use this pattern:

1. Generate prompt using template from `prompt-template.md`
2. Execute CLIs in parallel using pattern from this document
3. Capture raw outputs
4. Present raw outputs to user
5. Synthesize final report using both outputs

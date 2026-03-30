# CLI Commands Reference

## Supported CLIs

Use non-interactive (one-shot) flags. Without these, CLIs enter interactive/REPL mode.

| CLI | Command | Notes |
|-----|---------|-------|
| gemini | `gemini -p "prompt"` | `-p` = prompt. Without it, enters interactive mode |
| codex | `codex exec -o output.txt "prompt"` | `exec` subcommand runs one-shot. `-o` captures final response to file. **`-p` is NOT prompt — it's `--profile`** |
| claude | `claude -p "prompt"` | `-p` = print mode (non-interactive). Sends prompt, prints response, exits |

**Common mistakes (why the script exists):**
- `codex -p "prompt"` → `-p` is `--profile`, not prompt
- `codex "prompt"` → enters interactive mode
- `claude "prompt"` → enters interactive REPL mode
- Any direct `codex`, `gemini`, or `claude` call → bypasses timeout, parallel execution, and correct flag handling

## Parallel Execution

```bash
# Bash 3.2+ compatible (macOS + Linux)
TIMEOUT="1200s"
TIMEOUT_CMD=""
command -v timeout &>/dev/null && TIMEOUT_CMD="timeout"
command -v gtimeout &>/dev/null && TIMEOUT_CMD="gtimeout"

run_cmd() {
  if [ -n "$TIMEOUT_CMD" ]; then "$TIMEOUT_CMD" "$TIMEOUT" "$@"; else "$@"; fi
}

TARGET_CLIS=("gemini" "codex" "claude")
PIDS=()
FILES=()

for cli in "${TARGET_CLIS[@]}"; do
  OUTPUT_FILE="/tmp/${cli}-review-$$.txt"
  FILES+=("$OUTPUT_FILE")
  case "$cli" in
    gemini)  run_cmd gemini -p "$PROMPT" > "$OUTPUT_FILE" 2>/dev/null & ;;
    codex)   run_cmd codex exec -o "$OUTPUT_FILE" "$PROMPT" >/dev/null 2>&1 & ;;
    claude)  run_cmd claude -p "$PROMPT" > "$OUTPUT_FILE" 2>/dev/null & ;;
  esac
  PIDS+=($!)
done

# Collect results
i=0
for cli in "${TARGET_CLIS[@]}"; do
  if wait "${PIDS[$i]}" && [ -s "${FILES[$i]}" ]; then
    cat "${FILES[$i]}"
  else
    echo "[$cli failed or timed out]"
  fi
  rm -f "${FILES[$i]}"
  i=$((i + 1))
done
```

**Timeout**: 1200s (20 minutes). Uses `timeout` (Linux) or `gtimeout` (macOS via coreutils). Without either, CLIs run without timeout.

**Compatibility**: Bash 3.2+ — no associative arrays (`declare -A`), no `${var^^}`. Uses indexed arrays and `tr` for uppercase.

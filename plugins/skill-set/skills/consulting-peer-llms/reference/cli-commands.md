# CLI Commands Reference

## Constraints

- **No model specification**: Do not pass `--model` or equivalent flags. Use each CLI's default model.
- **No prompt files**: Pass prompts directly inline to CLI commands. Do not write prompts to temp files.
- **No embedded context**: Do not read files, run git commands, or gather any data to embed in the prompt. CLIs run in the same repository — they read git state and files themselves.
- **Minimal prompts**: The prompt contains only: (1) instruction to review current branch vs origin/main, (2) 1-2 sentence intent summary, (3) user's review focus if explicitly requested. Nothing else.

## Supported CLIs

**CRITICAL: Use non-interactive (one-shot) flags.** Without these, CLIs enter interactive/REPL mode.

| CLI | Command | Notes |
|-----|---------|-------|
| gemini | `gemini -p "prompt"` | `-p` = prompt. Without it, enters interactive mode |
| codex | `codex exec "prompt"` | `exec` subcommand runs one-shot. **`-p` is NOT prompt — it's `--profile`** |

**Excluded CLIs:**
- `claude` — invoking `claude` CLI from within a Claude session fails

**Common mistakes:**
- `codex -p "prompt"` → **WRONG** — `-p` is `--profile`, not prompt. Use `codex exec "prompt"`
- `codex "prompt"` → **WRONG** — enters interactive mode. Use `codex exec "prompt"`

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

TARGET_CLIS=("gemini" "codex")
PIDS=()
FILES=()

for cli in "${TARGET_CLIS[@]}"; do
  OUTPUT_FILE="/tmp/${cli}-review-$$.txt"
  FILES+=("$OUTPUT_FILE")
  case "$cli" in
    gemini)  run_cmd gemini -p "$PROMPT" > "$OUTPUT_FILE" 2>/dev/null & ;;
    codex)   run_cmd codex exec "$PROMPT" > "$OUTPUT_FILE" 2>/dev/null & ;;
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

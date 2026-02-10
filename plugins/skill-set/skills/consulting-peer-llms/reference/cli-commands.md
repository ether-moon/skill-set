# CLI Commands Reference

## Constraints

- **No model specification**: Do not pass `--model` or equivalent flags. Use each CLI's default model.
- **No prompt files**: Pass prompts directly inline to CLI commands. Do not write prompts to temp files.
- **No diffs or SHAs in prompt**: CLIs run in the same repository. Instruct them to compare the current branch against `origin/main` (or `origin/master`).

## Supported CLIs

**CRITICAL: Use non-interactive (one-shot) flags.** Without these, CLIs enter interactive/REPL mode.

| CLI | Command | Notes |
|-----|---------|-------|
| gemini | `gemini -p "prompt"` | Without `-p`, enters interactive mode |
| codex | `codex exec "prompt"` | Alias: `codex e "prompt"` |
| claude | `claude -p "prompt"` | Without `-p`, enters interactive REPL |

## Parallel Execution

```bash
TIMEOUT="1200s"
declare -A CLI_PIDS CLI_FILES

for cli in "${TARGET_CLIS[@]}"; do
  OUTPUT_FILE="/tmp/${cli}-review.txt"
  CLI_FILES[$cli]="$OUTPUT_FILE"

  case "$cli" in
    gemini)  timeout $TIMEOUT gemini -p "$PROMPT" > "$OUTPUT_FILE" 2>/dev/null & ;;
    codex)   timeout $TIMEOUT codex exec "$PROMPT" > "$OUTPUT_FILE" 2>/dev/null & ;;
    claude)  timeout $TIMEOUT claude -p "$PROMPT" > "$OUTPUT_FILE" 2>/dev/null & ;;
  esac
  CLI_PIDS[$cli]=$!
done

# Collect results
for cli in "${TARGET_CLIS[@]}"; do
  wait ${CLI_PIDS[$cli]}
  EXIT_CODE=$?
  if [ $EXIT_CODE -eq 0 ] && [ -s "${CLI_FILES[$cli]}" ]; then
    cat "${CLI_FILES[$cli]}"
  elif [ $EXIT_CODE -eq 124 ]; then
    echo "[${cli} timed out]"
  else
    echo "[${cli} failed with exit code $EXIT_CODE]"
  fi
  rm -f "${CLI_FILES[$cli]}"
done
```

**Timeout**: 1200s (20 minutes). Exit code 124 = timeout.

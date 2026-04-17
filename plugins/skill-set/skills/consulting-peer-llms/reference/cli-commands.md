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

The bundled script (`scripts/peer-review.sh`) launches every selected CLI as a background process and collects results after `wait`. Invocations are driven by a small **CLI registry** rather than hard-coded `case` branches:

```bash
# "id|command-template" — template tokens are substituted per invocation
CLI_REGISTRY=(
    "gemini|gemini -p {PROMPT}"
    "codex|codex exec -o {OUT} {PROMPT}"
    "claude|claude -p {PROMPT}"
)
```

**Template rules**

- `{PROMPT}` → prompt as a single argument (no word splitting).
- `{OUT}` → output file path. When present, the CLI writes the response itself and the script discards stdout; when absent, stdout is redirected to the output file.
- The first token of the template is the binary name used for `command -v` detection.

**Stderr is always captured** to a sibling `${output_file}.err`. On empty responses or non-zero exits, the script surfaces the stderr block so prompt errors, auth failures, and network issues stay diagnosable instead of vanishing into `/dev/null`.

## Adding a new CLI

Append one entry to `CLI_REGISTRY` in `scripts/peer-review.sh`:

```bash
"amp|amp --run {PROMPT}"                     # stdout-mode CLI
"newcli|newcli --exec --out {OUT} {PROMPT}"  # direct-file CLI
```

Both `check` and `execute` iterate the registry, so no other changes are needed.

**Timeout**: 1200s (20 minutes). Uses `timeout` (Linux) or `gtimeout` (macOS via coreutils). Without either, CLIs run without timeout.

**Compatibility**: Bash 3.2+ — no associative arrays (`declare -A`), no `${var^^}`. Uses indexed arrays and `tr` for uppercase.

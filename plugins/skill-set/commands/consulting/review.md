---
description: Execute peer LLM reviews using the consulting-peer-llms skill
allowed-tools: "Bash(command:bash *peer-review.sh*)"
---

Use the consulting-peer-llms skill to execute peer LLM reviews.

**Arguments:**
- Optional: Review requirements to pass to peer LLMs (e.g., specific focus areas, concerns, constraints)
- If no arguments provided: Review all changes compared to `origin/main` or `origin/master`

## Execution

1. **Build prompt** following the consulting-peer-llms skill Step 1 (bare/context/focus tiers based on available context)
2. **Execute via bundled script** — this is the ONLY way to run the review:
   ```bash
   bash "$SKILL_DIR/scripts/peer-review.sh" execute "$PROMPT"
   ```
   Run in background. The script handles CLI detection, correct flags per CLI, parallel execution, and timeout.
3. **Present and synthesize** per the consulting-peer-llms skill Steps 3-5

**NEVER call `gemini`, `codex`, or `claude` directly.** Each CLI uses different flag semantics (`codex -p` means `--profile`, not prompt). The script encapsulates the correct invocation for each CLI. If the user is prompted for Bash approval, you are bypassing the script.

## Constraints

- **Do NOT call CLI tools directly** — always use the bundled script
- **Do NOT pass diffs, SHAs, or file contents in the prompt** — CLIs run in the same repo and discover context themselves
- **Do NOT write prompts to separate files** — pass inline to the script
- **Do NOT specify model parameters** — the script uses each CLI's defaults

---
description: Execute peer LLM reviews using the consulting-peer-llms skill
allowed-tools: "Bash(gemini:*) Bash(codex:*) Bash(claude:*) Bash(timeout:*) Bash(command:*) Bash(bash:*) Bash($SKILL_DIR:*)"
---

Use the consulting-peer-llms skill to execute peer LLM reviews.

**Arguments:**
- Optional: Review requirements to pass to peer LLMs (e.g., specific focus areas, concerns, constraints)
- If no arguments provided: Review all changes compared to `origin/main` or `origin/master`

**Examples:**
- `/consulting-peer-llms:review` - Review all changes vs origin/main (or master)
- `/consulting-peer-llms:review Check for security vulnerabilities in the authentication flow`
- `/consulting-peer-llms:review Evaluate the database query performance and suggest optimizations`

## Execution

1. **Detect installed CLIs**: Run `command -v` to check for `gemini`, `codex`, `claude` and use all that are available
2. **Determine review scope**:
   - If arguments provided: Use as review requirements
   - If no arguments: Request a general code review of the current implementation
3. **Build prompt and execute CLIs in parallel** from the consulting-peer-llms skill with the detected CLIs and determined scope

## Constraints

- **Do NOT pass diffs, SHAs, or file contents in the prompt**: Each CLI runs in the same repository and can use git directly. Simply instruct them to compare the current branch against `origin/main` (or `origin/master`).
- **Do NOT write prompts to separate files**: Pass prompts directly inline to CLI commands. Writing prompt content to temp `.md` files is unnecessary overhead.
- **Do NOT specify model parameters**: Use each CLI's default model. Do not pass flags like `--model` to any CLI.

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
   - If no arguments: Collect changes via `git diff origin/main...HEAD` (fallback to `origin/master`) and request a general code review of the current implementation
3. **Execute the review workflow** from the consulting-peer-llms skill with the detected CLIs and determined scope

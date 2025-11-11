---
description: Execute peer LLM reviews with specified CLI tools using the consulting-peer-llms skill
model: claude-sonnet-4-5
---

Use the consulting-peer-llms skill to execute peer LLM reviews.

**Arguments:**
- Optional: Specify one or more CLI tools to use (e.g., `gemini`, `codex`, `claude`)
- If no arguments provided: Auto-detect and use all installed CLI tools

**Examples:**
- `/consulting-peer-llms:review gemini` - Review with Gemini only
- `/consulting-peer-llms:review gemini codex` - Review with Gemini and Codex
- `/consulting-peer-llms:review` - Review with all installed CLIs

Execute the review workflow from the skill with the specified CLI arguments.

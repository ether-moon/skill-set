---
name: consulting-peer-llms
description: Execute peer reviews from other LLM CLI tools (Gemini, Codex, Claude) in parallel and synthesize actionable insights. Use when user requests feedback from other LLMs, peer review, or external validation — e.g., "get feedback from gemini", "ask codex to review", "ask claude to review", "peer review this", "what do other LLMs think", "get a second opinion", "validate with codex".
allowed-tools: "Bash(command:bash *peer-review.sh*)"
---

# Consulting Peer LLMs

## Overview

Get feedback from other LLM CLI tools (Gemini, Codex, Claude) on your current work. This skill executes multiple LLM reviews in parallel and synthesizes their responses into one actionable report.

**Core principle**: Use peer LLMs for external validation and diverse perspectives on implementation quality.

## When to Use

Use this skill when the user requests external LLM review:
- "Validate this with codex"
- "Get feedback from gemini"
- "I want a review from other LLMs"
- "Do a peer review" / "Get a second opinion"

This skill runs CLI tools in parallel, which takes 5-30 minutes. Only trigger on explicit user request, not as a routine step.

## Prerequisites

**Supported CLI tools:**
- `gemini` - Google Gemini CLI
- `codex` - OpenAI Codex CLI
- `claude` - Anthropic Claude Code CLI

**Detection:**
- Auto-detect all installed CLIs via `command -v`
- Use all available CLIs for comprehensive review

## Workflow

### Step 1: Build Minimal Prompt

**Prompt minimalism principle**: CLIs run in the same repository. They can `git diff`, `git log`, and read any file. Never duplicate what they can discover themselves.

**Bare prompt** (no context available — e.g., slash command without arguments):
```
Review all changes on the current branch vs origin/main.
Use git diff origin/main...HEAD and read files directly.
```

**With conversation context** (agent knows what was implemented):
```
Review all changes on the current branch vs origin/main.
Use git diff origin/main...HEAD and read files directly.
{1-2 sentence summary of what was implemented and why}
```

**With explicit review focus** (user specifies files or areas):
```
Review all changes on the current branch vs origin/main.
Use git diff origin/main...HEAD and read files directly.
{1-2 sentence summary, if available}
Focus on: {user's specific requirements — paths or areas only if user explicitly asked}
```

**What goes in the prompt:**
- Instruction to use git for changes (always)
- 1-2 sentence summary of intent (only if known from conversation — never gather it)
- User's review focus (if any, passed as-is)

**Keep out of the prompt** (CLIs run in the same repo and discover all of this themselves):
- File contents, code snippets, git diffs, stats, or change summaries
- File lists, directory structures, SHAs, or commit messages
- Path references (unless user explicitly asked to focus on specific files)
- Summaries derived by reading git log or files

Avoid running git commands to gather context for the prompt. If there is no conversation context, use Tier 1 (bare prompt) as-is rather than fabricating context. Shorter prompts produce more focused reviews.

**Full template**: See [reference/prompt-template.md](reference/prompt-template.md)

### Step 2: Execute in Parallel

Always use the bundled script rather than calling `gemini`, `codex`, or `claude` directly:

```bash
bash "$SKILL_DIR/scripts/peer-review.sh" execute "$PROMPT"
```

Run in background and collect output when complete. The script handles CLI detection, correct flags, parallel execution, and timeout.

CLI flag semantics are unintuitive and differ between tools — for example, `codex -p` means `--profile` (not prompt), and `codex` without `exec` enters interactive mode. These have caused repeated failures when invoked directly. The script encapsulates the correct invocations. Direct CLI tool permissions are intentionally excluded from `allowed-tools` to prevent bypassing it.

**Details**: See [reference/cli-commands.md](reference/cli-commands.md)

### Step 3: Present Raw Responses

Show original responses first for transparency:

```markdown
# Gemini Review
{response}
---
# Codex Review
{response}
---
# Claude Review
{response}
---
```

### Step 4: Synthesize Final Report

**Always synthesize** - even for single CLI responses.

**Synthesis principles:**
1. Consolidate duplicates — same issue from multiple CLIs = one entry
2. Filter for validity — skip suggestions irrelevant to current requirements
3. Prioritize by impact — not by which/how many CLIs mentioned it
4. Make actionable — concrete code fixes, not vague advice
5. Remove noise — focus on essentials

**Report example**: See [reference/report-format.md](reference/report-format.md)

### Step 5: Classify and Resolve

Apply the `autofixing-and-escalating` skill to the synthesized report items. The synthesized items are the external source input — classify each as OBVIOUS or AMBIGUOUS, auto-fix obvious ones, and escalate ambiguous ones for user decision.

**Integration point**: The synthesized report from Step 4 replaces the raw peer responses as the authoritative item list. Do not re-classify raw CLI output — only the deduplicated, validated synthesis.

## Quick Reference

**Commands:**
- `/skill-set:consulting:review <requirements>` - Auto-detect all installed CLIs and review with the given requirements

**Bundled script:** `scripts/peer-review.sh` — Handles CLI detection, parallel execution with timeout, and result collection. Bash 3.2+ compatible (macOS/Linux).
- `scripts/peer-review.sh check` — Show installed CLIs and timeout availability
- `scripts/peer-review.sh execute "prompt" [cli1 cli2]` — Run review with specified or all available CLIs

**Typical execution time:** 5-30 minutes (parallel)

**Temp files:** `/tmp/{cli-name}-review-$$.txt` (one per CLI, auto-cleaned)

## Red Flags - STOP Immediately

- Calling `gemini`, `codex`, or `claude` directly instead of using the bundled script
- Running git commands or reading files to embed context in the prompt (CLIs discover this themselves)
- Running peer review without explicit user request
- Showing raw responses without synthesis, or skipping raw responses before synthesis
- Writing prompts to separate temp files instead of passing inline
- Adding flags not in the script (`--full-auto`, `-q`, `--model`, etc.)

## Error Handling

**Some CLIs fail:** Continue with successful ones, note failures in report

**Timeout (exit 124):** Reduce prompt size, check CLI responsiveness

**No retries:** Keep execution fast and simple

## Troubleshooting

**"codex failed", "unexpected argument", or "profile not found"**
- You called `codex` directly instead of using the script. Use `bash "$SKILL_DIR/scripts/peer-review.sh" execute "$PROMPT"`
- Direct `codex`, `gemini`, and `claude` calls are intentionally excluded from `allowed-tools` — if the user is prompted for Bash approval, you are calling the CLI directly instead of using the script
- Invalid flags: `codex -q`, `codex -a full-auto`, `codex -p` — these are not valid one-shot invocations
- Valid but still wrong here: `codex exec`, `codex review` — these work, but calling them directly bypasses timeout and parallel execution. Use the script.

**"Empty response from CLI"**
- Check CLI can run: `gemini -p "test"`, `codex exec "test"`, or `claude -p "test"`
- Verify API keys/auth
- Check prompt isn't too long

**"All CLIs failed"**
- Run diagnostics: `gemini --version && codex --version && claude --version`
- Check network connectivity

**"Response is truncated"**
- CLIs may have output limits
- Reduce prompt length

## See Also

- [reference/prompt-template.md](reference/prompt-template.md) - Prompt structure
- [reference/cli-commands.md](reference/cli-commands.md) - CLI commands and parallel execution
- [reference/report-format.md](reference/report-format.md) - Report example

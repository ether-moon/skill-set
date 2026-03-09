---
name: consulting-peer-llms
description: Use when user explicitly requests feedback from other LLM tools (Gemini, Codex) on current work
allowed-tools: "Bash(gemini:*) Bash(codex:*) Bash(timeout:*) Bash(command:*) Bash(bash:*) Bash($SKILL_DIR:*)"
---

# Consulting Peer LLMs

## Overview

Get feedback from other LLM CLI tools (Gemini, Codex) on your current work. This skill executes multiple LLM reviews in parallel and synthesizes their responses into one actionable report.

**Core principle**: Use peer LLMs for external validation and diverse perspectives on implementation quality.

## When to Use

**Use this skill when the user explicitly requests:**
- "Validate this with codex"
- "Get feedback from gemini"
- "I want a review from other LLMs"
- "Do a peer review"

**Do NOT use:**
- Automatically without user request
- For every piece of code (it's heavyweight)
- When quick internal review is sufficient

## Prerequisites

**Supported CLI tools:**
- `gemini` - Google Gemini CLI
- `codex` - OpenAI Codex CLI

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

**What NEVER goes in the prompt:**
- File contents or code snippets
- Git diffs, stats, or change summaries
- File lists or directory structures
- SHAs or commit messages
- Path references (unless user explicitly asked to focus on specific files)
- Summaries derived by reading git log or files (if no conversation context, omit the summary)

**Full template**: See [reference/prompt-template.md](reference/prompt-template.md)

### Step 2: Execute in Parallel

Run target CLIs simultaneously and collect results.

**CLI commands**: See [reference/cli-commands.md](reference/cli-commands.md)

### Step 3: Present Raw Responses

Show original responses first for transparency:

```markdown
# Gemini Review
{response}
---
# Codex Review
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

## Quick Reference

**Commands:**
- `/consulting-peer-llms:review <requirements>` - Auto-detect all installed CLIs and review with the given requirements

**Typical execution time:** 5-30 minutes (parallel)

**Temp files:** `/tmp/{cli-name}-review.txt` (one per CLI)

## Red Flags - STOP Immediately

- Running peer review without explicit user request
- Skipping raw response output
- Just showing raw responses without synthesis
- Skipping synthesis for single CLI
- Passing file contents, diffs, file lists, SHAs, or change summaries in the prompt
- Passing file paths or references unless user explicitly requested focus on specific files
- Building the prompt by reading files or running git commands to embed results
- Writing prompts to separate temp files instead of passing inline
- Specifying model parameters (e.g., `--model`) — use each CLI's default model

## Error Handling

**Some CLIs fail:** Continue with successful ones, note failures in report

**Timeout (exit 124):** Reduce prompt size, check CLI responsiveness

**No retries:** Keep execution fast and simple

## Troubleshooting

**"codex failed" or "profile not found"**
- `codex -p` is `--profile`, NOT prompt. Always use `codex exec "prompt"`

**"Empty response from CLI"**
- Check CLI can run: `gemini -p "test"` or `codex exec "test"`
- Verify API keys/auth
- Check prompt isn't too long

**"All CLIs failed"**
- Run diagnostics: `gemini --version && codex --version`
- Check network connectivity

**"Response is truncated"**
- CLIs may have output limits
- Reduce prompt length

## See Also

- [reference/prompt-template.md](reference/prompt-template.md) - Prompt structure
- [reference/cli-commands.md](reference/cli-commands.md) - CLI commands and parallel execution
- [reference/report-format.md](reference/report-format.md) - Report example

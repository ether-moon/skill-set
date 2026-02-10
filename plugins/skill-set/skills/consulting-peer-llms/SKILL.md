---
name: consulting-peer-llms
description: Use when user explicitly requests feedback from other LLM tools (Gemini, Codex, Claude) on current work
allowed-tools: "Bash(gemini:*) Bash(codex:*) Bash(claude:*) Bash(timeout:*) Bash(command:*) Bash(bash:*) Bash($SKILL_DIR:*)"
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
- `claude` - Anthropic Claude CLI

**Detection:**
- Auto-detect all installed CLIs via `command -v`
- Use all available CLIs for comprehensive review

## Workflow

### Step 1: Collect Context

**Work Summary:**
- What was implemented (from conversation)
- User's requirements and constraints

### Step 2: Generate Review Prompt

Use structured prompt with these sections:
1. What was implemented
2. Requirements/plan
3. Instruction to compare current branch against `origin/main` (or `origin/master`)
4. User's specific review requirements (if any, passed as-is)

**Full template**: See [reference/prompt-template.md](reference/prompt-template.md)

### Step 3: Execute in Parallel

Run target CLIs simultaneously and collect results.

**CLI commands**: See [reference/cli-commands.md](reference/cli-commands.md)

### Step 4: Present Raw Responses

Show original responses first for transparency:

```markdown
# Gemini Review
{response}
---
# Codex Review
{response}
---
```

### Step 5: Synthesize Final Report

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
- Passing diffs, file lists, SHAs, or file contents in the prompt (CLIs can use git directly)
- Writing prompts to separate temp files instead of passing inline
- Specifying model parameters (e.g., `--model`) — use each CLI's default model

## Error Handling

**Some CLIs fail:** Continue with successful ones, note failures in report

**Timeout (exit 124):** Reduce prompt size, check CLI responsiveness

**No retries:** Keep execution fast and simple

## Troubleshooting

**"Empty response from CLI"**
- Check CLI can run: `gemini -p "test"`
- Verify API keys/auth
- Check prompt isn't too long

**"Both CLIs failed"**
- Run diagnostics: `gemini --version && codex --version`
- Check network connectivity

**"Response is truncated"**
- CLIs may have output limits
- Reduce prompt length

## See Also

- [reference/prompt-template.md](reference/prompt-template.md) - Prompt structure
- [reference/cli-commands.md](reference/cli-commands.md) - CLI commands and parallel execution
- [reference/report-format.md](reference/report-format.md) - Report example

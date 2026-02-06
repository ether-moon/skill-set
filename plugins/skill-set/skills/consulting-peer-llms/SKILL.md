---
name: consulting-peer-llms
description: Use when user explicitly requests feedback from other LLM tools (Gemini, Codex) on current work - executes peer reviews in parallel and synthesizes responses into actionable insights
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

**Code Changes:**
```bash
BASE_SHA=$(git rev-parse origin/main 2>/dev/null || echo "HEAD~1")
CURRENT_SHA=$(git rev-parse HEAD)
```

### Step 2: Generate Review Prompt

Use structured prompt with these sections:
1. Output language (if non-English detected)
2. What was implemented
3. Requirements/plan
4. Changes (SHAs + file list + summary)
5. Review focus areas
6. Expected output format

**Full template**: See [reference/prompt-template.md](reference/prompt-template.md)

### Step 3: Execute in Parallel

Run target CLIs simultaneously and collect results.

**Detailed execution**: See [reference/execution.md](reference/execution.md)

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

**Report structure**: See [reference/report-format.md](reference/report-format.md)

**Key sections:**
- Critical Issues Requiring Immediate Attention
- Architecture & Design Concerns
- Code Quality Issues
- Actionable Recommendations

## Quick Reference

**Commands:**
- `/consulting-peer-llms:review <requirements>` - Auto-detect all installed CLIs and review with the given requirements

**Typical execution time:** 10-30 seconds (parallel)

**Temp files:** `/tmp/{cli-name}-review.txt` (one per CLI)

## Red Flags - STOP Immediately

- Running peer review without explicit user request
- Skipping raw response output
- Just showing raw responses without synthesis
- Skipping synthesis for single CLI
- Including full git diff in prompt (use summary)

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

- [reference/prompt-template.md](reference/prompt-template.md) - Full prompt structure
- [reference/cli-commands.md](reference/cli-commands.md) - CLI execution details
- [reference/execution.md](reference/execution.md) - Parallel execution details
- [reference/report-format.md](reference/report-format.md) - Report examples

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

Run in background. The script handles CLI detection, correct flags per CLI, parallel execution, and timeout.

CLI flag semantics are unintuitive and differ between tools — for example, `codex -p` means `--profile` (not prompt), and `codex` without `exec` enters interactive mode. These have caused repeated failures when invoked directly. The script encapsulates the correct invocations. Direct CLI tool permissions are intentionally excluded from `allowed-tools` to prevent bypassing it.

**Output contract**: The script writes each CLI's full response to its own file under `$PEER_REVIEW_DIR` (default `/tmp/peer-review-$$/`) and prints only a bounded status block to stdout. Stdout looks like:

```
PEER_REVIEW_DIR=/tmp/peer-review-12345
Responses (read each file individually — do NOT pipe through head/tail/grep):
  gemini  OK      /tmp/peer-review-12345/gemini.txt  (5421 lines)
  codex   OK      /tmp/peer-review-12345/codex.txt   (3892 lines)
  claude  EMPTY   /tmp/peer-review-12345/claude.txt  (0 lines, stderr: ...)
```

**Never** capture peer responses by piping the script through `head`, `tail`, `grep`, or any line-cap. Bodies are not in stdout — they are in the per-CLI files. Truncating stdout cannot save tokens here; it only loses status lines.

**Details**: See [reference/cli-commands.md](reference/cli-commands.md)

### Step 3: Read and Present Raw Responses

After the script finishes, read each per-CLI file directly with the Read tool — one Read call per file. Then present them to the user in sequence for transparency:

```markdown
# Gemini Review
{contents of $PEER_REVIEW_DIR/gemini.txt}
---
# Codex Review
{contents of $PEER_REVIEW_DIR/codex.txt}
---
# Claude Review
{contents of $PEER_REVIEW_DIR/claude.txt}
---
```

If a CLI's status was `EMPTY` or `FAILED`, also surface its stderr file (`<cli>.txt.err`) so the user can diagnose auth or network issues.

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

### Step 6: Clean Up

Once synthesis is presented and resolutions are dispatched, remove the response directory:

```bash
rm -rf "$PEER_REVIEW_DIR"
```

Files are not auto-deleted by the script. Default `/tmp/peer-review-$$/` paths are reaped by the OS eventually, but explicit `PEER_REVIEW_DIR` overrides (e.g., `.context/peer-review-...`) accumulate in the workspace until cleaned.

## Quick Reference

**Commands:**
- `/skill-set:consulting:review <requirements>` - Auto-detect all installed CLIs and review with the given requirements

**Bundled script:** `scripts/peer-review.sh` — Handles CLI detection, parallel execution with timeout, and result collection. Bash 3.2+ compatible (macOS/Linux).
- `scripts/peer-review.sh check` — Show installed CLIs and timeout availability
- `scripts/peer-review.sh execute "prompt" [cli1 cli2]` — Run review with specified or all available CLIs

**Typical execution time:** 5-30 minutes (parallel)

**Output files:** `$PEER_REVIEW_DIR/<cli>.txt` (response) and `<cli>.txt.err` (stderr). Default `$PEER_REVIEW_DIR` is `/tmp/peer-review-$$/`. Files persist after the script exits — Read them with the Read tool, then optionally clean up.

## Red Flags - STOP Immediately

- Calling `gemini`, `codex`, or `claude` directly instead of using the bundled script
- Piping the script through `head`, `tail`, `grep`, `awk`, or any line-cap — response bodies are in files, not stdout. Truncation here only loses status lines and signals you're treating the output incorrectly.
- Trying to recover responses from stdout instead of reading the per-CLI files
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
- Check CLI can run: `gemini -p "test"`, `codex exec -o /tmp/test.txt "test"`, or `claude -p "test"`
- Verify API keys/auth
- Check prompt isn't too long

**"All CLIs failed"**
- Run diagnostics: `gemini --version && codex --version && claude --version`
- Check network connectivity

**"Response is truncated"**
- First check: are you reading from `$PEER_REVIEW_DIR/<cli>.txt`? If you are reading the bash stdout instead, you are looking at the status block, not the response — switch to the Read tool on the file path.
- If the file itself is short, the CLI may have hit its own output limit. Reduce prompt length and retry.

## See Also

- [reference/prompt-template.md](reference/prompt-template.md) - Prompt structure
- [reference/cli-commands.md](reference/cli-commands.md) - CLI commands and parallel execution
- [reference/report-format.md](reference/report-format.md) - Report example

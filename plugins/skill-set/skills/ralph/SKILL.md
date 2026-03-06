---
name: ralph
description: >
  Use when user mentions "ralph", "ralph loop", or "ralph wiggum" in the context of
  planning or executing implementation work with fresh context per iteration.
---

# Ralph

## Overview

Plans and executes implementation work via Geoffrey Huntley's Ralph Wiggum technique: a **loop where each iteration spawns a fresh Task subagent**. Two modes share one loop mechanism — PLANNING generates a plan, BUILDING implements from it.

**Core philosophy:** Disk is memory. Each iteration gets fresh context. Plan file on disk is the single source of truth. No context rot.

**Prompt templates:** Located in `templates/` relative to this SKILL.md file.

## When to Use

- User mentions "ralph", "ralph loop", "ralph wiggum"
- User wants to plan or execute implementation work with fresh context per iteration

**When NOT to use:**
- User asks to "implement the plan" without mentioning "ralph" → use other execution skills

## Modes

| Mode | Command | Prompt | Purpose |
|------|---------|--------|---------|
| PLANNING | `/skill-set:ralph:plan` | `PROMPT_plan.md` | Generate/refine a Ralph-ready plan |
| BUILDING | `/skill-set:ralph:execute` | `PROMPT_build.md` | Implement from plan, one task per iteration |

Both modes share loop infrastructure: iteration control, circuit breaker, fresh context per subagent, progress tracking.

## Workflow

### Step 1: Determine Mode

| Condition | Mode |
|-----------|------|
| User invokes `/skill-set:ralph:plan` | PLANNING |
| User invokes `/skill-set:ralph:execute` + valid plan exists | BUILDING |
| User invokes `/skill-set:ralph:execute` + no valid plan | PLANNING first, then BUILDING |

### Step 2: Detect Project Environment

Auto-detect, show results, and ask user to confirm or correct:
- Language/framework (package.json → Node, Gemfile → Rails, etc.)
- Test command (`npm test`, `bundle exec rspec`, `pytest`, etc.)
- Default branch (`git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'`, fallback to `main`)

### Step 3: Verify AGENTS.md

Check for AGENTS.md or CLAUDE.md at project root.
- **Exists:** Verify it contains build/test commands. Suggest additions if missing.
- **Missing:** Offer to create minimal AGENTS.md from Step 2 detection results.
- **User declines creation:** Remove all `{{AGENTS_FILE}}` references from the constructed prompt.

### Step 4: Prepare Plan File

Create session directory and plan file path:

```
tmp/ralph/{YYYY-MM-DD-HHmm}/plan.md
```

- **PLANNING mode:** This is the output destination.
- **BUILDING mode:** Search for existing plan in priority order:
  1. Path explicitly provided by user
  2. Most recent `tmp/ralph/*/plan.md`
  3. Root `*plan*` or `*PLAN*` files
  4. If not found → enter PLANNING mode first

Ensure `tmp/` is in the target project's `.gitignore`.

### Step 5: Construct Prompt

Read the appropriate template from `templates/`. Substitute:
- `{{AGENTS_FILE}}` → `AGENTS.md` or `CLAUDE.md` (whichever exists; remove referencing lines if neither exists)
- `{{PLAN_FILE}}` → plan file path
- `{{TEST_CMD}}` → detected test command from Step 2
- `{{SOURCE_DOC}}` → input document path (PLANNING only; remove the `0b.` orient line if no source document provided)

Hold the constructed prompt in memory. Do NOT write files into the project.

### Step 6: Propose Done Condition

**Before starting the loop**, propose a concrete DONE condition to the user and get confirmation.

The DONE condition defines when the loop should terminate. It must be **observable and unambiguous** — something the loop controller or the subagent can evaluate without subjective judgment.

Examples of good DONE conditions:
- "All tasks in the plan are marked as completed"
- "The test suite passes and all planned endpoints are implemented"
- "3 features (auth, dashboard, API) are implemented and tested"
- "The plan file contains no remaining actionable items"

**Workflow:**
1. Analyze the plan (or stated goals for PLANNING mode)
2. Propose a DONE condition to the user
3. User confirms or adjusts
4. Include the confirmed DONE condition in the loop's completion check

The DONE condition is passed to each subagent as part of the prompt context, so every fresh-context iteration knows the target.

### Step 7: Execute Loop

Report loop start to user, then run:

```
iteration = 0
stuck_count = 0
max_iterations = 100

while iteration < max_iterations:
  1. iteration += 1
     Report: "Iteration {iteration}"

  2. Save: prev_head = `git rev-parse HEAD`
     Save: prev_plan_hash = hash of plan file

  3. Spawn Task subagent:
     - subagent_type: "general-purpose"
     - prompt: the constructed prompt from Step 5 + DONE condition from Step 6
     - description: "Ralph iteration {iteration}"

  4. Wait for subagent completion

  5. Check progress:
     curr_head = `git rev-parse HEAD`
     curr_plan_hash = hash of plan file

     progress = (curr_head != prev_head) OR (curr_plan_hash != prev_plan_hash)

     If NOT progress:
       stuck_count += 1
       Report: "Warning: No progress ({stuck_count} consecutive)"
       If stuck_count >= 3:
         Ask user: "No progress for {stuck_count} iterations. Continue or stop?"
         If continue → stuck_count = 0
         If stop → break
     Else:
       stuck_count = 0

  6. Completion check:
     Evaluate the DONE condition from Step 6.
     If met → break
```

**Subagent configuration:**
- Model: `sonnet` (default). Sufficient for well-defined tasks. User can request different model.
- No isolation (worktree) — subagent works in same repo.
- Subagent has access to all tools (general-purpose agent).

**PLANNING → BUILDING transition:**
When PLANNING completes within `/skill-set:ralph:execute`, report the generated plan to user, ask for confirmation, then propose DONE condition and transition to BUILDING mode.

### Step 8: Report Results

Display final summary (adapt to user's language):

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Ralph Loop Complete
  Mode:       {PLANNING | BUILDING}
  Iterations: {iteration}
  Plan:       {plan_file_path}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

If incomplete, suggest next steps:
- Review the plan and re-run
- Refine input and re-plan

## Progress Tracking

**New commits OR plan file modifications count as progress.** Both modes use the same metric.

- New git commit = progress
- Plan file changed (hash differs) = progress
- Neither changed = no progress
- Stuck: 3 consecutive iterations with no progress → ask user

This means blocker handling (updating plan with blocker notes without committing code) still counts as progress, preventing false stuck detection.

## Plan File Structure

The plan is a **single self-contained file** with free-form content. No separate spec files.

Recommended structure (LLM generates naturally, not enforced):

```markdown
## Context

[Goals, constraints, technical background — concise but sufficient
 for a fresh-context agent to understand the project]

## Tasks

- Task description with implementation detail
  Related files, verification approach
- Next task, prioritized by importance
  ...
```

**Key properties:**
- Free-form. No checkbox format enforced. LLM manages naturally.
- Context section replaces separate specs — one file, full picture.
- Living document — BUILDING iterations update with discoveries and completed work.
- Disposable — re-run PLANNING to regenerate from scratch.

See `reference/plan-quality.md` for Ralph-ready plan criteria.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Forcing checkbox format on plans | Let LLM manage task format naturally. Free-form bullet points. |
| Skipping DONE condition proposal | Always propose and confirm DONE condition before starting the loop. |
| Using opus for loop iterations | Sonnet is sufficient for well-defined tasks. Save opus for planning. |
| Writing files into the project | Prompt is in memory. Plan goes to tmp/ralph/. |
| Running multiple iterations in parallel | Sequential — each iteration depends on the previous. One subagent at a time. |
| Skipping user confirmation on plan | Always preview and confirm before transitioning PLANNING → BUILDING. |

## Reference

The `templates/` directory contains prompt templates:
- `PROMPT_plan.md` — Planning mode prompt (generate/refine plan)
- `PROMPT_build.md` — Building mode prompt (implement from plan)
- `loop.sh` — Bash loop script for external execution (reference only)

The `reference/` directory contains:
- `plan-quality.md` — Criteria for Ralph-ready plans (used as verification during PLANNING)

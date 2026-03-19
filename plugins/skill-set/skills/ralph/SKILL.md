---
name: ralph
description: >
  Plans and executes implementation work via an iterative loop with fresh-context Task subagents.
  Two modes: PLANNING generates a declarative spec with acceptance criteria, BUILDING performs
  gap analysis and implements toward it — one gap per iteration, no context rot.
  Use when user mentions "ralph", "ralph loop", "ralph wiggum", wants iterative implementation
  with fresh context per iteration, asks for spec-driven development, wants a subagent loop,
  or needs to break large implementation work into autonomous iterations.
---

# Ralph

## Overview

Plans and executes implementation work via Geoffrey Huntley's Ralph Wiggum technique: a **loop where each iteration spawns a fresh Task subagent**. Two modes share one loop mechanism — PLANNING generates a declarative spec, BUILDING performs gap analysis and implements toward it.

**Core philosophy:** Disk is memory. Each iteration gets fresh context. Spec file on disk is the single source of truth — a declarative description of the desired end state. Each build iteration performs gap analysis to autonomously determine what to do next. No context rot.

**Prompt templates:** Located in `templates/` relative to this SKILL.md file.

## When to Use

- User mentions "ralph", "ralph loop", or "ralph wiggum"
- User wants iterative implementation where each iteration starts with fresh context
- Implementation is large enough that context rot would degrade quality in a single session
- User wants to generate a declarative spec with acceptance criteria before building
- User asks for a subagent loop or autonomous iteration toward a spec

**What makes Ralph distinctive:** Normal implementation loads everything into one long session where context degrades over time. Ralph spawns a fresh subagent per iteration — each one reads the spec from disk, performs gap analysis, closes one gap, and exits. Disk is memory. No context rot.

**When NOT to use:**
- Quick implementations that fit comfortably in a single session
- User asks to "implement the plan" without needing iterative fresh-context execution

## Modes

| Mode | Command | Prompt | Purpose |
|------|---------|--------|---------|
| PLANNING | `/skill-set:ralph:plan` | `PROMPT_plan.md` | Generate/refine a declarative spec |
| BUILDING | `/skill-set:ralph:execute` | `PROMPT_build.md` | Gap analysis + implement, one gap per iteration |

Both modes share loop infrastructure: iteration control, circuit breaker, fresh context per subagent, progress tracking.

## Workflow

### Step 1: Determine Mode

| Condition | Mode |
|-----------|------|
| User invokes `/skill-set:ralph:plan` | PLANNING |
| User invokes `/skill-set:ralph:execute` + valid spec exists | BUILDING |
| User invokes `/skill-set:ralph:execute` + no valid spec | PLANNING first, then BUILDING |

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

### Step 4: Prepare Spec File

Create session directory and spec file path:

```
tmp/ralph/{YYYY-MM-DD-HHmm}/spec.md
```

- **PLANNING mode:** This is the output destination.
- **BUILDING mode:** Search for existing spec in priority order:
  1. Path explicitly provided by user
  2. Most recent `tmp/ralph/*/spec.md`
  3. Most recent `tmp/ralph/*/plan.md` (backward compatibility)
  4. Root `*spec*` or `*plan*` files
  5. If not found → enter PLANNING mode first

Ensure `tmp/` is in the target project's `.gitignore`.

### Step 5: Construct Prompt

Read the appropriate template from `templates/`. Substitute:
- `{{AGENTS_FILE}}` → `AGENTS.md` or `CLAUDE.md` (whichever exists; remove referencing lines if neither exists)
- `{{SPEC_FILE}}` → spec file path
- `{{TEST_CMD}}` → detected test command from Step 2
- `{{SOURCE_DOC}}` → input document path (PLANNING only; remove the `0b.` orient line if no source document provided)

Hold the constructed prompt in memory — writing it to disk would pollute the project with infrastructure files that don't belong in the codebase.

### Step 6: Propose Done Condition

**Before starting the loop**, propose a concrete DONE condition to the user and get confirmation.

The DONE condition defines when the loop should terminate. It must be **observable and unambiguous** — something the loop controller or the subagent can evaluate without subjective judgment.

Examples of good DONE conditions:
- "All acceptance criteria verified as met"
- "The test suite passes and all acceptance criteria are satisfied"
- "3 features (auth, dashboard, API) are implemented and all criteria met"
- "The spec's acceptance criteria section has no unmet items"

**Workflow:**
1. Analyze the spec (or stated goals for PLANNING mode)
2. Propose a DONE condition to the user
3. User confirms or adjusts
4. Include the confirmed DONE condition in the loop's completion check

The DONE condition is passed to each subagent as part of the prompt context, so every fresh-context iteration knows the target.

### Step 7: Execute Loop

Each iteration: spawn fresh Task subagent → wait for completion → check progress → evaluate DONE condition.

- **Progress detection:** New git commits OR spec file hash changes count as progress
- **Circuit breaker:** 3 consecutive iterations with no progress → ask user
- **Subagent:** `general-purpose`, model `sonnet` (default), same repo. No worktree isolation — each iteration needs to see the previous iteration's commits and file changes for accurate gap analysis.
- **Model choice:** Sonnet is the default because each iteration performs a well-scoped task (close one gap). Opus-level reasoning is valuable for planning, but gap analysis with a clear spec doesn't need it — and the cost difference compounds across many iterations.
- **Max iterations:** 100
- **PLANNING → BUILDING transition:** Report generated spec to user, confirm, propose DONE condition, then switch to BUILDING mode

**Full loop pseudocode and subagent configuration:** See [reference/workflow.md](reference/workflow.md)

### Step 8: Report Results

Display final summary (adapt to user's language):

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Ralph Loop Complete
  Mode:       {PLANNING | BUILDING}
  Iterations: {iteration}
  Spec:       {spec_file_path}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

If incomplete, suggest next steps:
- Review the spec and re-run
- Refine input and re-plan

## Progress Tracking

**New commits OR spec file modifications count as progress.** Both modes use the same metric.

- New git commit = progress
- Spec file changed (hash differs) = progress
- Neither changed = no progress
- Stuck: 3 consecutive iterations with no progress → ask user

This means blocker handling (updating spec with blocker notes without committing code) still counts as progress, preventing false stuck detection.

## Spec File Structure

A single self-contained file with three sections: **Context** (goals, constraints), **Acceptance Criteria** (declarative outcomes), and **Progress Log** (populated by build iterations). Acceptance Criteria stay frozen during BUILDING — if build iterations could edit criteria, they might silently lower the bar or mark things "done" by redefining what "done" means. Use PLANNING mode to intentionally revise criteria.

**Full structure, key properties, and examples:** See [reference/workflow.md](reference/workflow.md) and [reference/spec-quality.md](reference/spec-quality.md)

## Common Mistakes

| Mistake | Fix |
|---|---|
| Writing imperative tasks instead of acceptance criteria | Describe desired outcomes. "GET /api/users returns paginated results" not "Add pagination to /api/users." |
| Skipping DONE condition proposal | Always propose and confirm DONE condition before starting the loop. |
| Modifying acceptance criteria during BUILDING | Criteria stay frozen so build iterations can't silently lower the bar. Append only to Progress Log. Use PLANNING to revise criteria. |
| Using opus for loop iterations | Each iteration closes one well-scoped gap — sonnet handles this well and the cost difference compounds across many iterations. Reserve opus for planning. |
| Writing files into the project | Prompt stays in memory, spec goes to tmp/ralph/. Infrastructure files don't belong in the codebase. |
| Running multiple iterations in parallel | Each iteration's gap analysis depends on the previous iteration's commits. Sequential execution is essential for correctness. |
| Fabricating quantitative targets | Invented numbers (e.g., "reduce by 30%") become acceptance criteria that can't be verified, causing build iterations to chase fictional goals. Only include numbers the user stated or evidence supports. |
| Skipping user confirmation on spec | Always preview and confirm before transitioning PLANNING → BUILDING. |

## Reference

The `templates/` directory contains prompt templates:
- `PROMPT_plan.md` — Planning mode prompt (generate/refine spec)
- `PROMPT_build.md` — Building mode prompt (gap analysis + implement)
- `loop.sh` — Bash loop script for external execution (reference only)

The `reference/` directory contains:
- `workflow.md` — Loop pseudocode, subagent configuration, spec file structure details
- `spec-quality.md` — Criteria for Ralph-ready specs (used as verification during PLANNING)

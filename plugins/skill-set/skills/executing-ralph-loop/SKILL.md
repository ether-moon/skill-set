---
name: executing-ralph-loop
description: >
  Use when user explicitly mentions "ralph loop", "ralph wiggum", or "ralph" in the context of
  executing an implementation plan with fresh context per iteration.
---

# Executing Ralph Loop

## Overview

Executes an implementation plan via Geoffrey Huntley's Ralph Wiggum technique: a **loop where each iteration spawns a fresh Task subagent**. Each subagent reads the plan from disk, implements one task, commits, and exits. The main session acts as the loop controller — tracking progress, detecting stuck iterations, and reporting results.

**Core philosophy:** Disk is memory. Each iteration gets fresh context. Plan file on disk is the single source of truth. No context rot.

**Prompt template:** Located at `templates/PROMPT_build.md` relative to this SKILL.md file. Use the directory path of this SKILL.md to resolve template paths.

## When to Use

- User explicitly mentions "ralph" in the context of plan execution
- User mentions "ralph loop", "ralph wiggum"
- Plan exists as any markdown file with implementation steps

**When NOT to use:**
- User asks to "implement the plan" without mentioning "ralph" → use other execution skills
- No plan exists yet → guide user to create a plan first (any markdown with clear implementation steps)

## Workflow

### Step 1: Find Plan File

Search in priority order:
1. Path explicitly provided by user
2. `plans/*.md`
3. Root `*plan*.md`, `*PLAN*.md`
4. `tasks/*.md`

If not found, ask user for the path. If no plan exists, guide to plan creation first.

### Step 2: Validate and Reinforce Plan

Assess the plan for ralph loop readiness. A good plan has:
- Clear, independently executable tasks (each completable in one iteration)
- Concrete acceptance criteria or verification commands per task
- Specific file paths, function names, or code references where relevant

**If the plan lacks task boundaries or acceptance criteria:** Reinforce the plan before proceeding. Add missing details (file paths, test expectations, concrete steps) and show the preview to the user for confirmation. Do NOT skip this — vague tasks cause stuck iterations.

Then ensure checkbox format:

Count `- [ ]` / `- [x]` / `* [ ]` / `* [x]` patterns in the plan file.

**Any checkboxes exist (1+):** Report status (N remaining, M done) and continue. Do not reconvert.

**No checkboxes (0):** Extract tasks and convert:

| Plan Structure | Conversion Strategy |
|---|---|
| Numbered list (`1.`, `2.`) | Each numbered item → `- [ ]` |
| Headings (`## Task`, `### Step`) | Each section title → task |
| Bullet list (`-`, `*`) | Concrete action items → `- [ ]` |
| Unstructured prose | Ask user to identify tasks |

**Conversion rules:**
- Only convert top-level items to checkboxes. Sub-bullets under a task are preserved as indented context, NOT converted to checkboxes.
- Sections titled `Verification`, `Acceptance Criteria`, `Definition of Done`, `Notes`, or similar are preserved as-is — they are not tasks.
- Preserve original content (file paths, code snippets, verification commands) under each task.
- Default to in-place conversion; use top-inserted `## Task Checklist` only when task boundaries are unclear.
- **Always show preview and get user confirmation before modifying plan file.**
- Create backup (`plan.md.bak`) before any modification.

### Step 3: Detect Project Environment

Auto-detect, show results, and ask user to confirm or correct before proceeding:
- Language/framework (package.json → Node, Gemfile → Rails, etc.)
- Test command (`npm test`, `bundle exec rspec`, `pytest`, etc.)
- Lint command (`eslint`, `rubocop`, etc.) — detected for AGENTS.md but NOT injected into prompt (lint is the developer's responsibility, not per-iteration overhead)
- Default branch (`git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'`, fallback to `main`)

### Step 4: Verify AGENTS.md

Check for AGENTS.md or CLAUDE.md at project root.
- **Exists:** Verify it contains build/test commands. Suggest additions if missing.
- **Missing:** Offer to create minimal AGENTS.md from Step 3 detection results.
- **User declines creation:** Remove the `0a.` orient line from the constructed prompt entirely. The loop can still function with just the plan file and test command.

### Step 5: Construct Prompt

Read template from `templates/PROMPT_build.md` (relative to this SKILL.md). Substitute:
- `{{AGENTS_FILE}}` → `AGENTS.md` or `CLAUDE.md` (whichever exists)
- `{{PLAN_FILE}}` → confirmed plan path
- `{{TEST_CMD}}` → detected test command from Step 3

Hold the constructed prompt in memory. Do NOT write files into the project.

### Step 6: Execute Loop

Report loop start to user with task counts, then run:

```
iteration = 0
stuck_count = 0
prev_remaining = 0

while true:
  1. Read plan file → count [ ] (remaining), [x] (done), [!] (blocked)

  2. If remaining == 0 → all tasks complete, break

  3. iteration += 1
     Report: "Iteration {iteration} — {remaining} remaining, {done} done, {blocked} blocked"

  4. Spawn Task subagent:
     - subagent_type: "general-purpose"
     - prompt: the constructed prompt from Step 5
     - description: "Ralph iteration {iteration}"

  5. Wait for subagent completion

  6. Re-read plan file → count new_remaining
     If iteration > 1 AND new_remaining == prev_remaining:
       stuck_count += 1
       Report: "Warning: No progress detected ({stuck_count} consecutive)"
       If stuck_count >= 3:
         Report: "STUCK: No progress for 3 consecutive iterations. Stopping."
         break
     Else:
       stuck_count = 0
     prev_remaining = new_remaining
```

**Subagent configuration:**
- Model: `sonnet` (default). Sufficient for well-defined tasks. User can request different model.
- No isolation (worktree) — subagent works in same repo.
- Subagent has access to all tools (general-purpose agent).

### Step 7: Report Results

Display final summary (adapt to user's language):

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Ralph Loop Complete
  Iterations: {iteration}
  Done:       {done}
  Blocked:    {blocked}
  Remaining:  {remaining}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

If blocked or remaining tasks exist, suggest next steps:
- Review blocked tasks for blocker notes
- Refine the plan and re-run

## Common Mistakes

| Mistake | Fix |
|---|---|
| Skipping user confirmation on plan changes | Always preview and confirm before modifying plan file |
| Overly verbose prompt template | Keep prompt concise (~25 lines). Verbose inputs degrade determinism. |
| Using opus for loop iterations | Sonnet is sufficient for well-defined tasks. Save opus for planning. |
| Converting sub-bullets or verification sections to checkboxes | Only top-level task items become checkboxes. Sub-items and metadata sections are context. |
| Writing files into the project | The prompt is constructed in memory. No `ralph/` directory created in the project. |
| Running multiple iterations in parallel | Tasks are sequential — each iteration depends on the previous commit. One subagent at a time. |

## Key Principle

**Fresh context via Task subagents.** Each iteration spawns a new subagent with no memory of previous iterations. The plan file on disk is the only state. Git commits are the audit trail. This eliminates context rot while keeping execution within the Claude Code session.

## Reference

The `templates/` directory contains reference implementations:
- `loop.sh` — Bash loop script for external execution (alternative approach)
- `PROMPT_build.md` — Prompt template used for each iteration

---
name: executing-ralph-loop
description: >
  Use when user mentions "ralph loop", "ralph wiggum", wants to execute a plan via external bash
  loop with fresh context per iteration, or requests automated plan implementation. Triggers on
  "ralph loop", "ralph 실행", "plan을 ralph로", "계획대로 구현", "implement the plan" with
  ralph/loop context. Setup only — does NOT run the loop itself.
---

# Executing Ralph Loop

## Overview

Sets up infrastructure to execute an implementation plan via Geoffrey Huntley's Ralph Wiggum technique: an **external bash loop** where each iteration runs Claude with **fresh context**. The skill generates `ralph/loop.sh` and `ralph/PROMPT_build.md`, then the user runs the loop outside Claude.

**Core philosophy:** Disk is memory. Each iteration reads plan from disk, implements one task, commits, and exits. No context rot.

**Templates:** Located at `templates/loop.sh` and `templates/PROMPT_build.md` relative to this SKILL.md file. Use the directory path of this SKILL.md to resolve template paths.

## When to Use

- User has a plan file and wants to execute it via ralph loop
- User mentions "ralph loop", "ralph wiggum", "ralph 실행"
- User wants automated plan execution with fresh context per iteration
- Plan exists as any markdown file with implementation steps

**When NOT to use:**
- User wants to execute plan within current session → not needed, execute directly
- No plan exists yet → guide user to create a plan first (any markdown with clear implementation steps)
- Plan exists but lacks clear task boundaries or acceptance criteria → suggest reinforcing the plan before loop setup

## Workflow

### Step 1: Find Plan File

Search in priority order:
1. Path explicitly provided by user
2. `plans/*.md`
3. Root `*plan*.md`, `*PLAN*.md`
4. `tasks/*.md`

If not found, ask user for the path. If no plan exists, guide to plan creation first.

### Step 2: Ensure Task Checkboxes

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
- Lint command (`eslint`, `rubocop`, etc.) — detected for AGENTS.md but NOT injected into PROMPT_build.md (lint is the developer's responsibility, not per-iteration overhead)
- Default branch (`git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'`, fallback to `main`)

### Step 4: Verify AGENTS.md

Check for AGENTS.md or CLAUDE.md at project root.
- **Exists:** Verify it contains build/test commands. Suggest additions if missing.
- **Missing:** Offer to create minimal AGENTS.md from Step 3 detection results.
- **User declines creation:** Remove the `0a.` orient line from the generated PROMPT_build.md entirely. The loop can still function with just the plan file and test command.

### Step 5: Generate loop.sh

Read template from `templates/loop.sh` (relative to this SKILL.md). Substitute:
- `{{PLAN_FILE}}` → confirmed plan path (relative to project root)
- `{{MODEL}}` → user preference (default: `sonnet`). Verify the alias is valid for the installed `claude` CLI version. Full model IDs like `claude-sonnet-4-5` also work.

Create `ralph/` directory if it doesn't exist (`mkdir -p ralph`). Write to `ralph/loop.sh` in the **target project root**. Make executable (`chmod +x`).

**Permissions note:** The template uses `--dangerously-skip-permissions` by default. This is intentional — the loop must have full tool access for implementation work, and the allowed toolset varies by project. Users who prefer granular control should replace it with `--allowedTools` or configure permissions via project/user settings.

**Verbose flag:** The template includes `--verbose` for debugging iteration behavior. For quieter output in long runs, remove it from the generated `loop.sh`.

### Step 6: Generate PROMPT_build.md

Read template from `templates/PROMPT_build.md` (relative to this SKILL.md). Substitute:
- `{{AGENTS_FILE}}` → `AGENTS.md` or `CLAUDE.md` (whichever exists)
- `{{PLAN_FILE}}` → confirmed plan path
- `{{TEST_CMD}}` → detected test command from Step 3

Write to `ralph/PROMPT_build.md` in the **target project root**.

### Step 7: Show Execution Instructions

Display to user (adapt to user's language). **Substitute the actual plan path** into monitor commands — do not output literal placeholders.

```
Generated:
  ralph/loop.sh         — External bash loop (chmod +x done)
  ralph/PROMPT_build.md — Prompt injected each iteration

Run:
  ./ralph/loop.sh           # Unlimited (Ctrl+C to stop)
  ./ralph/loop.sh 15        # Max 15 iterations
  ./ralph/loop.sh 20        # Default recommendation: 20

Monitor (in another terminal):
  while true; do clear; grep -c '\[ \]' <actual-plan-path>; sleep 5; done
  git log --oneline -10

If the plan goes off track:
  Stop the loop, regenerate plan, restart.
  Plans are disposable — regeneration costs one iteration.
```

## Common Mistakes

| Mistake | Fix |
|---|---|
| Running loop inside Claude session | Loop MUST run in external bash. This skill only sets up files. |
| Skipping user confirmation on plan changes | Always preview and confirm before modifying plan file |
| Overly verbose PROMPT_build.md | Keep prompt concise (~25 lines). Verbose inputs degrade determinism. |
| Using opus for loop iterations | Sonnet is sufficient for well-defined tasks. Save opus for planning. |
| Converting sub-bullets or verification sections to checkboxes | Only top-level task items become checkboxes. Sub-items and metadata sections are context. |

## Key Principle

**This skill is setup-only.** It generates files. It never runs the loop. The external bash loop is what makes Ralph work — fresh context every iteration, disk as memory, git as the audit trail. Running the loop inside Claude would recreate the same context-rot problem that the official plugin has.

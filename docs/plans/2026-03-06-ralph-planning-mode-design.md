# Ralph Planning Mode Design

> Add a PLANNING mode to the ralph skill so that it can generate Ralph-ready plans from any input source and then execute them.

**Goal:** Enable the ralph loop to create its own plans — not just execute pre-existing ones — using the same loop mechanism with a different prompt.

**Architecture:** Single skill, two modes (PLANNING / BUILDING), two prompts. PLANNING mode reads input sources and generates a self-contained plan file. BUILDING mode implements from that plan. Both share loop infrastructure.

---

## Problem

The current ralph skill only executes plans. When no plan exists, it says "guide user to create a plan first" — a single line with no process behind it. Users must manually create Ralph-compatible plans or rely on external skills that may not be installed.

This creates three concrete failures:

1. **No plan → no ralph.** Users with an idea but no plan document can't use ralph at all.
2. **Bad plan → stuck loops.** Plans not structured for ralph (vague tasks, missing context, no verification criteria) cause iterations to spin without progress.
3. **External dependency.** Relying on upstream planning skills that may not be available makes the workflow fragile.

---

## Design

### Two Modes, One Skill

Mirrors Ghuntley's original architecture: same `loop.sh`, different prompt file.

```
/skill-set:ralph:plan     → PLANNING mode (PROMPT_plan.md)
/skill-set:ralph:execute  → BUILDING mode (PROMPT_build.md)
                            → plan 없으면 자동으로 PLANNING 먼저 실행
```

Both modes share:
- Loop infrastructure (iteration, circuit breaker, fresh context per subagent)
- File I/O pattern (read plan → update plan)
- Git commit-based progress tracking
- Stuck detection

### PLANNING Mode

**Purpose:** Generate a Ralph-ready plan from any input.

**Input sources (all optional, any combination):**
- A document the user points to (design doc, notes, existing plan, README)
- Verbal requirements from conversation
- Codebase alone (gap analysis — no document needed)

No specific upstream skill or document format is required. If brainstorming or planning skills produced a design doc beforehand, PLANNING mode naturally consumes it. If nothing exists, PLANNING mode works from codebase exploration and user-stated goals.

**Execution:** Runs as a loop (not a single call). First iteration generates a plan draft. Subsequent iterations read their own output, review, and refine. This allows the plan to self-improve across iterations — catching gaps, reordering priorities, adding missing context.

**Prompt template** (`PROMPT_plan.md`):

The planning prompt instructs the subagent to:

1. **Orient** — Read the input source document (if provided) and explore the codebase with parallel subagents to understand current state.
2. **Analyze** — Compare requirements against existing code. Identify gaps, TODOs, placeholders, missing functionality. Do not assume something is missing without confirming via code search.
3. **Generate/Update plan** — Create or update the plan file with:
   - A Context section summarizing goals, constraints, and technical background
   - A prioritized task list as free-form bullet points, sorted by importance
   - Discoveries, dependencies, and risks noted inline
4. **Do NOT implement.** Planning only. No code changes, no commits.

Template variables:
- `{{SOURCE_DOC}}` (optional) — path to input document
- `{{PLAN_FILE}}` — path to plan file being generated
- `{{AGENTS_FILE}}` — AGENTS.md or CLAUDE.md if present

### Plan File Structure

Single file. No separate spec files. The plan is self-contained.

```markdown
## Context

[Core requirements, constraints, technical background.
 Concise but sufficient — no arbitrary line limits.
 Every iteration reads this, so avoid unnecessary repetition
 while preserving enough information for a fresh-context agent
 to understand the project's goals and boundaries.]

## Tasks

- Task description with enough detail for independent implementation
  Related files, verification approach, dependencies
- Another task, prioritized by importance
  ...
```

**Key properties:**
- **Free-form bullet points.** No checkbox format (`- [ ]`) enforced. LLM manages the format naturally.
- **Context section replaces separate specs.** Each iteration reads the plan and gets both requirements context and task list in one file.
- **Living document.** BUILDING mode iterations update the plan with discoveries, completed work, and new findings.
- **Disposable.** If the plan drifts or becomes stale, re-run PLANNING mode to regenerate.

### BUILDING Mode Changes

Current `PROMPT_build.md` changes:

| Current | Changed |
|---------|---------|
| "Pick the first `[ ]` task" | "Choose the most important task" — LLM selects based on priority, dependencies, current state |
| Checkbox-based progress | Removed. LLM marks completed items in whatever format it chooses |
| `[ ]` / `[x]` / `[!]` counting | Removed from loop controller |

### Progress Tracking

**Git commit-based only.** No checkbox counting.

```
Loop controller per iteration:
  1. Save prev_head = git rev-parse HEAD
  2. Spawn subagent
  3. Check curr_head = git rev-parse HEAD
  4. Progress = (curr_head != prev_head)
```

**Stuck detection:** If no new commit for N consecutive iterations, warn user. After 3 consecutive stuck iterations, ask user whether to continue or stop. This logic already exists in the current implementation — the change is removing the checkbox-based parallel check.

**Completion detection:** Loop controller can no longer count remaining tasks from checkboxes. The subagent should update the plan to reflect completion state. The loop controller checks whether the plan still contains actionable items by reading the file after each iteration.

### Auto-Planning in Execute

When `/skill-set:ralph:execute` is invoked:

1. Search for plan file in `tmp/ralph/*/plan.md` (most recent session) or user-provided path
2. If found → validate Ralph-readiness (has Context section? has actionable tasks?)
3. If not found or not Ralph-ready → automatically enter PLANNING mode first
4. After planning completes → transition to BUILDING mode

### Plan File Location

Plan files are **temporary and session-scoped**. PLANNING mode writes to:

```
tmp/ralph/{session-id}/plan.md
```

Session ID uses timestamp format: `YYYY-MM-DD-HHmm` (e.g., `tmp/ralph/2026-03-06-1430/plan.md`).

This means:
- Plans don't clutter the project root or permanent directories
- Multiple ralph sessions can coexist without conflict
- Plans are naturally disposable — `tmp/` signals impermanence
- Git ignores them (add `tmp/` to `.gitignore` if not already present)

The plan file path is passed to both PLANNING and BUILDING prompts via `{{PLAN_FILE}}`.

### Command Structure

```
commands/ralph/                     # renamed from ralph-loop/
├── plan.md                         # /skill-set:ralph:plan
└── execute.md                      # /skill-set:ralph:execute
```

### File Changes

```
skills/ralph/                       # renamed from executing-ralph-loop/
├── SKILL.md                        # Add mode branching, update workflow
├── templates/
│   ├── PROMPT_plan.md              # New: planning mode prompt
│   ├── PROMPT_build.md             # Modified: free-form task selection
│   └── loop.sh                     # Modified: commit-based tracking only
└── reference/
    └── plan-quality.md             # New: what makes a plan Ralph-ready
```

### Iteration Limits

| Mode | Default Max | Rationale |
|------|------------|-----------|
| PLANNING | 100 | Effectively unlimited. Stuck detection (3 consecutive no-progress) is the real control. |
| BUILDING | 100 | Same. Most projects complete well before this limit. |

---

## What Does NOT Change

- **Subagent model**: Task subagents with fresh context per iteration.
- **Core philosophy**: Disk is memory. Fresh context. Plan file is single source of truth.
- **Environment detection**: Auto-detect language, test command, AGENTS.md. Unchanged.
- **AGENTS.md handling**: Verify/create operational guide. Unchanged.

---

## Risks and Mitigations

| Risk | Mitigation |
|------|-----------|
| PLANNING mode generates vague plans | `reference/plan-quality.md` defines Ralph-ready criteria. PLANNING prompt includes explicit instructions for concrete, independently-executable tasks. Loop iterations self-review and refine. |
| Free-form plans make completion detection unreliable | Subagent is instructed to clearly mark task status. Loop controller uses commit-based progress as primary signal. |
| Context section grows too large over iterations | PLANNING prompt instructs conciseness. If context balloons, user can re-run planning to regenerate a clean plan. |
| Auto-planning in execute mode surprises users | Announce mode transition clearly: "No Ralph-ready plan found. Starting planning mode first." Get user confirmation before proceeding. |
| Plan in tmp/ lost after cleanup | By design. Plans are disposable. If user wants to preserve, they copy it out of tmp/. |

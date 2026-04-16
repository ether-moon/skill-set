# Resolution Reference

Detailed formats and workflows for the five resolution phases. Use this alongside SKILL.md for the complete process.

## Table of Contents

- [Phase 1: Classify & Register Tasks](#phase-1-classify--register-tasks)
- [Phase 2: Classification Report](#phase-2-classification-report)
- [Phase 3: Discuss Ambiguous Items](#phase-3-discuss-ambiguous-items)
- [Individual Review Workflow (Choice 2)](#individual-review-workflow-choice-2)
- [Phase 4: Batch Execute](#phase-4-batch-execute)
- [Phase 5: Summary](#phase-5-summary)
- [Statistics Format](#statistics-format)

## Phase 1: Classify & Register Tasks

Walk through every item from the source and apply the classification criteria from SKILL.md. **Do not execute any fixes during this phase.**

For each actionable item (OBVIOUS or AMBIGUOUS), create a task:

1. **Classification**: OBVIOUS or AMBIGUOUS (with severity for AMBIGUOUS)
2. **Target**: file path and line number
3. **Description**: what the source identified and the planned fix
4. **Source**: who or what raised the issue

Skip items matching the ALWAYS SKIP criteria — do not create tasks for them.

### Task Registration Format

```
Task subject: [OBVIOUS|AMBIGUOUS/severity] description — `file:line`
Task description:
  - Source: @reviewer / linter rule / security scan
  - Issue: what was identified
  - Planned fix: what will be changed (for OBVIOUS)
  - Analysis: why ambiguous + recommendation (for AMBIGUOUS)
```

All tasks start in `pending` status.

## Phase 2: Classification Report

Present the full classification to the user. Nothing has been executed yet — the user sees the complete picture before any discussion or code changes.

### OBVIOUS Items Queued

```
N items classified as obvious (queued for auto-fix):
- `path/to/file.ts:42` — Fix null check (source: linter rule no-null-deref)
- `path/to/file.ts:87` — Remove unused import (source: @reviewer)
- `path/to/utils.py:15` — Add missing await (source: static analysis)
```

If no OBVIOUS items exist, state that clearly and move on.

### AMBIGUOUS Items Listed

Present AMBIGUOUS items grouped by severity: CRITICAL first, then MAJOR, then MINOR. Within each group, order by file path for easy navigation.

### Per-Item Format

```
### CRITICAL (N items)

**1. [One-line description]** — `file/path:line` (source: @name or tool)
- Issue: What the source identified
- Why ambiguous: What makes this debatable — the trade-off, uncertainty, or design choice
- Recommendation: Suggested action with rationale
```

### Example

```
### CRITICAL (1 item)

**1. Race condition in user update** — `src/api/users.ts:134` (source: @bob)
- Issue: Concurrent updates may overwrite each other
- Why ambiguous: Fix requires choosing between optimistic locking, pessimistic locking, or retry logic — each has different performance and complexity trade-offs
- Recommendation: Apply optimistic locking — least invasive, matches existing pattern in `orders.ts`

### MAJOR (1 item)

**2. N+1 query in listing endpoint** — `src/api/products.ts:67` (source: security scan)
- Issue: Each product triggers a separate category lookup
- Why ambiguous: Can be fixed with eager loading (simple but may over-fetch), join query (efficient but changes return shape), or caching (fast reads but stale risk)
- Recommendation: Eager loading — simplest fix, dataset is small enough that over-fetching is negligible

### MINOR (2 items)

**3. Extract validation logic** — `src/api/users.ts:45` (source: @coderabbitai)
- Issue: Validation logic is inline, could be a separate function
- Why ambiguous: Current code is 8 lines and used once — extraction adds indirection without clear benefit yet
- Recommendation: Skip — extract when a second caller appears

**4. Rename `data` to `userProfile`** — `src/api/users.ts:12` (source: @alice)
- Issue: Generic variable name reduces readability
- Why ambiguous: `data` is used in 3 destructuring patterns below — rename affects readability of those too
- Recommendation: Apply — improves clarity and the destructuring patterns still read well
```

If no AMBIGUOUS items exist, skip directly to Phase 4.

## Phase 3: Discuss Ambiguous Items

### Choice Offerings

After presenting all ambiguous items:

```
How would you like to proceed?
- [1] Apply all recommended
- [2] Review individually
- [3] Skip all
```

### Updating Tasks Per Decision

- **Choice 1 (Apply all)**: All AMBIGUOUS tasks remain `pending` — approved for execution.
- **Choice 2 (Review individually)**: Walk through each; mark skipped items as `completed` (skipped). See below.
- **Choice 3 (Skip all)**: Mark all AMBIGUOUS tasks as `completed` (skipped).

## Individual Review Workflow (Choice 2)

Walk through each item one at a time:

1. Show the current code (relevant lines with context)
2. Show the suggested change (diff or description)
3. Show the analysis (why ambiguous + recommendation)
4. Ask: **Apply? [Y/n/skip]**
   - **Y** (default): Task stays `pending` — approved for execution
   - **n**: Mark task as `completed` (skipped)
   - **skip**: Mark this and all remaining AMBIGUOUS tasks as `completed` (skipped)

## Phase 4: Batch Execute

After all decisions are finalized, execute every remaining `pending` task — both OBVIOUS and user-approved AMBIGUOUS items — in a single batch.

If no approved tasks remain (all items were skipped or classified as SKIP), skip to Phase 5 with a note that nothing was applied.

### Confirm Before Executing

Show the execution plan:

```
Ready to apply N changes:

OBVIOUS: X items
AMBIGUOUS (approved): Y items
  - `src/api/users.ts:134` — Optimistic locking for race condition
  - `src/api/users.ts:12` — Rename `data` to `userProfile`
Skipped: Z items

Proceed? [Y/n]
```

Only execute after explicit user confirmation.

### Parallel Execution via Subagents

1. **Group by file**: Collect all approved tasks targeting the same file into one group. Tasks touching different files are independent.
2. **Launch subagents**: Dispatch one Agent subagent per file group concurrently (e.g., 5 files -> 5 parallel subagents). Tasks within the same file must be applied sequentially by a single subagent to avoid edit conflicts.
3. **Each subagent** performs:
   - Read the target file
   - Apply each fix in sequence using the appropriate edit tool
   - Verify the fix didn't break surrounding code
   - Mark each task as `completed` on success
   - Return results: list of applied fixes + any failures
4. **Collect results**: Wait for all subagents to complete before moving to Phase 5.

**On failure:** The subagent marks the task as `completed` with failure details in the description (conflict, unexpected state, side effect) and continues with remaining tasks in the same file group. Failed tasks are distinguished from successful ones in the summary.

## Phase 5: Summary

Report the outcome of the batch execution:

```
Applied N of M changes:

Successful:
- `path/to/file.ts:42` — Fixed null check
- `path/to/file.ts:87` — Removed unused import
- `src/api/users.ts:134` — Applied optimistic locking
- `src/api/users.ts:12` — Renamed `data` to `userProfile`

Failed (N items):
- `path/to/file.ts:63` — Type narrowing: fix conflicted with overload

Skipped: Z items
```

If any tasks failed, explain what went wrong and suggest next steps (manual fix, alternative approach, etc.).

## Statistics Format

For summary reports (e.g., PR comments, audit logs):

```
Total items reviewed: N
- Auto-fixed (OBVIOUS): X
- Applied after discussion (AMBIGUOUS): Y
- Failed: F
- Skipped: Z
```

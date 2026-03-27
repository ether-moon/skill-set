# Resolution Reference

Detailed formats and workflows for the four resolution phases. Use this alongside SKILL.md for the complete process.

## Table of Contents

- [Phase 1: Auto-fix Obvious Items](#phase-1-auto-fix-obvious-items)
- [Phase 2: Auto-fix Report Format](#phase-2-auto-fix-report-format)
- [Phase 3: Ambiguous Item Presentation](#phase-3-ambiguous-item-presentation)
- [Individual Review Workflow (Choice 2)](#individual-review-workflow-choice-2)
- [Phase 4: Final Confirmation](#phase-4-final-confirmation)
- [Statistics Format](#statistics-format)

## Phase 1: Auto-fix Obvious Items

**Parallelize using subagents** to minimize wall-clock time:

1. **Group by file**: Collect all OBVIOUS items targeting the same file into one group. Items touching different files are independent.
2. **Launch subagents**: Dispatch one Agent subagent per file group. If items span many files, launch them concurrently (e.g., 5 files → 5 parallel subagents). Items within the same file must be applied sequentially by a single subagent to avoid edit conflicts.
3. **Each subagent** performs:
   - Read the target file
   - Apply each fix in sequence using the appropriate edit tool
   - Verify the fix didn't break surrounding code
   - Return results: list of applied fixes + any failures
4. **Collect results**: Wait for all subagents to complete before moving to Phase 2.

**On failure:** The subagent moves the item to AMBIGUOUS with:
- Original classification rationale
- What went wrong (conflict, unexpected state, side effect)
- Continue with remaining items in the same file group

## Phase 2: Auto-fix Report Format

Present to the user after all OBVIOUS items are processed:

```
Applied N obvious fixes:
- `path/to/file.ts:42` — Fixed null check (source: linter rule no-null-deref)
- `path/to/file.ts:87` — Removed unused import (source: @reviewer)
- `path/to/utils.py:15` — Added missing await (source: static analysis)
```

If any OBVIOUS items were moved to AMBIGUOUS due to failure:

```
1 item moved from obvious to ambiguous (auto-fix failed):
- `path/to/file.ts:63` — Type narrowing: attempted fix conflicted with overload
```

If no OBVIOUS items existed, skip this phase entirely.

## Phase 3: Ambiguous Item Presentation

### Grouping

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

### Choice Offerings

After presenting all ambiguous items:

```
How would you like to proceed?
- [1] Apply all recommended
- [2] Review individually
- [3] Skip all
```

## Individual Review Workflow (Choice 2)

Walk through each item one at a time:

1. Show the current code (relevant lines with context)
2. Show the suggested change (diff or description)
3. Show the analysis (why ambiguous + recommendation)
4. Ask: **Apply? [Y/n/skip]**
   - **Y** (default): Apply the recommendation
   - **n**: Skip this item
   - **skip**: Skip this and all remaining items

Track decisions for the final confirmation.

## Phase 4: Final Confirmation

Before applying any user-approved changes, show a complete summary:

```
Summary of changes to apply:

OBVIOUS (auto-applied): 3 items
AMBIGUOUS (approved): 2 items
  - `src/api/users.ts:134` — Optimistic locking for race condition
  - `src/api/users.ts:12` — Rename `data` to `userProfile`
Skipped: 2 items
  - `src/api/users.ts:45` — Extract validation (deferred)
  - `src/api/products.ts:67` — N+1 query (alternative approach preferred)

Proceed? [Y/n]
```

Only apply after explicit user confirmation.

## Statistics Format

For summary reports (e.g., PR comments, audit logs):

```
Total items reviewed: N
- Auto-fixed (OBVIOUS): X
- Applied after discussion (AMBIGUOUS): Y
- Skipped: Z
```

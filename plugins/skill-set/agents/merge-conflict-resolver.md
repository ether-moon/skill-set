---
name: merge-conflict-resolver
description: Resolves merge conflicts by fetching the target branch, identifying conflicting files, and applying the autofixing-and-escalating skill to classify each conflict as obvious or ambiguous. Called as a sub-agent from resolving-pr-blockers orchestrator.
---

# Merge Conflict Resolver

## Overview

Sub-agent that resolves merge conflicts in the current branch against the PR's target branch. Uses the `autofixing-and-escalating` skill to classify conflicts: obvious conflicts (one-sided changes, lockfiles, auto-generated files) are resolved automatically; ambiguous conflicts (both sides made meaningful changes) are escalated to the user.

**Core principle:** Merge conflicts are items from an external source (git merge). Classify by clarity of resolution, not by file importance.

## Prerequisites

- Called by `resolving-pr-blockers` orchestrator
- Receives: PR number, target branch name, repository info
- Current branch has an open PR with merge conflicts

## Autofix & Escalation Framework

This agent applies the `autofixing-and-escalating` skill to merge conflicts.

**Before starting classification, read the skill:**
1. Find and read `autofixing-and-escalating/SKILL.md` from the plugin's skills directory
2. For edge cases, read `autofixing-and-escalating/reference/classification.md`

**Merge-conflict-specific terminology mapping:**
- "Source" = git merge (the merge operation that produced the conflict)
- "Item" = a conflict region within a file (between `<<<<<<<` and `>>>>>>>` markers)
- "Location" = file path + conflict region

**Merge-conflict-specific classification guidance:**

OBVIOUS (auto-resolve):
- Only one side made changes (the other side is identical to the merge base)
- Lockfiles (package-lock.json, yarn.lock, Gemfile.lock, go.sum, etc.) — always accept current branch and regenerate
- Auto-generated files (compiled outputs, build artifacts)
- Whitespace-only or formatting-only conflicts
- Import ordering conflicts where both sides added non-conflicting imports

AMBIGUOUS (escalate):
- Both sides made substantive changes to the same code region
- Semantic conflicts where logic was changed by both sides
- Configuration file changes where both values could be valid
- Test file conflicts where both sides added different test cases

## Language Detection

Detect and use the user's preferred language for all communication.

Detection priority:
1. User's current messages
2. Project context (CLAUDE.md, README.md)
3. Git history
4. Default to English

## Workflow

### Step 1: Fetch Target Branch and Merge

```bash
# Fetch latest target branch
git fetch origin <TARGET_BRANCH>

# Attempt merge (will produce conflicts)
git merge origin/<TARGET_BRANCH> --no-commit
```

If merge succeeds without conflicts, commit and exit early — the conflict may have been resolved by a prior push to the target branch.

### Step 2: Identify Conflicting Files

```bash
# List all files with conflicts
git diff --name-only --diff-filter=U
```

### Step 3: Classify Each Conflict

For each conflicting file:

1. Read the file to see conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`)
2. For each conflict region, determine:
   - What the current branch changed (ours)
   - What the target branch changed (theirs)
   - What the merge base had (common ancestor, via `git show :1:<file>` if needed)
3. Apply autofixing-and-escalating classification:
   - If only one side changed → OBVIOUS (accept the changed side)
   - If lockfile → OBVIOUS (accept ours, regenerate later)
   - If both sides changed substantively → AMBIGUOUS

### Step 4: Resolve

Follow the `autofixing-and-escalating` resolution workflow:

**Phase 1 — Auto-fix OBVIOUS conflicts:**
- Resolve each OBVIOUS conflict in the file
- Stage resolved files: `git add <file>`
- If a lockfile was involved, run the appropriate package manager to regenerate:
  ```bash
  # Example for Node.js
  npm install  # or yarn install
  ```

**Phase 2 — Report auto-fixes to user**
- List every auto-resolved conflict with file path and resolution rationale
- Never skip the report

**Phase 3 — Escalate AMBIGUOUS conflicts:**
- Present each ambiguous conflict with:
  - File path and conflict region
  - What "ours" changed
  - What "theirs" changed
  - Why it's ambiguous (the trade-off)
  - Recommendation
- Offer choices: [1] Apply all recommended, [2] Review individually, [3] Skip all

**Phase 4 — Apply user decisions and commit:**
```bash
git add <resolved-files>
git commit -m "resolve merge conflicts with <TARGET_BRANCH>"
```

Do NOT push — the orchestrator handles the final push.

### Step 5: Handle Unresolvable Conflicts

If any conflicts remain unresolved (user chose to skip):
- Abort the merge for those files: restore conflict markers
- Report which files still have conflicts
- The orchestrator will include this in the final report

## Error Handling

- If `git merge` fails for reasons other than conflicts, report the error
- If a lockfile regeneration command fails, report it but continue with other files
- If auto-resolution produces invalid code, move the item to AMBIGUOUS

## Common Mistakes

### Using Rebase Instead of Merge
**Problem:** Rebase rewrites history and can cause issues for shared branches.
**Fix:** Always use `git merge` for conflict resolution in PR context.

### Not Regenerating Lockfiles
**Problem:** Accepting one side's lockfile without regenerating leads to dependency inconsistencies.
**Fix:** After resolving lockfile conflicts, always run the package manager to regenerate.

## Success Criteria

- All conflict files identified
- Each conflict classified as OBVIOUS or AMBIGUOUS
- OBVIOUS conflicts auto-resolved with report to user
- AMBIGUOUS conflicts presented with rationale and recommendation
- Resolved files committed with descriptive message
- No unresolved conflict markers left in committed files

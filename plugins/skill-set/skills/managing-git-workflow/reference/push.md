# Push Workflow

Push changes to remote repository, automatically committing if needed.

## Prerequisites

- Git repository with remote configured
- Changes to push (committed or uncommitted)

## Steps

### 1. Check Current Status

```bash
# Check for uncommitted changes and unpushed commits
git status
```

**Exit if:** No changes and branch is up to date → Output appropriate message in project's language and stop

### 2. Auto-Commit if Needed

**If uncommitted changes exist**, follow the commit workflow:

**→ See `managing-git-workflow/reference/commit.md` for complete commit steps**

Quick reference:
```bash
# Check if uncommitted changes exist
git status --porcelain
```

If output is non-empty, follow commit.md workflow (git add, analyze, commit).

### 3. Check Branch Tracking Status

```bash
git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null
```

If command succeeds, upstream tracking exists. If it fails, will need `-u` flag on push.

### 4. Push to Remote

**If upstream exists:**
```bash
git push
```

**If no upstream tracking:**
```bash
git push -u origin "$(git branch --show-current)"
```

This sets up tracking for future pushes.

### 5. Verify and Report

```bash
git status
```

**Output to user:**
- Success message with branch name
- Number of commits pushed
- Current branch status

**Example output:**
```
✓ Successfully pushed to origin/feature-branch
  2 commits pushed
  Branch is up to date with 'origin/feature-branch'
```

## Common Issues

**Issue:** "No upstream tracking branch"
**Fix:** Automatically handled in step 4 with `-u` flag.

**Issue:** Push rejected (diverged branches)
**Fix:**
```bash
# Check status
git status

# If behind, pull first
git pull --rebase

# Then retry push
```

**Issue:** Authentication failed
**Fix:** User needs to configure git credentials or SSH keys. Not handled by this workflow.

## Equivalent Direct Commands

```bash
# Check for uncommitted changes (non-empty output = changes exist)
git status --porcelain

# Check for unpushed commits (>0 = unpushed)
git rev-list --count @{u}..HEAD 2>/dev/null

# Get current branch name
git branch --show-current

# Check upstream tracking (success = exists)
git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null
```

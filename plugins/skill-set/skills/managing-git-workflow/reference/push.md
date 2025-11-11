# Push Workflow

Push changes to remote repository, automatically committing if needed.

## Prerequisites

- Git repository with remote configured
- Changes to push (committed or uncommitted)

## Steps

### 1. Check Current Status

```bash
source .claude/skills/managing-git-workflow/git-helpers.sh

# Check for uncommitted changes and unpushed commits
git status
```

**Exit if:** No changes and branch is up to date → Output appropriate message in project's language and stop

### 2. Auto-Commit if Needed

**If uncommitted changes exist**, follow the commit workflow:

**→ See `managing-git-workflow/reference/commit.md` for complete commit steps**

Quick reference:
```bash
if has_uncommitted_changes; then
    # Follow commit.md workflow:
    # - git add -A
    # - Analyze patterns (git log --oneline -10)
    # - Generate message in project's language
    # - git commit -m "message"
fi
```

### 3. Check Branch Tracking Status

```bash
if has_upstream; then
    echo "Upstream tracking exists"
else
    echo "No upstream tracking - will set on push"
fi
```

### 4. Push to Remote

**If upstream exists:**
```bash
git push
```

**If no upstream tracking:**
```bash
git push -u origin $(get_current_branch)
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

## Helper Functions Reference

```bash
# Load helpers first
source .claude/skills/managing-git-workflow/git-helpers.sh

# Available functions:
has_uncommitted_changes  # Returns 0 if changes exist
has_unpushed_commits     # Returns 0 if unpushed commits exist
get_current_branch       # Echoes branch name
has_upstream             # Returns 0 if upstream tracking exists
```

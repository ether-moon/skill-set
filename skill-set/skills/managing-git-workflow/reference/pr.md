# Pull Request Workflow

Create a pull request with auto-generated title and description, automatically pushing if needed.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Steps](#steps)
   - [1. Validate Branch Status](#1-validate-branch-status)
   - [2. Auto-Commit and Push if Needed](#2-auto-commit-and-push-if-needed)
   - [3. Check for Existing PR](#3-check-for-existing-pr)
   - [4. Analyze Commits and Changes](#4-analyze-commits-and-changes)
   - [5. Generate PR Title and Description](#5-generate-pr-title-and-description)
   - [6. Create Pull Request](#6-create-pull-request)
   - [7. Open in Browser](#7-open-in-browser)
3. [Common Issues](#common-issues)
4. [Helper Functions Reference](#helper-functions-reference)
5. [Workflow Integration](#workflow-integration)

## Prerequisites

- Git repository with GitHub remote
- `gh` CLI installed and authenticated
- Not on master/main branch
- Changes to include in PR (committed, uncommitted, or pushed)

## Steps

### 1. Validate Branch Status

```bash
source .claude/skills/managing-git-workflow/scripts/git-helpers.sh

# Check current branch
if is_main_branch; then
    echo "ERROR: Cannot create PR from main/master branch"
    exit 1
fi

# Check for uncommitted changes
git status
```

### 2. Auto-Commit and Push if Needed

**If uncommitted changes exist** OR **if commits not pushed:**

**→ See `managing-git-workflow/reference/push.md` for complete push steps**

Push workflow automatically handles:
- Committing uncommitted changes (via `managing-git-workflow/reference/commit.md`)
- Pushing to remote with upstream tracking

Quick reference:
```bash
# This is handled by push.md, which handles commit.md
# Just follow the push workflow if needed
```

### 3. Check for Existing PR

```bash
if check_pr_exists; then
    pr_url=$(get_pr_url)
    echo "PR already exists: $pr_url"
    exit 0
fi
```

### 4. Analyze Commits and Changes

```bash
# Get commits since diverged from master
git log --oneline origin/master..HEAD

# Get change summary
git diff --stat origin/master..HEAD

# Extract ticket number from branch name
ticket=$(extract_ticket_from_branch)
```

### 5. Generate PR Title and Description

**Title format:**
```
[TICKET-123]: 기능 요약 (Korean)
```

**If no ticket number:**
```
기능 요약 (Korean)
```

**Description format:**
```markdown
## Summary
- 변경사항 요약 (bullet points in Korean)

## Changes
- 구체적인 변경 내용

## Test Plan
- [ ] 테스트 항목 1
- [ ] 테스트 항목 2
```

**Analysis for content:**
- Read commit messages from step 4
- Summarize overall purpose
- List specific changes from diff stat
- Generate test checklist based on changes

### 6. Create Pull Request

```bash
gh pr create \
  --title "<generated_title>" \
  --body "$(cat <<'EOF'
## Summary
- 변경사항 요약

## Changes
- 구체적인 변경 내용

## Test Plan
- [ ] 테스트 항목
EOF
)" \
  --base master
```

**Important:** Use HEREDOC for PR body to handle multi-line content correctly.

The command automatically uses current branch as head.

### 7. Open in Browser

```bash
# Get PR URL from gh output
pr_url=$(gh pr view --json url --jq .url)

# Open in browser (macOS)
open "$pr_url"
```

**Output to user:**
- PR URL
- PR title
- Success message

**Example output:**
```
✓ Pull request created: https://github.com/owner/repo/pull/123
  Title: FLEASVR-287: Github spec kit 설치

Opening in browser...
```

## Common Issues

**Issue:** "Not in a git repository" or "No GitHub remote"
**Fix:** Verify repository setup. This workflow requires GitHub remote.

**Issue:** "gh: command not found"
**Fix:** Install GitHub CLI: `brew install gh` (macOS) and authenticate with `gh auth login`

**Issue:** "Pull request already exists"
**Fix:** Automatically detected in step 3. Outputs existing PR URL instead.

**Issue:** Can't determine appropriate PR description
**Fix:** Analyze more context:
```bash
# Check files changed
git diff --name-only origin/master..HEAD

# Check detailed changes
git diff origin/master..HEAD
```

## Helper Functions Reference

```bash
# Load helpers first
source .claude/skills/git-workflow/scripts/git-helpers.sh

# Available functions:
is_main_branch()           # Returns 0 if on main/master
check_pr_exists()          # Returns 0 if PR exists for current branch
get_pr_url()               # Echoes PR URL if exists
extract_ticket_from_branch() # Echoes ticket number from branch name
get_current_branch()       # Echoes current branch name
```

## Workflow Integration

This workflow integrates the full stack:

```
pr.md
  ↓ (if needed)
push.md
  ↓ (if needed)
commit.md
```

Each level only executes if necessary, creating a seamless experience from uncommitted changes to published PR.

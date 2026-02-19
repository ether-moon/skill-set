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
4. [Equivalent Direct Commands](#equivalent-direct-commands)
5. [Workflow Integration](#workflow-integration)

## Prerequisites

- Git repository with GitHub remote
- `gh` CLI installed and authenticated
- Not on master/main branch
- Changes to include in PR (committed, uncommitted, or pushed)

## Steps

### 1. Validate Branch Status

```bash
# Check current branch - abort if on main/master
git branch --show-current
```

If the output is `main` or `master`, stop and inform user: "Cannot create PR from main/master branch."

```bash
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
gh pr list --head "$(git branch --show-current)" --json number,url --jq '.[0]'
```

If a PR already exists, output its URL and stop.

### 4. Analyze Commits and Changes

```bash
# Get commits since diverged from base branch
git log --oneline origin/master..HEAD

# Get change summary
git diff --stat origin/master..HEAD

# Get branch name to extract ticket number (e.g., FMT-1234, FLEASVR-287)
git branch --show-current
```

Parse the ticket number from the branch name output (e.g., `feature/FMT-1234-description` → `FMT-1234`).

### 5. Generate PR Title and Description

**Language:** Use language specified in project context, prompts, or documentation
- Check project docs, README, or existing PR patterns for language preference
- If unspecified, default to English

**Title format:**
```
[TICKET-123]: Feature summary
```

**If no ticket number:**
```
Feature summary
```

**Description format:**
```markdown
## Summary
- Summary of changes (bullet points)

## Changes
- Specific change details

## Test Plan
- [ ] Test item 1
- [ ] Test item 2
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
- Summary of changes

## Changes
- Specific change details

## Test Plan
- [ ] Test item 1
EOF
)" \
  --base master
```

**Important:** Use HEREDOC for PR body to handle multi-line content correctly.

The command automatically uses current branch as head.

### 7. Open in Browser

```bash
gh pr view --web
```

**Output to user:**
- PR URL
- PR title
- Success message

**Example output:**
```
✓ Pull request created: https://github.com/owner/repo/pull/123
  Title: FLEASVR-287: Install Github spec kit

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

## Equivalent Direct Commands

```bash
# Check if on main/master branch
git branch --show-current                # compare output with "main"/"master"

# Check if PR exists for current branch
gh pr list --head "$(git branch --show-current)" --json number --jq 'length'  # 0 = no PR

# Get PR URL
gh pr view --json url --jq .url

# Extract ticket from branch name
git branch --show-current                # parse ticket pattern (e.g., ABC-123) from output

# Open PR in browser
gh pr view --web
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

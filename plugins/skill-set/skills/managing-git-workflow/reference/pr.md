# Pull Request Workflow

Create a pull request with auto-generated title and description, automatically committing and pushing if needed. Self-contained — no delegation to other workflows.

## Prerequisites

- Git repository with GitHub remote
- `gh` CLI installed and authenticated
- Not on master/main branch
- Changes to include in PR (committed, uncommitted, or pushed)

## Call Summary

| Step | Type | Bash Calls |
|------|------|------------|
| 1. Gather git context | read (git) | 1 |
| 2. Check existing PR | read (gh) | 1 |
| 3. Commit and push (if needed) | write (git) | 0~1 |
| 4. Analyze PR scope | read (git) | 1 |
| 5. Generate PR content | analysis | 0 |
| 6. Create PR and open | write (gh) | 1 |
| **Total** | | **4~5** |

## Steps

### 1. Gather Git Context (1 Bash call)

Collect all needed git information in a single call:

```bash
git branch --show-current; git status --porcelain; git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "NO_UPSTREAM"; git log --oneline -10; git diff HEAD --stat; git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main"
```

**Parse the output into 6 sections:**
1. **Branch** (`git branch --show-current`): Current branch name — abort if `main` or `master`
2. **Status** (`git status --porcelain`): Uncommitted changes — empty means all committed
3. **Upstream** (`git rev-parse ...`): Tracking branch or `NO_UPSTREAM`
4. **Log** (`git log --oneline -10`): Recent commit patterns and style
5. **Diff stat** (`git diff HEAD --stat`): Summary of uncommitted changes
6. **Base branch** (`git symbolic-ref ...`): Default branch name (e.g., `main` or `master`). Use this as `BASE` in all subsequent steps.

**Exit if:** Branch is `main` or `master` → Inform user: "Cannot create PR from main/master branch."

**Extract ticket number** from branch name (match patterns like `FMT-1234`, `FLEASVR-287`, `ABC-123`).

### 2. Check Existing PR (1 Bash call)

```bash
gh pr list --head "BRANCH_NAME" --json number,url --jq '.[0]'
```

Replace `BRANCH_NAME` with the branch from step 1.

**Exit if:** PR already exists → Output its URL and stop.

### 3. Commit and Push if Needed (0~1 Bash call)

**Skip this step** if status from step 1 is empty AND upstream exists (already pushed).

If uncommitted changes exist, generate a commit message first:

**Commit message rules:**
- **Language:** Use language specified in project context, prompts, or documentation (default to English)
- **Style:** Follow patterns from the log output in step 1
- **Ticket numbers:** Include if extracted from branch name in step 1
- **Clarity:** Clearly describe what changed and why

Then execute the appropriate command:

**Uncommitted changes + no upstream:**
```bash
git add -A && git commit -m "$(cat <<'EOF'
Generated commit message
EOF
)" && git push -u origin "$(git branch --show-current)"
```

**Uncommitted changes + upstream exists:**
```bash
git add -A && git commit -m "$(cat <<'EOF'
Generated commit message
EOF
)" && git push
```

**All committed + no upstream:**
```bash
git push -u origin "$(git branch --show-current)"
```

**All committed + upstream exists:**
Skip — already pushed.

### 4. Analyze PR Scope (1 Bash call)

Get the full scope of changes for PR description:

```bash
git log --oneline origin/BASE..HEAD; git diff --stat origin/BASE..HEAD
```

Replace `BASE` with the base branch detected in step 1.

**Parse the output into 2 sections:**
1. **Commits**: All commits since diverging from base branch
2. **Change summary**: Files and lines changed

### 5. Generate PR Title and Description (no Bash call)

**Language:** Use language specified in project context, prompts, or documentation (default to English).

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

### 6. Create PR and Open in Browser (1 Bash call)

```bash
gh pr create --title "Generated title" --body "$(cat <<'EOF'
## Summary
- Summary of changes

## Changes
- Specific change details

## Test Plan
- [ ] Test item 1
EOF
)" --base BASE && gh pr view --web
```

**Important:** Use HEREDOC for PR body to handle multi-line content correctly.

**Output to user:**
- PR URL
- PR title
- Success message

**Example output:**
```
Pull request created: https://github.com/owner/repo/pull/123
  Title: FLEASVR-287: Install Github spec kit

Opening in browser...
```

## Common Issues

**Issue:** "Not in a git repository" or "No GitHub remote"
**Fix:** Verify repository setup. This workflow requires GitHub remote.

**Issue:** "gh: command not found"
**Fix:** Install GitHub CLI: `brew install gh` (macOS) and authenticate with `gh auth login`

**Issue:** "Pull request already exists"
**Fix:** Automatically detected in step 2. Outputs existing PR URL instead.

**Issue:** Can't determine appropriate PR description
**Fix:** Analyze more context with `git diff --name-only origin/BASE..HEAD` or `git diff origin/BASE..HEAD` (use the base branch detected in step 1).

**Issue:** Push rejected (diverged branches)
**Fix:** Run `git pull --rebase` then retry step 3.

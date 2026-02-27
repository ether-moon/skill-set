# Push Workflow

Push changes to remote repository, automatically committing if needed. Self-contained — no delegation to other workflows.

## Prerequisites

- Git repository with remote configured
- Changes to push (committed or uncommitted)

## Call Summary

| Step | Type | Bash Calls |
|------|------|------------|
| 1. Gather context | read | 1 |
| 2. Generate message (if needed) | analysis | 0 |
| 3. Commit and/or push | write | 1 |
| **Total** | | **2** |

## Steps

### 1. Gather Context (1 Bash call)

Collect all needed information in a single call:

```bash
git status --porcelain; git log --oneline -10; git diff HEAD --stat; git branch --show-current; git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "NO_UPSTREAM"
```

**Parse the output into 5 sections:**
1. **Status** (`git status --porcelain`): Uncommitted changes — empty means all committed
2. **Log** (`git log --oneline -10`): Recent commit patterns and style
3. **Diff stat** (`git diff HEAD --stat`): Summary of uncommitted changes
4. **Branch** (`git branch --show-current`): Current branch name for ticket extraction
5. **Upstream** (`git rev-parse ...`): Tracking branch or `NO_UPSTREAM`

**Exit if:** Status is empty AND branch is up to date with upstream → Output appropriate message in project's language and stop.

### 2. Generate Commit Message (no Bash call, only if uncommitted changes)

If status from step 1 is non-empty, generate a commit message:

**Rules:**
- **Language:** Use language specified in project context, prompts, or documentation (default to English)
- **Style:** Follow patterns from the log output in step 1
- **Ticket numbers:** Extract from branch name (match patterns like `FMT-1234`, `FLEASVR-287`, `ABC-123`)
- **Clarity:** Clearly describe what changed and why

### 3. Commit and/or Push (1 Bash call)

Choose the appropriate command based on state from step 1:

**Case A: Uncommitted changes + no upstream**
```bash
git add -A && git commit -m "$(cat <<'EOF'
Generated commit message
EOF
)" && git push -u origin "$(git branch --show-current)" && git log --oneline -1
```

**Case B: Uncommitted changes + upstream exists**
```bash
git add -A && git commit -m "$(cat <<'EOF'
Generated commit message
EOF
)" && git push && git log --oneline -1
```

**Case C: All committed + no upstream**
```bash
git push -u origin "$(git branch --show-current)"
```

**Case D: All committed + upstream exists**
```bash
git push
```

**Output to user:**
- Success message with branch name
- Commit details (if committed in this step)
- Push confirmation

**Example output:**
```
Pushed to origin/feature-branch
  Commit: a1b2c3d FMT-1234: Improve user authentication logic
  Branch is up to date with 'origin/feature-branch'
```

## Common Issues

**Issue:** "No upstream tracking branch"
**Fix:** Automatically handled with `-u` flag in Cases A and C.

**Issue:** Push rejected (diverged branches)
**Fix:**
```bash
git pull --rebase
```
Then retry the push step.

**Issue:** Authentication failed
**Fix:** User needs to configure git credentials or SSH keys. Not handled by this workflow.

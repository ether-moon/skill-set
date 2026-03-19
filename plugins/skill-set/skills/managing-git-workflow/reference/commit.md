# Commit Workflow

Create a commit with auto-generated message following project conventions and language preferences.

## Prerequisites

- Changes to commit (staged or unstaged)
- Access to git repository

## Call Summary

| Step | Type | Bash Calls |
|------|------|------------|
| 1. Gather context | read | 1 |
| 2. Generate message | analysis | 0 |
| 3. Commit | write | 1 |
| **Total** | | **2** |

## Steps

### 1. Gather Context (1 Bash call)

Collect all needed information in a single call:

```bash
git status --porcelain; git log --oneline -10; git diff HEAD --stat; git branch --show-current
```

**Parse the output into 4 sections:**
1. **Status** (`git status --porcelain`): File changes — empty means nothing to commit
2. **Log** (`git log --oneline -10`): Recent commit patterns and style
3. **Diff stat** (`git diff HEAD --stat`): Summary of what changed (works before staging)
4. **Branch** (`git branch --show-current`): Current branch name for ticket extraction

**Exit if:** Status section is empty → Output appropriate message in project's language and stop.

### 2. Generate Commit Message (no Bash call)

Using the gathered context, generate the commit message:

**Guidelines:**
- **Language:** Match the project's language. Check project docs, README, or existing commit message patterns for preference. Default to English if unclear.
- **Style:** Follow patterns from the log output in step 1 — consistency with existing commits matters more than any specific convention.
- **Ticket numbers:** Extract from branch name if present (match patterns like `PROJ-123`, `TEAM-456`).
  - Example: `feature/PROJ-123-add-auth` -> `PROJ-123`
- **Clarity:** Describe what changed and why.

**Message format examples:**
```
PROJ-123: Improve user authentication logic
TEAM-456: Add payment webhook handler
Fix: Resolve empty projectDir error
```

### 3. Stage and Commit (1 Bash call)

Chain staging, commit, and verification in a single call:

```bash
git add -A && git commit -m "$(cat <<'EOF'
Generated commit message
EOF
)" && git log --oneline -1
```

**Important:** Always use HEREDOC for messages with special characters or multi-line content.

**Output to user:**
- Commit hash (first 7 characters)
- Commit message
- Brief summary of changes

**Example output:**
```
Commit created: a1b2c3d PROJ-123: Improve user authentication logic
  3 files changed, 45 insertions(+), 12 deletions(-)
```

## Common Issues

**Issue:** "No changes to commit"
**Fix:** User may have already committed. Check status output from step 1.

**Issue:** Commit message contains quotes or special characters
**Fix:** Always use HEREDOC format shown in step 3.

**Issue:** Can't determine appropriate message style
**Fix:** Analyze more commits with `git log --oneline -20` or ask user for guidance.

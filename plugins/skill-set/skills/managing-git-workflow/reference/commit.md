# Commit Workflow

Create a commit with auto-generated message following project conventions and language preferences.

## Prerequisites

- Changes to commit (staged or unstaged)
- Access to git repository

## Steps

### 1. Check Current Status

```bash
git status
```

**Exit if:** No changes exist → Output appropriate message in project's language and stop

### 2. Stage Changes

```bash
git add -A
```

Stages all changes (new files, modifications, deletions).

### 3. Analyze Commit Patterns

Run these commands to understand project conventions:

```bash
# Recent commit messages
git log --oneline -10

# Changed files
git diff --cached --name-only

# Change summary
git diff --cached --stat
```

### 4. Generate Commit Message

**Rules:**
- **Language:** Use language specified in project context, prompts, or documentation
  - Check project docs, README, or existing commit patterns for language preference
  - If unspecified, default to English
- **Style:** Follow patterns from step 3
- **Ticket numbers:** Include if detected in branch name or changes
  - Examples: FMT-1234, FLEASVR-287, ABC-123
- **Clarity:** Clearly describe what changed and why

**Helper for ticket extraction:**
```bash
source .claude/skills/managing-git-workflow/git-helpers.sh
extract_ticket_from_branch
```

**Message format examples:**
```
FMT-1234: Improve user authentication logic
FLEASVR-287: Install Github spec kit
Fix bug: Resolve empty projectDir error
```

### 5. Create Commit

```bash
git commit -m "$(cat <<'EOF'
Generated commit message
EOF
)"
```

**Important:** Use HEREDOC for multi-line messages or messages with special characters.

### 6. Verify Success

```bash
git log --oneline -1
```

**Output to user:**
- Commit hash (first 7 characters)
- Commit message
- Brief summary of changes

**Example output:**
```
✓ Commit created: a1b2c3d FMT-1234: Improve user authentication logic
  3 files changed, 45 insertions(+), 12 deletions(-)
```

## Common Issues

**Issue:** "No changes to commit"
**Fix:** User may have already committed. Run `git status` to confirm.

**Issue:** Commit message contains quotes or special characters
**Fix:** Always use HEREDOC format shown in step 5.

**Issue:** Can't determine appropriate message style
**Fix:** Analyze more commits with `git log --oneline -20` or ask user for guidance.

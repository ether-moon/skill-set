# Commit Workflow

Create a commit with auto-generated Korean message following project conventions.

## Prerequisites

- Changes to commit (staged or unstaged)
- Access to git repository

## Steps

### 1. Check Current Status

```bash
git status
```

**Exit if:** No changes exist → Output "변경사항이 없습니다" and stop

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
- **Language:** Korean only
- **Style:** Follow patterns from step 3
- **Ticket numbers:** Include if detected in branch name or changes
  - Examples: FMT-1234, FLEASVR-287, ABC-123
- **Clarity:** Clearly describe what changed and why

**Helper for ticket extraction:**
```bash
source .claude/skills/managing-git-workflow/scripts/git-helpers.sh
extract_ticket_from_branch
```

**Message format examples:**
```
FMT-1234: 사용자 인증 로직 개선
FLEASVR-287: Github spec kit 설치
버그 수정: 빈 projectDir로 인한 오류 해결
```

### 5. Create Commit

```bash
git commit -m "$(cat <<'EOF'
생성된 커밋 메시지
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
✓ Commit created: a1b2c3d FMT-1234: 사용자 인증 로직 개선
  3 files changed, 45 insertions(+), 12 deletions(-)
```

## Common Issues

**Issue:** "No changes to commit"
**Fix:** User may have already committed. Run `git status` to confirm.

**Issue:** Commit message contains quotes or special characters
**Fix:** Always use HEREDOC format shown in step 5.

**Issue:** Can't determine appropriate message style
**Fix:** Analyze more commits with `git log --oneline -20` or ask user for guidance.

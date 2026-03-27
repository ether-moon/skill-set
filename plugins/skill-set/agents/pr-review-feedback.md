---
name: pr-review-feedback
description: "Processes PR review comments — classifies feedback as obvious or ambiguous using the autofixing-and-escalating skill, auto-fixes obvious items, discusses ambiguous items with rationale and recommendation. Called as a sub-agent from resolving-pr-blockers orchestrator."
---

# PR Review Feedback

## Overview

Interactive processing of PR review comments from any source (human reviewers, AI tools like CodeRabbit, Codex, Claude, or other bots): collect feedback, classify as obvious or ambiguous, auto-fix obvious items, discuss ambiguous items with recommendations, and complete workflow with verified git commits and PR comments.

**Core principle:** Classify by clarity, not severity. Obvious issues get fixed immediately; ambiguous ones get discussed with rationale and recommendations.

## When to Use

**Use when:**
- Reviewers (human or automated) have posted comments on your current PR
- You need to process review feedback with user input on ambiguous items
- You want obvious fixes applied automatically with a summary report

**Don't use when:**
- No PR exists or no review comments
- Uncommitted changes exist (must commit first)
- Fully automated processing without interaction is required

## Quick Reference

| Phase | Mode | Key Actions |
|-------|------|-------------|
| **Collection** | Auto | Pre-check → Discover PR → Collect comments → Filter |
| **Classification** | Auto | Classify each item as OBVIOUS or AMBIGUOUS |
| **Auto-fix** | Auto | Apply all OBVIOUS fixes → Report summary to user |
| **Discussion** | **Interactive** | Present AMBIGUOUS items (grouped by severity) → Get user decisions |
| **Completion** | Auto | Commit → Post PR summary → Verify |

## Autofix & Escalation Framework

This agent applies the `autofixing-and-escalating` skill to PR review comments.

**Before starting Phase 2 (Classification), read the skill:**
1. Find and read `autofixing-and-escalating/SKILL.md` from the plugin's skills directory
2. For edge cases, also read `autofixing-and-escalating/reference/classification.md`

**PR-specific terminology mapping:**
- "Source" = the reviewer who posted the comment (human or bot)
- "Item" = an unresolved review comment or thread
- "Location" = file path + line number from the PR diff

**PR-specific adaptations:**
- Include reviewer name and bot/human status with each classified item
- If auto-fix of an OBVIOUS item fails, move to AMBIGUOUS with explanation
- Resolution report includes `(reviewer: @name)` attribution
- Bot resolution: if items came from CodeRabbit, prepend `@coderabbitai resolve` to PR comment

## Language Detection

**IMPORTANT: Detect and use user's preferred language for all communication.**

**Detection priority (check in order):**
1. **User's current messages** - What language is the user speaking in this conversation?
2. **Project context** - Check CLAUDE.md, README.md, recent commits for language patterns
3. **Git history** - `git log --oneline -5` to see commit message language
4. **Default** - If no clear indication, use **English**

**Apply detected language to:**
- All conversational messages with user
- PR comment content
- Reports and summaries
- Error messages and warnings

**Always keep in English:**
- Code examples
- Bash commands and scripts
- File paths
- Technical API calls

## Mandatory Workflow Tracking

**IMMEDIATELY after discovering the PR, before collecting comments, create these tasks:**

```
TaskCreate: "Collect and classify PR review comments"
TaskCreate: "Auto-fix obvious items"
TaskCreate: "Report obvious fixes and discuss ambiguous items"
TaskCreate: "Apply agreed changes"
TaskCreate: "Commit changes"
TaskCreate: "Post PR summary comment"
TaskCreate: "Verify PR comment posted"
```

**Rules:**
- Create ALL tasks before starting comment collection
- Set each task to `in_progress` when starting it, `completed` when done
- Before reporting completion to the user, run `TaskList` and confirm zero pending tasks
- Never skip a task. If a task has nothing to do (e.g., no OBVIOUS items), mark it completed with a note explaining why.

### Phase 1: Collection

1. **Discover PR**: Find current PR from branch
   ```bash
   BRANCH=$(git branch --show-current)
   gh pr list --head "$BRANCH" --json number,title,url
   ```

2. **Collect Comments with Pagination** (up to 200 comments):

   **Important:** Collect ALL comment sources — PR-level comments, review bodies, and inline review threads. Human reviewers typically leave inline code comments via review threads, not PR-level comments.

   **Method 1: GraphQL (Recommended)**
   ```bash
   get_all_comments() {
     local pr_number=$1
     local owner=$2
     local repo=$3

     local query='query($owner:String!, $repo:String!, $number:Int!) {
       repository(owner:$owner, name:$repo) {
         pullRequest(number:$number) {
           comments(first:100) {
             nodes {
               id author { login } body createdAt
               replies(first:10) { nodes { author { login } body createdAt } }
             }
           }
           reviewThreads(first:100) {
             nodes {
               isResolved
               comments(first:10) {
                 nodes {
                   author { login } body createdAt
                   path line
                 }
               }
             }
           }
         }
       }
     }'

     gh api graphql -f query="$query" \
       -F owner="$owner" -F repo="$repo" -F number="$pr_number"
   }
   ```

   The query returns both PR-level `comments` and inline `reviewThreads`. Filter out threads where `isResolved: true`. For large PRs with 100+ comments, add pagination cursors to both fields.

   **Method 2: REST API (Alternative)**
   ```bash
   get_all_comments_rest() {
     local pr_number=$1
     local owner=$2
     local repo=$3

     # PR-level comments
     gh api "repos/$owner/$repo/issues/$pr_number/comments?per_page=100"

     # Inline review comments (different endpoint)
     gh api "repos/$owner/$repo/pulls/$pr_number/comments?per_page=100"
   }
   ```

   Merge results from both endpoints. For 100+ comments, paginate with `&page=2`.

3. **Filter**: Process unresolved review comments
   - Collect ALL review comments (do not filter by author)
   - Group comments by reviewer for context (track which reviewer said what)
   - Note which reviewers are bots (e.g., `coderabbitai[bot]`, `github-actions[bot]`) for the verification phase
   - Exclude bodies with resolution markers: "resolved", "fixed", "applied", checkmarks
   - Check entire thread (including replies) for resolution indicators
   - If a thread contains a bot-specific resolution command (e.g., `@coderabbitai resolve`), treat it as resolved
   - Sort by recency (newest first)

### Phase 2: Classification

Apply the `autofixing-and-escalating` skill to classify each actionable comment.

For each comment, extract:
- File path, line number, and specific change requested
- Reviewer name and whether they are a bot

Then classify per the skill's criteria:
1. **Primary**: Apply the OBVIOUS criteria (all four must be met) → OBVIOUS or AMBIGUOUS
2. **Secondary** (AMBIGUOUS only): Assign severity (CRITICAL > MAJOR > MINOR)
3. **Safety check**: Apply the "ALWAYS AMBIGUOUS" rules to catch misclassifications

Skip summaries without actionable items (e.g., "LGTM", general praise).

### Phase 3: Auto-fix and Report

Follow the resolution workflow in `autofixing-and-escalating/reference/resolution.md`:
- Auto-fix all OBVIOUS items using subagents (grouped by file), moving failures to AMBIGUOUS
- Report every auto-applied fix to the user with reviewer attribution — never skip the report

### Phase 4: Discuss and Apply

Continue the resolution workflow:
- Present AMBIGUOUS items grouped by severity with "why ambiguous" + recommendation + reviewer attribution
- Offer choices: [1] Apply all recommended, [2] Review individually, [3] Skip all
- Show final summary and apply only after explicit user confirmation

### Phase 5: Completion

**Step 5.1 — Commit:**
Stage all modified files and create a commit with a descriptive message summarizing what was addressed. Do NOT push — the orchestrator handles the final push.

**Step 5.2 — Post PR Summary Comment:**
Generate a PR comment summarizing all actions taken:
- **Auto-applied** (OBVIOUS): list with file paths
- **Applied after discussion** (AMBIGUOUS): list with file paths
- **Skipped**: list with brief rationale
- **Statistics**: total reviewed, auto-applied, discussed & applied, skipped

**Bot resolution detection:** If any collected comments were authored by `coderabbitai[bot]` or similar CodeRabbit accounts, prepend `@coderabbitai resolve` to the PR comment. Do NOT include this tag if CodeRabbit was not among the reviewers.

Post the comment:
```bash
gh pr comment "$PR_NUMBER" --body "$COMMENT_BODY"
```

**Step 5.3 — Verify:**
```bash
# Wait for API sync
sleep 2
# Confirm comment exists
LAST_COMMENT=$(gh pr view "$PR_NUMBER" --json comments --jq '.comments[-1].body')
echo "$LAST_COMMENT" | head -5
```

If CodeRabbit resolution tag was included, verify it is present in the posted comment.

Mark all remaining tasks as completed. Run `TaskList` to confirm zero pending tasks.

## Common Mistakes

### Skipping Pagination
**Problem:** Missing comments when PR has 100+ comments
**Fix:** Use GraphQL/REST pagination to collect up to 200 comments

### Ignoring Reviewer Context
**Problem:** Treating human and bot comments identically without noting who said what
**Fix:** Group comments by reviewer, note if reviewer is human or bot — human comments may need different discussion approach

## Success Criteria

- All tasks created at workflow start
- All unresolved comments collected (up to 200 with pagination)
- Each item classified as OBVIOUS or AMBIGUOUS (with severity for AMBIGUOUS)
- All OBVIOUS items auto-applied and reported to user before discussion
- AMBIGUOUS items presented with "why ambiguous" + recommendation + rationale
- Only user-approved AMBIGUOUS changes applied
- Changes committed (orchestrator handles push)
- PR comment posted (with `@coderabbitai resolve` if CodeRabbit was a reviewer)
- All tasks show `completed` in TaskList

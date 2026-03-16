---
name: pr-review-feedback
description: Use when a PR has review comments from any source (human reviewers, CodeRabbit, Codex, Claude, other bots) - interactively classify feedback by severity, discuss recommendations with user, apply agreed changes, and ensure mandatory commit and PR comment workflow with verification
---

# PR Review Feedback

## Overview

Interactive processing of PR review comments from any source (human reviewers, AI tools like CodeRabbit, Codex, Claude, or other bots): collect and classify feedback, discuss CRITICAL/MAJOR items for immediate action, analyze MINOR items with recommendations, and complete workflow with verified git commits and PR comments.

**Core principle:** Interactive severity-based workflow with user conversation (collect → discuss → apply together → verify completion).

## When to Use

**Use when:**
- Reviewers (human or automated) have posted comments on your current PR
- You need to process review feedback with user input
- You want to discuss which suggestions to apply
- You need guided review with recommendations and rationale

**Don't use when:**
- No PR exists or no review comments
- Uncommitted changes exist (must commit first)
- Fully automated processing without interaction is required

## Quick Reference

| Phase | Mode | Key Actions |
|-------|------|-------------|
| **Collection** | Auto | Pre-check → Discover PR → Collect comments → Filter & Classify |
| **Discussion** | **Interactive** | Present items → Get user decisions → Analyze MINOR with rationale |
| **Application** | Auto | Apply agreed changes → Commit & Push |
| **Verification** | Auto | Post PR summary comment → Verify posted |

## Severity Classification

### CRITICAL (Immediate Discussion Required)
- **Security**: SQL injection, XSS, CSRF, auth bypass, sensitive data exposure
- **Data Loss**: Destructive operations, cascade deletes, corruption risks
- **Breaking Bugs**: Nil pointer errors, type crashes, unhandled exceptions
- **Critical Logic**: Payment errors, authorization failures, data integrity violations

### MAJOR (Important Discussion)
- **Performance**: N+1 queries, memory leaks, slow algorithms, missing indexes
- **Resource Issues**: File handle leaks, connection pool exhaustion, unbounded loops
- **Significant Bugs**: Wrong calculations, incorrect validations, race conditions
- **Production Impact**: High error rates, significant user impact, reliability issues

### MINOR (Analyze & Recommend)
- **Code Quality**: Variable naming, method extraction, DRY violations
- **Style**: Formatting preferences, comment style, code organization
- **Documentation**: Missing comments, outdated docs, unclear naming
- **Speculative**: "Could be", "might consider", optional improvements

### ALWAYS SKIP (Never Process)
- Comments with resolution markers: checkmarks or "resolved", "fixed", "applied"
- Threads already resolved (including `@coderabbitai resolve` or similar bot resolution commands)
- Developer confirmation replies: "Applied", "Done", "Fixed"
- Duplicate suggestions (process once only)

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
- Status updates

**Always keep in English:**
- Code examples
- Bash commands and scripts
- File paths
- Technical API calls

## Mandatory Workflow Tracking

**IMMEDIATELY after discovering the PR, before collecting comments, create these tasks:**

```
TaskCreate: "Collect and classify PR review comments"
TaskCreate: "Discuss feedback with user"
TaskCreate: "Apply agreed changes"
TaskCreate: "Commit and push changes"
TaskCreate: "Post PR summary comment"
TaskCreate: "Verify PR comment posted"
```

**Rules:**
- Create ALL tasks before starting comment collection
- Set each task to `in_progress` when starting it, `completed` when done
- Before reporting completion to the user, run `TaskList` and confirm zero pending tasks
- Never skip a task. If a task cannot be completed, explain why to the user instead of silently moving on.

### Phase 1: Collection

1. **Discover PR**: Find current PR from branch
   ```bash
   BRANCH=$(git branch --show-current)
   gh pr list --head "$BRANCH" --json number,title,url
   ```

2. **Collect Comments with Pagination** (up to 200 comments):

   **Important:** Collect BOTH PR-level comments (`pullRequest.comments`) AND inline review threads (`pullRequest.reviews`, `pullRequest.reviewThreads`). Human reviewers typically leave inline code comments via review threads, not PR-level comments.

   **Method 1: GraphQL with Pagination (Recommended)**
   ```bash
   get_all_comments() {
     local pr_number=$1
     local owner=$2
     local repo=$3
     local cursor=""
     local has_next=true
     local all_comments="[]"

     while [ "$has_next" = "true" ]; do
       local query='query($owner:String!, $repo:String!, $number:Int!, $cursor:String) {
         repository(owner:$owner, name:$repo) {
           pullRequest(number:$number) {
             comments(first:100, after:$cursor) {
               pageInfo { hasNextPage endCursor }
               nodes {
                 id
                 author { login }
                 body
                 createdAt
                 replies(first:10) {
                   nodes { author { login } body createdAt }
                 }
               }
             }
           }
         }
       }'

       local result=$(gh api graphql -f query="$query" \
         -F owner="$owner" -F repo="$repo" -F number="$pr_number" \
         ${cursor:+-F cursor="$cursor"})

       local page_comments=$(echo "$result" | jq '.data.repository.pullRequest.comments.nodes')
       all_comments=$(echo "$all_comments" | jq ". + $page_comments")

       has_next=$(echo "$result" | jq -r '.data.repository.pullRequest.comments.pageInfo.hasNextPage')
       cursor=$(echo "$result" | jq -r '.data.repository.pullRequest.comments.pageInfo.endCursor')

       [ "$has_next" = "false" ] && break
       [ $(echo "$all_comments" | jq 'length') -ge 200 ] && break
     done

     echo "$all_comments" | jq 'sort_by(.createdAt) | reverse | .[:200]'
   }
   ```

   **Method 2: REST API with Pagination (Alternative)**
   ```bash
   get_all_comments_rest() {
     local pr_number=$1
     local page=1
     local per_page=100
     local all_comments="[]"

     while [ $page -le 2 ]; do  # Max 2 pages = 200 comments
       local result=$(gh api "repos/$OWNER/$REPO/issues/$pr_number/comments?per_page=$per_page&page=$page")

       [ "$(echo "$result" | jq 'length')" -eq 0 ] && break

       all_comments=$(echo "$all_comments" | jq ". + $result")
       ((page++))
     done

     echo "$all_comments" | jq 'sort_by(.created_at) | reverse | .[:200]'
   }
   ```

3. **Filter**: Process unresolved review comments
   - Collect ALL review comments (do not filter by author)
   - Group comments by reviewer for context (track which reviewer said what)
   - Note which reviewers are bots (e.g., `coderabbitai[bot]`, `github-actions[bot]`) for the verification phase
   - Exclude bodies with resolution markers: "resolved", "fixed", "applied", checkmarks
   - Check entire thread (including replies) for resolution indicators
   - If a thread contains a bot-specific resolution command (e.g., `@coderabbitai resolve`), treat it as resolved
   - Sort by recency (newest first)

4. **Classify**: Assign severity to each actionable item
   - Extract file path, line number, and specific change
   - Match against severity criteria (CRITICAL > MAJOR > MINOR)
   - Skip summaries without actionable items (e.g., "LGTM", general praise)

### Phase 2: Interactive Discussion

**Step 2.1 - Present Summary and CRITICAL/MAJOR Items:**
Show the user a summary with counts per severity and reviewer breakdown, then list each CRITICAL and MAJOR item with:
- File path and line number
- One-line issue description
- Suggested fix
- Risk/impact assessment
- Who raised it (reviewer name)

Offer choices: [1] Apply all, [2] Review individually, [3] See details first, [4] Start with MINOR analysis

**Step 2.2 - Individual Review (if selected):**
Walk through each item one at a time. For each, show current code, suggested change, and analysis. Ask: Apply? [Y/n/skip]

**Step 2.3 - MINOR Analysis & Recommendations:**
After CRITICAL/MAJOR decisions are made, analyze all MINOR items and classify each as:
- **Recommended to apply**: Clear improvement, low risk — include rationale
- **Optional**: Trade-offs exist, user should decide based on project context
- **Not recommended**: Adds unnecessary complexity or dependencies — include rationale

Present summary with apply options.

**Step 2.4 - Final Confirmation:**
Before applying, show a complete summary of what will be applied, what was skipped, and why. Get explicit user confirmation.

### Phase 3: Application & Completion

**Step 3.1 - Apply Changes:**
Apply each user-approved change in sequence. Report progress as each item completes.

**Step 3.2 - Commit & Push:**
Stage all modified files, create a commit with a descriptive message summarizing what was addressed (group by severity), and push to the remote branch.

**Step 3.3 - Post PR Summary Comment:**
Generate a PR comment summarizing all actions taken:
- Items applied (grouped by CRITICAL/MAJOR/MINOR with file paths)
- Items skipped with brief rationale
- Statistics (total reviewed, applied, deferred, skipped)

**Bot resolution detection:** If any collected comments were authored by `coderabbitai[bot]` or similar CodeRabbit accounts, prepend `@coderabbitai resolve` to the PR comment. Do NOT include this tag if CodeRabbit was not among the reviewers.

Post the comment:
```bash
gh pr comment "$PR_NUMBER" --body "$COMMENT_BODY"
```

**Step 3.4 - Verify:**
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

### Not Providing Rationale
**Problem:** User doesn't understand why suggestions are categorized
**Fix:** Include 1-2 line rationale for each MINOR item classification

### Auto-Applying Without Discussion
**Problem:** Applying changes user didn't explicitly approve
**Fix:** Present summary, get user decision, then apply only agreed items

### Incomplete Error Recovery
**Problem:** Stopping workflow when single item fails
**Fix:** Skip failed item with explanation, continue with others, complete remaining tasks

### Ignoring Reviewer Context
**Problem:** Treating human and bot comments identically without noting who said what
**Fix:** Group comments by reviewer, note if reviewer is human or bot — human comments may need different discussion approach

## Success Criteria

- All tasks created at Phase 1 start
- All unresolved comments collected (up to 200 with pagination)
- Each item classified by severity (CRITICAL/MAJOR/MINOR)
- CRITICAL/MAJOR items discussed with user
- MINOR items analyzed with clear rationale
- Only user-approved changes applied
- Changes committed and pushed
- PR comment posted (with `@coderabbitai resolve` if CodeRabbit was a reviewer)
- All tasks show `completed` in TaskList

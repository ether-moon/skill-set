---
name: pr-review-feedback
description: Use when a PR has review comments from any source (human reviewers, CodeRabbit, Codex, Claude, other bots) - classifies feedback as obvious or ambiguous, auto-fixes obvious items, discusses ambiguous items with rationale and recommendation, and ensures mandatory commit and PR comment workflow with verification
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
| **Completion** | Auto | Commit & Push → Post PR summary → Verify |

## Primary Classification: OBVIOUS vs AMBIGUOUS

The primary axis is **clarity of correctness**, not severity.

### OBVIOUS (Auto-fix)

Items where the reviewer explicitly identified a specific issue AND the fix is objectively correct with no room for reasonable disagreement.

**All four criteria must be met:**
1. The reviewer explicitly identified a specific issue (not a general suggestion)
2. The issue is objectively verifiable (not opinion-based)
3. There is exactly one correct way to fix it (no design choices involved)
4. No reasonable developer would disagree with the fix

**Examples:**
- Typos in variable names, comments, or docs that the reviewer pointed out
- Missing null/nil checks that will provably crash
- Textbook security flaws (SQL injection, XSS) with a clear fix
- Off-by-one errors that are provably wrong
- Unused imports/variables the reviewer identified
- Wrong API usage per official documentation
- Syntax errors or broken references

### AMBIGUOUS (Discuss with user)

Items where there is room for interpretation, trade-offs, or legitimate disagreement.

**Examples:**
- "Consider using X pattern instead of Y" — architectural preference
- "This could be more performant with..." — trade-off involved
- "Maybe extract this into a separate function" — design choice
- Style preferences not enforced by linter
- Suggestions requiring significant refactoring
- Performance optimizations with readability trade-offs
- Alternative approaches where both are valid
- Changes affecting public API surface
- Suggestions involving new dependencies

### ALWAYS AMBIGUOUS (Never auto-fix)

Classify as AMBIGUOUS regardless of apparent clarity:
- Reviewer used hedging language: "might", "could", "consider", "maybe", "what about"
- Fix requires changing more than ~10 lines
- Fix has multiple valid approaches
- Involves architectural or design decisions
- Affects public API or external contracts

### Safety Rule

**When in doubt, classify as AMBIGUOUS.** It is always better to discuss than to silently apply a wrong fix.

### ALWAYS SKIP (Never Process)
- Comments with resolution markers: checkmarks or "resolved", "fixed", "applied"
- Threads already resolved (including `@coderabbitai resolve` or similar bot resolution commands)
- Developer confirmation replies: "Applied", "Done", "Fixed"
- Duplicate suggestions (process once only)

## Secondary Classification: Severity (AMBIGUOUS items only)

Within AMBIGUOUS items, assign severity for grouping and sort order:

### CRITICAL
- Security: auth bypass, sensitive data exposure, injection vulnerabilities
- Data Loss: destructive operations, corruption risks
- Breaking Bugs: nil pointer errors, type crashes, unhandled exceptions

### MAJOR
- Performance: N+1 queries, memory leaks, missing indexes
- Significant Bugs: wrong calculations, race conditions
- Resource Issues: file handle leaks, connection pool exhaustion

### MINOR
- Code Quality: naming, method extraction, DRY violations
- Style: formatting, code organization
- Documentation: missing comments, unclear naming
- Speculative: optional improvements

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
TaskCreate: "Commit and push changes"
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

For each actionable comment, extract:
- File path, line number, and specific change requested
- Reviewer name and whether they are a bot

Then classify:
1. **Primary**: Apply the OBVIOUS criteria (all four must be met) → OBVIOUS or AMBIGUOUS
2. **Secondary** (AMBIGUOUS only): Assign severity (CRITICAL > MAJOR > MINOR)
3. **Safety check**: Apply the "ALWAYS AMBIGUOUS" rules to catch misclassifications

Skip summaries without actionable items (e.g., "LGTM", general praise).

### Phase 3: Auto-fix Obvious Items

Apply all OBVIOUS items immediately without user interaction.

- Apply each fix in sequence
- If any fix fails, move it to AMBIGUOUS with an explanation of why auto-fix failed
- Track what was applied for the summary report

### Phase 4: Report & Discuss

**Step 4.1 — Report Obvious Fixes:**

Present a summary of what was auto-applied:

> Applied N obvious fixes:
> - `path/to/file.ts:42` — Fixed null check (reviewer: @alice)
> - `path/to/file.ts:87` — Removed unused import (reviewer: @coderabbitai)
> - ...

If no OBVIOUS items existed, skip this and proceed to Step 4.2.

**Step 4.2 — Present Ambiguous Items:**

Present AMBIGUOUS items grouped by severity (CRITICAL → MAJOR → MINOR). For each item show:
- File path and line number
- One-line issue description
- **Why it's ambiguous**: What makes this debatable or uncertain
- **Recommendation**: Agent's suggested action with rationale
- Who raised it (reviewer name)

Example format:

> ### CRITICAL (1 item)
>
> **1. Race condition in user update** — `src/api/users.ts:134` (reviewer: @bob)
> - Issue: Concurrent updates may overwrite each other
> - Why ambiguous: Fix requires choosing between optimistic locking, pessimistic locking, or retry logic — each has different trade-offs
> - Recommendation: Apply optimistic locking — it's the least invasive change and matches the existing pattern in `orders.ts`
>
> ### MINOR (2 items)
>
> **2. Extract validation logic** — `src/api/users.ts:45` (reviewer: @coderabbitai)
> - Issue: Validation logic is inline, could be a separate function
> - Why ambiguous: Current code is only 8 lines and used once — extraction adds indirection without clear benefit yet
> - Recommendation: Skip — extract when a second caller appears
>
> ...

Offer choices: [1] Apply all recommended, [2] Review individually, [3] Skip all

**Step 4.3 — Individual Review (if selected):**
Walk through each item one at a time. For each, show current code, suggested change, and analysis. Ask: Apply? [Y/n/skip]

**Step 4.4 — Final Confirmation:**
Before applying, show a complete summary of what will be applied and what was skipped. Get explicit user confirmation.

### Phase 5: Application & Completion

**Step 5.1 — Apply Changes:**
Apply each user-approved AMBIGUOUS change in sequence. Report progress as each item completes.

**Step 5.2 — Commit & Push:**
Stage all modified files, create a commit with a descriptive message summarizing what was addressed, and push to the remote branch.

**Step 5.3 — Post PR Summary Comment:**
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

**Step 5.4 — Verify:**
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

### Classifying Ambiguous Items as Obvious
**Problem:** Auto-applying a fix that had trade-offs the user should have weighed
**Fix:** Apply the four OBVIOUS criteria strictly. When in doubt, classify as AMBIGUOUS.

### Skipping Pagination
**Problem:** Missing comments when PR has 100+ comments
**Fix:** Use GraphQL/REST pagination to collect up to 200 comments

### Not Explaining Why Something Is Ambiguous
**Problem:** User sees an ambiguous item but doesn't understand what makes it debatable
**Fix:** Always include "Why ambiguous" with each item — what's the trade-off or uncertainty?

### Auto-Applying Without Reporting
**Problem:** User doesn't know what was changed on their behalf
**Fix:** Always present the obvious-fix summary before moving to ambiguous discussion

### Incomplete Error Recovery
**Problem:** Stopping workflow when single item fails
**Fix:** If an OBVIOUS fix fails, move it to AMBIGUOUS with explanation. Continue with remaining items.

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
- Changes committed and pushed
- PR comment posted (with `@coderabbitai resolve` if CodeRabbit was a reviewer)
- All tasks show `completed` in TaskList

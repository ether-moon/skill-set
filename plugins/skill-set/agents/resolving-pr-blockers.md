---
name: resolving-pr-blockers
description: Resolves all PR blockers — CI failures, merge conflicts, and review feedback. Scans the current branch's PR, detects blockers, dispatches specialized sub-agents, and pushes once all are resolved. Use when user says "fix my PR", "CI failed", "resolve conflicts", "fix the build", "handle review comments", "PR won't merge".
---

# Resolving PR Blockers

## Overview

Orchestrator agent that scans the current branch's PR for blockers and dispatches specialized sub-agents to resolve them. Handles merge conflicts, CI failures, and review comments.

Core principle: detect merge conflicts and CI failures upfront, always dispatch pr-review-feedback for comment handling, maintain correct dependency ordering, commit per sub-agent, push once at the end.

## When to Use

- Current branch has an open PR with failing checks, merge conflicts, or unresolved review comments
- User wants all PR blockers resolved in one pass

Don't use when:
- No PR exists for the current branch
- No blockers detected (all checks passing, no conflicts, no unresolved comments)

## Language Detection

Detect and use the user's preferred language for all communication.

Detection priority:
1. User's current messages
2. Project context (CLAUDE.md, README.md)
3. Git history (git log --oneline -5)
4. Default to English

Apply detected language to: conversational messages, reports, summaries.
Always keep in English: code examples, commands, file paths.

## Workflow

### Phase 1: PR Discovery & Blocker Scan

```bash
# 1. Find the PR for the current branch
BRANCH=$(git branch --show-current)
PR_JSON=$(gh pr list --state open --head "$BRANCH" --json number,title,url,headRefName)
PR_NUMBER=$(echo "$PR_JSON" | jq -r '.[0].number')

# Extract repo owner and name
OWNER=$(gh repo view --json owner -q '.owner.login')
REPO=$(gh repo view --json name -q '.name')
```

If no PR found, report to user and exit.

```bash
# 2. Scan merge conflicts and CI status:

# Merge conflict status and target branch
gh pr view "$PR_NUMBER" --json mergeable,mergeStateStatus,baseRefName

# CI check status
gh pr checks "$PR_NUMBER" --json name,state,link,workflow
```

Categorize findings:
- **Merge conflicts**: `mergeable` is `CONFLICTING` or `mergeStateStatus` is `DIRTY`. If `mergeable` is `UNKNOWN`, wait 3 seconds and re-query — GitHub computes this lazily.
- **CI failures**: Any check with `state` = `FAILURE`

**Review comments**: Do NOT scan for review comments here. Always dispatch `pr-review-feedback` — it handles its own comment discovery, filtering, and early exit if none exist.

If no merge conflicts AND no CI failures, still dispatch pr-review-feedback (it may find unresolved comments). If pr-review-feedback also finds nothing, report "All clear — PR is ready to merge" and exit.

### Phase 2: Sub-agent Dispatch

Create tasks for tracking:
```
TaskCreate: "Scan PR for blockers"
TaskCreate: "Resolve merge conflicts" (if detected)
TaskCreate: "Fix CI failures" (if detected)
TaskCreate: "Process review comments"
TaskCreate: "Push changes and finalize"
```

**Dispatch rules with dependency management:**

```
Dependency chain:
  merge-conflict-resolver → ci-failure-resolver (sequential)
  pr-review-feedback (parallel with above chain)
```

1. **If merge conflicts detected**: Launch `merge-conflict-resolver` sub-agent immediately
   - Wait for completion before launching ci-failure-resolver
   - Pass PR number and target branch info

2. **If CI failures detected**: Launch `ci-failure-resolver` sub-agent
   - If merge conflicts existed: launch only AFTER merge-conflict-resolver completes
   - If no merge conflicts: launch immediately
   - Pass PR number and failed run IDs

3. **Always**: Launch `pr-review-feedback` sub-agent
   - Launch immediately, in parallel with the conflict→CI chain
   - The sub-agent handles its own comment discovery and exits early if none exist
   - Pass PR number

**Sub-agent dispatch format:**
Use the `Agent` tool to launch each sub-agent. In the prompt, instruct the sub-agent to read its agent file from the plugin's `agents/` directory and follow its instructions. Provide:
- The path to the agent file (e.g., `agents/merge-conflict-resolver.md`)
- PR number
- Repository owner and name
- Branch name
- Specific blocker details (e.g., failed run IDs for CI, target branch for conflicts)

### Phase 3: Completion

After ALL sub-agents have completed:

1. **Push once**:
   ```bash
   git push
   ```

2. **PR summary comment** — only if pr-review-feedback sub-agent was dispatched:
   The pr-review-feedback sub-agent handles its own PR comment posting. No additional comment needed for merge conflict or CI failure resolution — commit messages are sufficient.

3. **Report to user**: Summarize what was resolved across all sub-agents.

Mark all tasks as completed. Run TaskList to confirm zero pending tasks.

## Error Handling

- If a sub-agent fails or cannot resolve its blockers, report the failure and continue with other sub-agents
- If merge-conflict-resolver fails, still attempt ci-failure-resolver (CI may have independent failures)
- Never leave the workflow in a partial state — always push whatever was successfully resolved
- If no changes were made by any sub-agent, skip the push
- After push, CI will re-run remotely. If the user reports new failures, re-run this workflow

## Common Mistakes

### Not Checking for PR First
**Problem:** Attempting to scan blockers when no PR exists.
**Fix:** Always verify PR existence before scanning. Exit early with a clear message.

### Dispatching CI Resolver Before Conflicts Are Resolved
**Problem:** CI failures may be caused by merge conflicts, making fixes invalid.
**Fix:** Always resolve merge conflicts first, then address CI failures.

### Pushing Multiple Times
**Problem:** Each sub-agent pushes independently, triggering unnecessary CI runs.
**Fix:** Sub-agents only commit. Orchestrator pushes once at the end.

## Success Criteria

- PR discovered and all blocker types scanned
- Sub-agents dispatched with correct dependency ordering
- Each sub-agent commits its own changes with descriptive messages
- Single push after all sub-agents complete
- PR summary comment posted (only for review feedback)
- All tasks show completed in TaskList

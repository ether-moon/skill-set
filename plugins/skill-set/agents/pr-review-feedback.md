---
name: pr-review-feedback
description: Processes unresolved actionable PR review threads on the current HEAD in the recorded current PR worktree. Returns queued publication content; never switches branches, pushes, comments, or resolves threads itself.
tools: ["Read", "Grep", "Glob", "Bash", "Edit", "Write"]
---

# PR Review Feedback

## Input Contract

Require repository, PR number, current remote HEAD SHA, recorded current worktree/branch, `workspace_mode=current`, and `resolve-authorized` capabilities with `edit=true`, `commit=true`, `push=false`, and `comment=false`.

Run only when the recorded resolver plan includes review. If that plan also includes CI, require the CI resolver to have succeeded or no-oped and verify its local HEAD; a review-only plan starts directly from the supplied PR HEAD. In both cases, verify the worktree remains based on that pinned HEAD.

## Collect Current Review State

Use GraphQL `reviewThreads(first:100, after:$cursor)` with `pageInfo.hasNextPage` and `endCursor` until every page is collected. Keep unresolved, non-outdated threads with a non-empty actionable comment. Preserve thread ID, path, line, author, body, and current-HEAD context.

Do not infer resolution from words such as "fixed" in an unrelated comment. Do not truncate at 100 threads. PR-level discussion may provide context, but only an actionable unresolved review thread is a code blocker.

Preserve each thread's actual author/app identity. Do not select or return a provider adapter; the publication runner derives CodeRabbit, Claude/Anthropic, `chatgpt-codex-connector`/Codex, or `other` from that saved evidence. Provider identity never changes classification.

## Classify and Resolve

1. Read `autofixing-and-escalating/SKILL.md` and pass the capability contract.
2. Apply the runner's narrow whole-message acknowledgement rule before classification: normalize ASCII case/punctuation/whitespace and skip only exact praise/summary labels (`lgtm`, `looks good`, `looks good to me`, `great work`, `great job`, `nice work`, `well done`, `thanks`, `thank you`, `approved`, `all good`, `ship it`, `summary`, `review summary`, `code review summary`, `walkthrough`) or a body consisting only of `👍`, `✅`, or `🎉`. A praise phrase plus a request remains actionable. Also skip requests made obsolete by the current diff.
3. Classify each actionable request. Public API, data/schema, dependency, security-policy, destructive, architectural, and multiple-solution requests are always AMBIGUOUS.
4. Apply only OBVIOUS items in the shared resolver worktree, preserving prior CI edits.
5. Resolve `skills/managing-git-workflow/scripts/skill-set-git` from the installed skill collection, run focused validation, inspect the index, and commit only explicit modified paths through that absolute runner path with `commit --path <path> --expected-index <fingerprint> --message-file <file>`.
6. On AMBIGUOUS, return the decision with rationale and recommendation. Do not publish partial work.

## Queue, Do Not Publish

Return a summary body whenever review activity was processed, including auto-applied, user-approved, skipped, and no-op items. Also return one resolution-feedback entry for every blocked-snapshot thread: its exact thread ID, outcome (`fixed`, `accepted_as_is`, or `unresolved`), and a concise body explaining what was done or why it remains open. Do not include a provider/adapter field; the runner derives it from the saved thread author. Do not include `@codex`, `@claude`, `@coderabbitai`, review triggers, or edit-delegation commands in either payload.

Do not post or resolve anything. The orchestrator writes the summary and `{threads:[...]}` feedback files, then lets `skill-set-pr publish` reply and resolve only after the publication gate. The runner derives CodeRabbit's exact resolve command only when every queued CodeRabbit item is resolved; Codex and Claude receive resolution feedback, never a new-review command.

The orchestrator may publish this payload only after every attempted resolver succeeds/no-ops and the expected-SHA push succeeds. For a review-only no-op, it must re-verify the unchanged remote HEAD first.

## Result Contract

Return `success`, `no-op`, `AMBIGUOUS`, or `failed`, `input_head`, `output_head`, commits, modified paths, validation results, processed thread IDs, queued summary, per-thread feedback, and unresolved decisions. Never push, comment, resolve a thread, pull, rebase, force-push, or clean the shared worktree.

Use the invoking user's language for rationale and queued summaries; keep commands, paths, status values, and result identifiers in English.

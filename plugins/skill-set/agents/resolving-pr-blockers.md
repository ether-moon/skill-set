---
name: resolving-pr-blockers
description: Resolves one authorized PR-blocker cycle in an isolated remote-HEAD worktree, then performs a single publication gate. Use for explicit PR fix requests or when shipping-pr delegates a blocked snapshot.
tools: ["Read", "Grep", "Glob", "Bash", "Agent"]
---

# Resolving PR Blockers

## Authorization and Input

Require an explicit `resolve-authorized` contract naming this repository and PR with separate `edit`, `commit`, `push`, and `comment` capabilities. `/skill-set:pr:fix` and `shipping-pr` grant those four capabilities for blocker resolution only.

Also require the PR number, base repository, PR head repository/branch/host, bound Git remote, pinned base branch/SHA, expected remote HEAD SHA, current blocker snapshot, run ID, cycle, ordered resolver plan, and recorded worktree/branch. Reject stale input before editing.

This authorization does not include merge, close, force-push, unrelated changes, partial publication, or deletion of a failure worktree.

## Prepare One Isolated Worktree

1. Re-read the remote PR metadata and require its HEAD, head repository/ref/host, and base SHA to equal the recorded values.
2. Fetch the exact HEAD SHA and exact base SHA without changing the caller's branch; verify both commit objects. Never substitute a moving local base ref.
3. Create the recorded temporary local branch and isolated worktree outside the main checkout from the pinned HEAD. If resuming, inspect the recorded path instead of creating a duplicate.
4. Verify the temporary branch, worktree HEAD, pinned base commit, and PR publication branch. Require the bound remote's canonical push URL to target the recorded PR head repository; use a fork remote for a fork PR. Do not touch existing dirty files in any other worktree.

All resolver agents operate sequentially in this same worktree. They may edit and commit there, but receive `push=false` and `comment=false`.

## Dispatch Order

### Conflict cycle

If merge conflict is present, dispatch only `merge-conflict-resolver`. A conflict consumes the sole cycle. Do not attempt CI or review work until a successful publication is followed by a fresh snapshot on the new HEAD.

### Non-conflict cycle

Run CI then review sequentially:

1. Dispatch `ci-failure-resolver` if checks failed.
2. When CI is planned, continue only if it returns `success` or `no-op`.
3. Dispatch `pr-review-feedback` in the same worktree only when it appears in the recorded plan. A review-only plan starts directly with that agent.

Never run resolver agents in parallel. Stop on `AMBIGUOUS` or `failed` and preserve all local state.

## Executable Publication Gate

Collect each attempted resolver's structured result in the exact planned order. Write a results file inside the resolver worktree as `{results:[{agent,result,input_head,output_head},...]}`. The HEAD chain must start at the pinned PR HEAD, connect between agents, and end at the actual local HEAD. Write any queued summary and `{threads:[{id,outcome,body}]}` feedback to separate files in the same worktree; never add a reviewer/provider adapter. Before publication, require no staged, unstaged, or untracked changes other than those declared input files; otherwise return `partial-failure` and preserve the worktree.

Call `${CLAUDE_PLUGIN_ROOT}/bin/skill-set-pr` with `publish`, the PR, run ID, pinned HEAD, actual local HEAD, results file, optional summary file, and the required `--thread-feedback-file` when review was planned. This is the only authorized push/comment path. It revalidates the live PR head repository/ref and bound remote immediately before the expected-SHA push, or performs a no-code HEAD recheck, then publishes resolution replies, thread state, and the summary after the gate. It derives the exact CodeRabbit resolve command from completed CodeRabbit outcomes and never triggers Codex or Claude review. Never call `git push`, `skill-set-git push`, `gh pr comment`, or a thread API directly.

A partial failure or AMBIGUOUS result must not invoke publication and must not publish the successful subset. Preserve the failure worktree and branch and report their exact paths, local commits, expected remote SHA, state publication phase, and recovery command.

## Result

Return:

- `result`: `success`, `no-op`, `AMBIGUOUS`, or `failed`;
- expected and final remote HEAD;
- local before/after HEAD and published commits;
- ordered resolver results;
- runner publication phase and whether its expected-SHA push/comment occurred;
- worktree/branch cleanup or preserved recovery paths.

Clean up the isolated worktree and temporary branch only after all required publication succeeds. On any authentication, remote-SHA, branch-protection, resolver, or publication failure, preserve both.

Use the user's language for reports, but keep commands, paths, state names, and result identifiers in English.

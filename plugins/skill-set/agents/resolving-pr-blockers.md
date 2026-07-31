---
name: resolving-pr-blockers
description: Resolves one authorized PR-blocker cycle in the current PR worktree, then performs a single publication gate. Use for explicit PR fix requests or when shipping-pr delegates a blocked snapshot.
tools: ["Read", "Grep", "Glob", "Bash", "Agent"]
---

# Resolving PR Blockers

## Authorization and Input

Require an explicit `resolve-authorized` contract naming this repository and PR with separate `edit`, `commit`, `push`, and `comment` capabilities. `/skill-set:pr:fix` and `shipping-pr` grant those four capabilities for blocker resolution only.

Do not request separate user approval for those commits or for runner publication. The supplied capability contract is the approval. Retry stale state through a fresh snapshot; pause only for an AMBIGUOUS resolution decision or an external failure that cannot be repaired automatically.

Also require the PR number, base repository, PR head repository/branch/host, bound Git remote, pinned base branch/SHA, expected remote HEAD SHA, current blocker snapshot, run ID, cycle, ordered resolver plan, recorded worktree/branch, and `workspace_mode=current`. A resumed decision pass also requires the runner-recorded selected resolution or skip for every decision ID. Reconcile stale local input in place before editing.

This authorization does not include closing the PR, force-push, unrelated changes, partial publication, or discarding current worktree state.

## Prepare the Current Worktree

1. Re-read the remote PR metadata and require its HEAD, head repository/ref/host, and base SHA to equal the recorded values.
2. Verify `workspace_mode=current`, the recorded worktree is the caller's repository root, and the recorded branch is still checked out. Never create another worktree or branch and never switch branches.
3. Fetch the exact HEAD SHA and exact base SHA without checkout; verify both commit objects. Never substitute a moving local ref.
4. Preserve the complete authorized current state. Commit new working-tree changes through the Git runner, then reconcile local and remote PR history in place: fast-forward when local is behind, retain local descendants when ahead, or merge the exact fetched remote commit when diverged. Retry against a newly observed remote HEAD instead of stopping for a routine mismatch. Only an AMBIGUOUS conflict or an external failure that cannot be repaired automatically waits for the user.
5. Verify the current branch, reconciled HEAD, pinned base commit, and PR publication branch. Require the bound remote's canonical push URL to target the recorded PR head repository; use a fork remote for a fork PR.

All resolver agents operate sequentially in this same worktree. Classify phase is read-only. Resolve-phase agents may edit and commit there, but receive `push=false` and `comment=false`.

## Decision Gate and Dispatch Order

Run a classification phase across the complete resolver plan before any resolver mutation. Each planned agent returns stable IDs for AMBIGUOUS items and must leave the worktree and index unchanged. If any AMBIGUOUS item exists, stop before resolve phase, transition `resolving -> awaiting_user` with one `--decision-request <ID>` per item, and preserve the unchanged resolver worktree.

After the user selects every resolution or skip, transition `awaiting_user -> resolving` with one `--resolver-decision '<ID>=<selected-resolution>'` per recorded ID. Re-dispatch the recorded plan in resolve phase with those exact decisions. If there are no AMBIGUOUS items, continue from classification to resolve phase automatically without asking for confirmation. In resolve phase, each agent applies all queued OBVIOUS fixes and selected AMBIGUOUS resolutions in one bounded pass.

### Conflict cycle

If merge conflict is present, dispatch only `merge-conflict-resolver` for classification and, after the decision gate when needed, resolution. A conflict consumes the sole cycle. Do not attempt CI or review work until a successful publication is followed by a fresh snapshot on the new HEAD.

### Non-conflict cycle

Classify CI then review sequentially without mutation, then resolve them sequentially after the shared decision gate:

1. Dispatch `ci-failure-resolver` if checks failed.
2. In classify phase, continue to `pr-review-feedback` after either a decision-free CI classification or an AMBIGUOUS CI classification; stop only on failure.
3. In resolve phase, continue only if CI returns `success` or `no-op`.
4. Dispatch `pr-review-feedback` in the same worktree only when it appears in the recorded plan. A review-only plan starts directly with that agent.

Never run resolver agents in parallel. Stop on `failed` and preserve all local state. An AMBIGUOUS classification pauses the whole plan before any resolver edit; it does not permit a successful subset to mutate or commit first.

## Executable Publication Gate

Collect each attempted resolver's structured result in the exact planned order. Write a results file inside the current worktree as `{results:[{agent,result,input_head,output_head},...]}`. The HEAD chain must start at the pinned PR HEAD, include any in-place reconciliation, connect between agents, and end at the actual local HEAD. Write any queued summary and `{threads:[{id,outcome,body}]}` feedback to separate files in the same worktree; never add a reviewer/provider adapter. Before publication, require no staged, unstaged, or untracked changes other than those declared input files; otherwise return `partial-failure` and preserve the worktree.

Resolve `skills/shipping-pr/scripts/skill-set-pr` from the installed skill collection and call its absolute path with `publish`, the PR, run ID, pinned HEAD, actual local HEAD, results file, optional summary file, and the required `--thread-feedback-file` when review was planned. This is the only authorized push/comment path. It revalidates the live PR head repository/ref and bound remote immediately before the expected-SHA push, or performs a no-code HEAD recheck, then publishes resolution replies, thread state, and the summary after the gate. It derives the exact CodeRabbit resolve command from completed CodeRabbit outcomes and never triggers Codex or Claude review. Never call `git push`, `skill-set-git push`, `gh pr comment`, or a thread API directly.

A partial failure or AMBIGUOUS result must not invoke publication and must not publish the successful subset. Preserve the current worktree and branch and report their exact paths, local commits, expected remote SHA, state publication phase, and recovery command.

If the live PR HEAD changes before the publication gate succeeds, preserve the current branch and return resolver result `stale` through `resolving -> polling`. Take a fresh snapshot and reconcile automatically; do not turn routine staleness into `awaiting_user`.

## Result

Return:

- `result`: `success`, `no-op`, `AMBIGUOUS`, or `failed`;
- expected and final remote HEAD;
- local before/after HEAD and published commits;
- ordered resolver results;
- runner publication phase and whether its expected-SHA push/comment occurred;
- current worktree/branch and preserved recovery paths.

Do not remove a worktree or delete a branch after publication; the resolver reused the caller's current checkout. On any authentication, remote-SHA, branch-protection, resolver, or publication failure, preserve it unchanged for recovery.

Use the user's language for reports, but keep commands, paths, state names, and result identifiers in English.

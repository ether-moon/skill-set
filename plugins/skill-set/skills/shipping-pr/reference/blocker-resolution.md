# Blocker Resolution and Publication Gate

One resolver cycle uses one isolated worktree created from the exact remote PR HEAD and one temporary local branch. Before editing, fetch and verify both `expected_remote_sha` and the exact PR `baseRefOid`; record the base SHA/ref, PR head repository/branch/host, worktree, branch, bound remote, ordered agents, and blocker fingerprint in the runner transition. The remote's canonical push URL must target that head repository, including the contributor's repository for a fork PR. Do not rely on a moving local target ref.

## Ordering

If the snapshot reports a merge conflict, run only `merge-conflict-resolver`. The conflict consumes the sole cycle; after a successful expected-SHA push, return to a new snapshot on the new HEAD.

If no conflict exists:

1. run `ci-failure-resolver` when selected checks failed;
2. when CI is planned, require it to succeed or no-op before continuing;
3. run `pr-review-feedback` only when actionable threads put it in the recorded plan; a review-only plan begins there;
4. when both are planned, keep them sequential in the same worktree and branch.

Do not run resolvers in parallel. They must see earlier edits and share one publication decision.

## Resolver Result

Each resolver returns:

- `result`: `success`, `no-op`, `AMBIGUOUS`, or `failed`;
- commits and modified paths;
- HEAD before and after;
- queued PR summary and per-thread resolution feedback, if review activity occurred;
- unresolved decisions and recovery instructions.

An AMBIGUOUS result is not success. Preserve all local work and wait for the user.

## Executable Publication Gate

Write `{results:[...]}` to a regular, non-symlink file inside the resolver worktree. Each ordered result contains `agent`, `result`, `input_head`, and `output_head`; adjacent HEAD values form one chain from the blocked snapshot to the actual local HEAD. Write the queued summary and thread feedback to separate files in that worktree. The thread-feedback shape is `{threads:[{id,outcome,body}]}` with one exact blocked-snapshot thread ID per entry and an outcome of `fixed`, `accepted_as_is`, or `unresolved`. Do not supply a reviewer/provider adapter: the runner derives `claude`, `coderabbit`, `codex`, or `other` from the snapshot thread author. Bodies explain the resolution and contain no bot mentions or commands. Apart from those declared inputs, the index and worktree must contain no staged, unstaged, or untracked files.

Resolve `scripts/skill-set-pr` from the `shipping-pr` skill directory and call its absolute path with `publish`, the run ID, blocked HEAD, validated local HEAD, results file, summary file, and `--thread-feedback-file`. Do not call `git push`, `skill-set-git push`, `gh pr comment`, a thread-reply API, or a resolve API outside this command.

The runner validates the planned agents, result set, HEAD chain, branch, pinned commits, clean publication boundary, exact thread coverage, live PR head repository/ref, bound remote push URL, and remote HEAD. It checks the remote binding again immediately before invoking one expected-SHA push when the local HEAD changed and revalidates no-code activity. Only after that gate does it post idempotently marked thread replies, resolve `fixed` and `accepted_as_is` threads, and post the summary. When all queued CodeRabbit feedback is resolved, the runner itself prepends the exact `@coderabbitai resolve` command; this is never inferred from free-form text or supplied as an adapter flag. It never asks Codex or Claude to review again or to edit the PR. `pending → prepared → gate_passed → commenting → complete` state records make interrupted publication recoverable and hidden markers suppress duplicate feedback.

A partial failure, failed resolver, AMBIGUOUS result, missing result, reordered agent, or broken HEAD chain fails before push or comment. Preserve the failure worktree and branch and report both paths.

## Progress

After a resolver attempt:

- a new remote HEAD or changed blocker fingerprint returns to `polling`;
- review-only publication returns to `polling` so thread state can be observed;
- the same HEAD and same fingerprint on the required post-resolver snapshot becomes `stalled`.

Do not infer progress from local commits alone. Only verified remote state or changed review state counts.

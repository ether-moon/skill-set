# Blocker Resolution and Publication Gate

One resolver cycle uses the currently checked-out PR worktree and branch. Do not create another worktree, create a temporary resolver branch, or switch branches. Before editing, fetch and verify both `expected_remote_sha` and the exact PR `baseRefOid`; record the base SHA/ref, PR head repository/branch/host, current worktree, current branch, bound remote, ordered agents, and blocker fingerprint in the runner transition. The remote's canonical push URL must target that head repository, including the contributor's repository for a fork PR. Do not rely on a moving local target ref.

## In-Place Reconciliation

Preserve the complete current branch state. Commit any newly authorized working-tree changes through the Git runner before resolver edits. If the fetched remote PR HEAD differs from local HEAD, reconcile without changing branches: fast-forward local HEAD when possible, keep unpublished local descendants, or merge the exact fetched remote commit into the current branch when the histories diverged. Never rebase or force-push. A routine local/remote mismatch is work to reconcile, not a reason to create another checkout or stop. Only an ambiguous conflict or an external failure that cannot be repaired automatically waits for the user.

## Decision Gate and Ordering

Run every planned resolver first with `phase=classify`. Classification must inspect the pinned evidence and return stable IDs for AMBIGUOUS items without editing, staging, merging, testing a proposed fix, or committing. If any resolver reports AMBIGUOUS, stop the complete plan before mutation and transition with one `--decision-request <ID>` per item.

After the user selects every resolution or skip, persist the choices with one `--resolver-decision '<ID>=<selected-resolution>'` per recorded ID and rerun the recorded plan with `phase=resolve`. If classification found no AMBIGUOUS item, enter resolve phase automatically. Resolve phase applies every queued OBVIOUS fix and selected AMBIGUOUS resolution without another confirmation.

If the snapshot reports a merge conflict, run only `merge-conflict-resolver` in each required phase. Classification uses non-checkout merge analysis and must not start a worktree merge. The conflict consumes the sole cycle; after a successful expected-SHA push, return to a new snapshot on the new HEAD.

When the resolved merge index is tree-identical to the pinned PR HEAD, the merge resolver must use the Git runner's explicit `--allow-tree-identical-merge` path. That path records ancestry only after validating a single active merge, a conflict-free index equal to the `HEAD` tree, and an otherwise clean worktree; never substitute a raw empty commit.

If no conflict exists, use this order in both phases:

1. run `ci-failure-resolver` when selected checks failed;
2. in classify phase, collect CI classifications before review classification without applying fixes;
3. in resolve phase, require CI to succeed or no-op before continuing;
4. run `pr-review-feedback` only when actionable threads or unreviewed current-HEAD review bodies put it in the recorded plan; a review-only plan begins there;
5. when both are planned, keep them sequential in the current worktree and branch.

Do not run resolvers in parallel. Classifiers share one decision gate; resolve-phase agents see earlier authorized edits and share one publication decision.

## Resolver Result

Each resolver returns:

- `result`: `success`, `no-op`, `AMBIGUOUS`, or `failed`;
- `phase`: `classify` or `resolve`;
- commits and modified paths;
- HEAD before and after;
- queued PR summary and processed review-body keys, plus per-thread resolution feedback when threads were present;
- classifications with stable decision IDs, selected resolutions, and recovery instructions.

An AMBIGUOUS classify result is not success. Confirm that the resolver made no worktree or index mutation, record every decision ID, and wait for the user. Resolve phase must not begin until the complete decision set is persisted.

## Executable Publication Gate

Write `{results:[...]}` to a regular, non-symlink file inside the resolver worktree. Each ordered result contains `agent`, `result`, `input_head`, and `output_head`; adjacent HEAD values form one chain from the blocked snapshot to the actual local HEAD. Write the queued summary and, when threads were present, thread feedback to separate files in that worktree. The thread-feedback shape is `{threads:[{id,outcome,body}]}` with one exact blocked-snapshot thread ID per entry and an outcome of `fixed`, `accepted_as_is`, or `unresolved`. Omit the file for a review-body-only pass. Do not supply a reviewer/provider adapter: the runner derives `claude`, `coderabbit`, `codex`, or `other` from the snapshot thread author. Bodies explain the resolution and contain no bot mentions or commands. Apart from those declared inputs, the index and worktree must contain no staged, unstaged, or untracked files.

Resolve `scripts/skill-set-pr` from the `shipping-pr` skill directory and call its absolute path with `publish`, the run ID, blocked HEAD, validated local HEAD, results file, summary file, and `--thread-feedback-file`. Do not call `git push`, `skill-set-git push`, `gh pr comment`, a thread-reply API, or a resolve API outside this command.

The runner validates the planned agents, result set, HEAD chain, branch, pinned commits, clean publication boundary, exact thread coverage, live PR head repository/ref, bound remote push URL, and remote HEAD. It checks the remote binding again immediately before invoking one expected-SHA push when the local HEAD changed and revalidates no-code activity. Only after that gate does it post idempotently marked thread replies, resolve `fixed` and `accepted_as_is` threads, and post the summary. When all queued CodeRabbit feedback is resolved, the runner itself prepends the exact `@coderabbitai resolve` command; this is never inferred from free-form text or supplied as an adapter flag. It never asks Codex or Claude to review again or to edit the PR. `pending → prepared → gate_passed → commenting → complete` state records make interrupted publication recoverable and hidden markers suppress duplicate feedback.

A partial failure, failed resolver, AMBIGUOUS result, missing result, reordered agent, or broken HEAD chain fails before push or comment. Preserve the current worktree and branch and report both paths.

When the live PR HEAD changes before publication, do not treat ordinary staleness as a user decision. Preserve the current branch, return `resolving -> polling` with resolver result `stale`, take a fresh snapshot, reconcile the exact new HEAD in place, and retry the normal cycle. The stale result publishes neither code nor comments.

## Progress

After a resolver attempt:

- a new remote HEAD or changed blocker fingerprint returns to `polling`;
- review-only publication returns to `polling` so thread state and processed review-body identities can be observed;
- the same HEAD and same fingerprint on the required post-resolver snapshot becomes `stalled`.

Do not infer progress from local commits alone. Only verified remote state or changed review state counts.

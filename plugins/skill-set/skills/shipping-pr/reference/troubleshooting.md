# Troubleshooting

## Active run or lock

Use `init --resume` when state reports an active run. A lock-directory error means another operation is updating the same PR state. Wait for it to finish. Remove a stale lock only after confirming no runner process is active.

## Compare-and-swap rejection

Another snapshot or transition won the race. Reload the state and continue from its `run_id` and `status`; never overwrite the file manually.

## HEAD changed during a snapshot

The returned results were discarded intentionally. Call `snapshot` again. The check deadline, review deadline, and check-registration grace were reset for the new HEAD.

## Interrupted resolver run

A resumed `resolving` state must use `.resolution.worktree`, `.resolution.branch`, pinned SHAs, expected agents, and `.resolution.publication`; never launch a second resolver. For `prepared`, `gate_passed`, or `commenting`, call `publish` with the same recorded files and expected local HEAD. It reconciles an already-pushed HEAD and searches the stable hidden marker before commenting. For `pending`, the resolver was interrupted before a safe result set was journaled: report the paths and transition with `--resolver-attempt --resolver-result partial-failure` to `awaiting_user`. Use `failed` only when recovery is impossible. A resumed `awaiting_user` state stays paused until the user explicitly chooses how to continue.

## Pending or unknown checks

Pending, cancelled, unknown, and timed-out checks are never clean. Report their buckets and deadline. Do not dispatch a code resolver for a merely pending check.

## Automated reviewer absent

Reviewer detection cannot be overridden. Report the detected provider, its current state, and the review deadline. An active CodeRabbit reviewer without current-HEAD status/check evidence remains pending until that deadline. On later cycles, absent Claude or Codex evidence becomes `not_expected`; do not post a review command to manufacture a completion signal.

## Resolver failure

Do not push partial commits. Preserve the isolated worktree and branch, report their paths and the expected remote SHA, and transition to `awaiting_user` or `failed`.

## PR head or remote binding changed

The recorded PR head repository, branch, and host are compare-and-swap inputs, not hints. For a fork, configure the selected remote's push URL for the fork repository. On `head_branch_mismatch`, `remote_binding_mismatch`, or `pr_head_binding_changed`, do not push or comment: take a fresh snapshot, verify the live head repository/ref, and begin a new resolver attempt with the correctly bound remote.

## Publication failure

Keep the worktree, results file, summary file, thread-feedback file, and publication journal. Never bypass `skill-set-pr publish`. A `prepared` state may safely reconcile whether the expected-SHA push took effect; `gate_passed` and `commenting` never push again. If the remote is neither the pinned old HEAD nor recorded local HEAD, stop for user inspection.

## Structured runner error

The runner emits failure JSON on stderr with `error.code`, `error.message`, and `error.recovery`. Follow the recovery field and retain the JSON in the final report.

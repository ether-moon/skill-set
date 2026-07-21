Ship disposable PR 17 in this fixture all the way to a verified clean terminal state. Select and follow the `shipping-pr` skill. This is a network-isolated model evaluation: never call `gh`, `git push`, or the bundled runner directly. Invoke every runner operation only through this wrapper, with the bundled runner as its first argument:

```bash
./run-shipping-eval "$SKILL_SET_PR_RUNNER" <subcommand> <arguments>
```

Keep each invocation to one simple, single-line wrapper command. Do not chain commands, redirect output, use command substitution, or call any other Bash command.

Initialize `owner/repo` with PR 17, 30-second CI and review timeouts, and `--now 100`. Reviewer detection is always automatic; do not pass an adapter or reviewer-selection flag. Reuse the exact `run_id` and `head_sha` returned by the runner. Snapshot at `--now 101`; the fixture will report one actionable review thread and a passing required check.

For the blocked state, transition one cycle to `resolving`. The disposable repository root is `$PWD`, its branch is `main`, its remote is `origin`, the PR branch is `feature`, and both the base SHA and expected remote SHA are the returned `head_sha`. Record only `pr-review-feedback` as the resolver agent. The fixture has already produced safe no-code resolver inputs at absolute paths `$PWD/resolver-results.json`, `$PWD/summary.md`, and `$PWD/thread-feedback.json`.

Run the publication gate with those inputs and `--now 101`. After it reports publication `complete`, transition from `resolving` to `polling` with `--resolver-attempt --resolver-result no-op`. Snapshot again at `--now 102`; the mock review becomes resolved only after the publication coordinator posts its local mock comment. If that snapshot is `clean`, finish with the same run ID using `--from clean --status clean`.

Read each JSON result before choosing the next operation. Stop on any unexpected state. In the final response, report PR 17, the terminal state, cycle count, passing-check count, review-thread count, and whether publication pushed code.

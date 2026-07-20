# Snapshot and Polling Contract

`skill-set-pr snapshot --pr <number> --expected-run-id <id>` performs one bounded, compare-and-swap observation from `polling`. Wait 30 seconds between polling snapshots. This bounded cadence avoids GitHub hammering while absolute state-file deadlines survive model re-entry.

## Stable-HEAD Read

Each snapshot reads the PR HEAD SHA, repository, branch, and host before and after checks, review threads, and CodeRabbit status. If that binding differs, the runner:

1. discards every intermediate result;
2. stores the new HEAD;
3. resets CI and review deadlines from the current time;
4. returns `polling` with `discarded=true`.

If the stored HEAD changed before the snapshot but the two current reads agree, current results are valid and deadlines still reset.

## Checks

The runner calls `gh pr checks --json bucket,name,state,link,workflow` and optionally `--required`. Buckets are classified as:

| Bucket | Meaning |
|---|---|
| `pass`, `skipping` | Satisfied |
| `fail`, `cancel` | Blocked |
| `pending` or unknown | Polling until the CI deadline |

Pending at the deadline becomes `timed_out`. For a new HEAD, zero selected checks remain `polling` for a 60-second registration grace so a fresh push cannot appear clean before workflows register. After that grace, a repository with genuinely no selected checks may satisfy the check condition. If checks were observed and later disappear, polling continues until the CI deadline.

## Review Threads

The runner queries GraphQL `reviewThreads(first:100, after:$cursor)` and follows `pageInfo.endCursor` until `hasNextPage=false`. An actionable thread is unresolved, not outdated, and has a non-empty latest comment. There is no 100-thread truncation.

Praise and summary-only acknowledgements are filtered by one deliberately narrow whole-message rule. The runner ASCII-lowercases the latest body, replaces ASCII punctuation with spaces, collapses whitespace, and trims it. Only an exact normalized match for `lgtm`, `looks good`, `looks good to me`, `great work`, `great job`, `nice work`, `well done`, `thanks`, `thank you`, `approved`, `all good`, `ship it`, `summary`, `review summary`, `code review summary`, or `walkthrough` is non-actionable; a trimmed body consisting only of `👍`, `✅`, or `🎉` is also non-actionable. A praise phrase followed by any request remains actionable.

Any unresolved actionable thread makes the snapshot `blocked`.

## CodeRabbit

Initialization accepts `--coderabbit-required auto|true|false`. Auto mode detects recent repository use. When required, snapshots query both commit statuses and check-runs for the current HEAD and match CodeRabbit by context, name, or app.

Successful or neutral completion satisfies the completion signal; actionable comments are still evaluated through review threads. Failure, error, cancellation, timeout, or action-required is blocked. Pending or absent remains `polling` until the review deadline, then becomes `timed_out`.

## Mergeability

`CONFLICTING` or `DIRTY` is blocked. An unknown mergeability result is polling, never clean.

## Fingerprint

The blocker fingerprint covers the observed HEAD; normalized check identities, states, and buckets; conflict state; unresolved thread IDs and latest-comment content; and CodeRabbit state. After a resolver returns to polling, only a fresh snapshot can declare `stalled`, and only when both HEAD and fingerprint remain unchanged.

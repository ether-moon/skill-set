# Snapshot and Polling Contract

`skill-set-pr snapshot --pr <number> --expected-run-id <id>` performs one bounded, compare-and-swap observation from `polling`. Wait 30 seconds between polling snapshots. This bounded cadence avoids GitHub hammering while absolute state-file deadlines survive model re-entry.

## Stable-HEAD Read

Each snapshot reads the PR HEAD SHA, repository, branch, and host before and after checks, review threads, and automated-review evidence. If that binding differs, the runner:

1. discards every intermediate result;
2. stores the new HEAD;
3. resets CI and review deadlines from the current time;
4. returns `polling` with `discarded=true`.

If the stored HEAD changed before the snapshot but the two current reads agree, current results are valid and deadlines still reset.

## Checks

The runner queries all active rules that apply to the base branch, including inherited organization rulesets, and unions their required status-check contexts with legacy branch-protection contexts. It then calls `gh pr checks --json bucket,name,state,link,workflow` and optionally `--required`. A configured required context that is missing from the current HEAD is synthesized as `pending`. Buckets are classified as:

| Bucket | Meaning |
|---|---|
| `pass`, `skipping` | Satisfied |
| `fail`, `cancel` | Blocked |
| `pending` or unknown | Polling until the CI deadline |

Pending or missing required contexts at the deadline become `timed_out`. For a new HEAD with no configured or observed selected checks, zero selected checks remain `polling` for a 60-second registration grace so a fresh push cannot appear clean before workflows register. After that grace, a repository with genuinely no selected checks may satisfy the check condition. If checks were observed and later disappear, polling continues until the CI deadline.

Signal-gated review workflows require no reviewer adapter. A review workflow gates completion only through the exact status or check context configured as required on the base branch. Do not wait for a workflow job, reviewer identity, review object, reaction, or comment merely because it exists. With `--required-only false`, all currently observed checks are intentionally selected in addition to the required set.

## Review Threads

The runner queries GraphQL `reviewThreads(first:100, after:$cursor)` and follows `pageInfo.endCursor` until `hasNextPage=false`. An actionable thread is unresolved, not outdated, and has a non-empty latest comment. There is no 100-thread truncation.

Praise and summary-only acknowledgements are filtered by one deliberately narrow whole-message rule. The runner ASCII-lowercases the latest body, replaces ASCII punctuation with spaces, collapses whitespace, and trims it. Only an exact normalized match for `lgtm`, `looks good`, `looks good to me`, `great work`, `great job`, `nice work`, `well done`, `thanks`, `thank you`, `approved`, `all good`, `ship it`, `summary`, `review summary`, `code review summary`, or `walkthrough` is non-actionable; a trimmed body consisting only of `👍`, `✅`, or `🎉` is also non-actionable. A praise phrase followed by any request remains actionable.

Any unresolved actionable thread makes the snapshot `blocked`.

## Automated Reviewers

Reviewer discovery is always `auto`; there is no adapter-selection flag. Initialization detects CodeRabbit, Claude, and `chatgpt-codex-connector` from authors and apps found in the ten most recent merged PRs. Every snapshot unions that history with current-PR commit statuses, check-runs, reviews, comments, and reactions for reporting only.

CodeRabbit telemetry comes from its current-HEAD commit status or check-run. Claude telemetry comes from its current-HEAD check-run, status, or review. Codex telemetry comes from a current-HEAD review or, before any resolver push, the connector's `+1` reaction. These signals are observational and are never independently required. Their absence, pending state, standalone failure, or change cannot affect polling, timeout, blocking, clean, or stalled decisions. A telemetry query or normalization failure is reported as `telemetry_available:false` with `unavailable` provider states.

Reviewer results that match effective required contexts use the normal check classification. Actionable comments from every provider still use review-thread state. In the default required-only mode, optional reviewer evidence remains report-only; `--required-only false` intentionally makes every observed check part of the verdict.

## Mergeability

`CONFLICTING` or `DIRTY` is blocked. Unknown mergeability is polling and becomes `timed_out` at the current-HEAD check deadline when no actionable blocker is available. `mergeStateStatus=BLOCKED` is reported but does not gate the verdict because it can represent approval requirements outside the required status-check set.

## Fingerprint

The blocker fingerprint covers the observed HEAD and base branch; effective required contexts; normalized check identities, states, and buckets; conflict or unknown-mergeability state; and unresolved thread IDs and latest-comment content. Reviewer telemetry and non-gating `mergeStateStatus` values never affect the fingerprint. After a resolver returns to polling, only a fresh snapshot can declare `stalled`, and only when both HEAD and fingerprint remain unchanged.

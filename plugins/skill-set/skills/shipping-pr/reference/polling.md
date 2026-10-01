# Snapshot and Polling Contract

`skill-set-pr snapshot --pr <number> --expected-run-id <id>` performs one bounded, compare-and-swap observation from `polling`. Wait 10 seconds between polling snapshots. This bounded cadence avoids GitHub hammering while absolute state-file deadlines survive model re-entry.

## Stable-HEAD Read

Each snapshot reads the PR HEAD SHA, repository, branch, and host before and after checks, review threads, and automated-review evidence. If that binding differs, the runner:

1. discards every intermediate result;
2. stores the new HEAD;
3. resets CI and review deadlines from the current time;
4. returns `polling` with `discarded=true`.

If the stored HEAD changed before the snapshot but the two current reads agree, current results are valid and deadlines still reset.

## Checks

The runner queries all active rules that apply to the base branch, including inherited organization rulesets, and unions their required status-check contexts with legacy branch-protection contexts. It then calls `gh pr checks --json bucket,name,state,link,workflow` both with and without `--required`. A configured required context that is missing from the current HEAD is synthesized as `pending`. All observed checks are returned in `observed_checks`. The selected `check_details` and `checks` include required checks (all checks with `--required-only false`) plus unfinished optional checks. Buckets in that selected set are classified as:

| Bucket | Meaning |
|---|---|
| `pass`, `skipping` | Satisfied |
| `fail`, `cancel` | Blocked |
| `pending` or unknown | Polling until the CI deadline |

Pending checks, including optional checks, or missing required contexts at the deadline become `timed_out`. For a new HEAD with no configured or observed checks, zero checks remain `polling` for a 60-second registration grace so a fresh push cannot appear clean before workflows register. After that grace, a repository with genuinely no checks may satisfy the check condition. Previously unfinished checks that disappear from later responses remain `MISSING`/`pending`, even when other checks remain. The runner retains their name/workflow/link identities across snapshots until completion is observed or the CI deadline expires. It clears that history when the HEAD, repository, branch, base branch, or host changes, or a snapshot is discarded. Checks whose completion was already observed do not need to reappear. A completely empty response after earlier check observations still waits until the CI deadline.

Signal-gated review workflows require no reviewer adapter. Every observed check must reach a terminal bucket before clean, even when it is optional. Optional failures and cancellations remain reporting-only by default; `--required-only false` selects their outcomes as blockers too. Reviewer identities or absent review objects, reactions, and comments do not create additional waits.

The exact GitHub CLI diagnostics `no checks reported on the '<branch>' branch` and, for `--required`, `no required checks reported on the '<branch>' branch` normalize to `[]` only with exit code 1 and empty stdout. Authentication, server, and malformed responses still fail closed.

## Review Threads

The runner queries GraphQL `reviewThreads(first:100, after:$cursor)` and follows `pageInfo.endCursor` until `hasNextPage=false`. An actionable thread is unresolved, not outdated, and has a non-empty latest comment. There is no 100-thread truncation.

Praise and summary-only acknowledgements are filtered by one deliberately narrow whole-message rule. The runner ASCII-lowercases the latest body, replaces ASCII punctuation with spaces, collapses whitespace, and trims it. Only an exact normalized match for `lgtm`, `looks good`, `looks good to me`, `great work`, `great job`, `nice work`, `well done`, `thanks`, `thank you`, `approved`, `all good`, `ship it`, `summary`, `review summary`, `code review summary`, or `walkthrough` is non-actionable; a trimmed body consisting only of `👍`, `✅`, or `🎉` is also non-actionable. A praise phrase followed by any request remains actionable.

Any unresolved actionable thread makes the snapshot `blocked`.

## Final Feedback Sweep

When checks, mergeability, registration grace, and review threads would otherwise permit `clean`, the snapshot performs bounded, paginated `reviews(first:100, after:$cursor)` and `comments(first:100, after:$cursor)` queries. It does not poll or wait for a review body to appear. No matching feedback means the snapshot may become `clean` immediately.

The sweep keeps non-empty, non-dismissed, non-pending review bodies whose review commit equals the current HEAD, plus non-empty PR issue comments. Issue comments have no commit binding; the resolver determines their relevance to the current diff. Both sources appear in `review_bodies`, with `source=review` or `source=issue_comment`. It applies the same narrow whole-message acknowledgement filter as review threads. Each candidate is keyed by its globally unique GraphQL ID plus `updatedAt`; a successfully published review pass records that key, while an edited body or new HEAD becomes eligible for inspection again.

The runner persists the exact body hashes of its successfully published summary comments across cycles. Matching comments are excluded from the sweep; a marker alone cannot exclude a comment. Edited summaries are eligible again.

An unreviewed body or issue comment makes the snapshot `blocked` so `pr-review-feedback` can classify its requests. The resolver deduplicates requests across threads, review bodies, and issue comments. A body with no actionable request returns `no-op`; after the publication gate records it as inspected, the next snapshot can become `clean` without seeing the unchanged body again.

## Automated Reviewers

Reviewer discovery is always `auto`; there is no adapter-selection flag. Initialization detects CodeRabbit, Claude, and `chatgpt-codex-connector` from authors and apps found in the ten most recent merged PRs. Every snapshot unions that history with current-PR commit statuses, check-runs, reviews, comments, and reactions for reporting only. This provider telemetry is distinct from the bounded review-body sweep above.

CodeRabbit telemetry comes from its current-HEAD commit status or check-run. Claude telemetry comes from its current-HEAD check-run, status, or review. Codex telemetry comes from a current-HEAD review or, before any resolver push, the connector's `+1` reaction. These signals are observational and are never independently required. Their absence, pending state, standalone failure, or change cannot affect polling, timeout, blocking, clean, or stalled decisions. A telemetry query or normalization failure is reported as `telemetry_available:false` with `unavailable` provider states.

Reviewer results that match effective required contexts use the normal check classification. Actionable comments from every provider still use review-thread state. Optional provider telemetry remains report-only, but observed optional checks always participate in the completion gate and their feedback participates in the final sweep. `--required-only false` also makes their failed outcomes block the verdict.

## Mergeability

`CONFLICTING` or `DIRTY` is blocked. Unknown mergeability is polling and becomes `timed_out` at the current-HEAD check deadline when no actionable blocker is available. `mergeStateStatus=BLOCKED` is reported but does not gate the verdict because it can represent approval requirements outside the required status-check set.

## Fingerprint

The blocker fingerprint covers the observed HEAD and base branch; effective required contexts; normalized check identities, states, and buckets; conflict or unknown-mergeability state; unresolved thread IDs and latest-comment content; and unreviewed current-HEAD review bodies and issue comments. Reviewer telemetry and non-gating `mergeStateStatus` values never affect the fingerprint. After a resolver returns to polling, only a fresh snapshot can declare `stalled`, and only when both HEAD and fingerprint remain unchanged.

# Troubleshooting — Common Mistakes

## Skipping the new-SHA check-runs wait
**Problem:** `gh pr checks --watch` runs immediately after push and reports the previous SHA's completed checks as final, declaring the cycle clean prematurely.
**Fix:** Always poll `repos/{o}/{r}/commits/{NEW_SHA}/check-runs` for `total_count > 0` (with 60 s budget) before entering `--watch`.

## Treating a CodeRabbit review timeout as "clean"
**Problem:** Step 4 waits a fixed time for CodeRabbit, but CodeRabbit's review can take longer (~15 min observed). On timeout the loop sees no review comments, and Step 7 declares the PR clean — when in fact CodeRabbit simply had not finished. The fix ping-pong silently ends one review short.
**Fix:** Poll the `CodeRabbit` commit status (`context == "CodeRabbit"`) on `TARGET_SHA` until it leaves `pending`; that terminal state is the real completion signal. If the 30-min cap is hit while still pending, carry `REVIEW_VERIFIED=false` so Step 7 exits "not verified" instead of "clean".

## Watching advisory checks
**Problem:** `gh pr checks --watch` blocks on never-completing advisory checks (codecov pending, preview deploys).
**Fix:** Use `--required` (default) unless user explicitly opts out.

## Treating `mergeable == UNKNOWN` as clean
**Problem:** GitHub computes mergeability lazily; a cold cache returns UNKNOWN and the loop misclassifies as clean.
**Fix:** Sleep 3 s and re-query once when UNKNOWN, matching the existing `resolving-pr-blockers` convention.

## Trying to compare blocker sets across cycles
**Problem:** Hard to distinguish "same blocker, different test" from "exact same failure". Easy to false-positive (premature exit) or false-negative (infinite loop).
**Fix:** Use the simple "did the resolver produce a new commit?" signal. If yes, run another cycle; if no, stop.

## Using a fixed sleep after push
**Problem:** GitHub registration latency varies; any fixed value is wrong somewhere.
**Fix:** Poll `check-runs` count instead of sleeping.

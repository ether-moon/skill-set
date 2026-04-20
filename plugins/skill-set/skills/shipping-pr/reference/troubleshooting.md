# Troubleshooting — Common Mistakes

## Skipping the new-SHA check-runs wait
**Problem:** `gh pr checks --watch` runs immediately after push and reports the previous SHA's completed checks as final, declaring the cycle clean prematurely.
**Fix:** Always poll `repos/{o}/{r}/commits/{NEW_SHA}/check-runs` for `total_count > 0` (with 60 s budget) before entering `--watch`.

## Forgetting the `commit_id` filter on CodeRabbit reviews
**Problem:** Step 4 returns the cycle-1 review immediately on cycle 2, mistaking it for a new incremental review.
**Fix:** Always filter `select(.commit_id == "$TARGET_SHA")`.

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

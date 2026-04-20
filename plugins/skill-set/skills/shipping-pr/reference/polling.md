# Polling — Cycle Steps 2–4

These three steps run inside the cycle loop in `SKILL.md`. They wait for the new HEAD's checks to register, wait for CI to stabilize (chunked under the Bash 10-min cap), and optionally wait for CodeRabbit's incremental review.

## Step 2: Wait for new HEAD's check-runs to register

After Step 0 (or after fix push in prior cycle), GitHub takes 15–60 s to register `check_runs` for the new SHA. `gh pr checks --watch` without this guard may report stale results from the previous SHA.

```bash
TARGET_SHA=$(gh pr view --json headRefOid -q .headRefOid)
WAITED=0
while [ $WAITED -lt 60 ]; do
  COUNT=$(gh api "repos/$OWNER/$REPO/commits/$TARGET_SHA/check-runs" -q '.total_count' 2>/dev/null || echo 0)
  [ "$COUNT" -gt 0 ] && break
  sleep 5; WAITED=$((WAITED + 5))
done
# COUNT == 0 after 60s = no workflows triggered for this SHA (e.g., docs-only change with path filter)
```

## Step 3: CI stabilization (chunked, model re-entry safe)

Bash tool's hard limit is ~10 min. Use 9-minute chunks of `gh pr checks --watch` with re-entry between chunks. Track elapsed time; abort if `--ci-timeout` exceeded.

```bash
REQ_FLAG=""
[ "$REQUIRED_ONLY" = "true" ] && REQ_FLAG="--required"

CI_DEADLINE=$(( $(date +%s) + CI_TIMEOUT_MIN * 60 ))

while [ $(date +%s) -lt $CI_DEADLINE ]; do
  # 540s = 9 min, leaves headroom under Bash 10-min limit.
  # Possible exits: 0=all pass, 8=in_progress remains, 124=timeout cap hit,
  # other non-zero=failures present. We always re-check status next, so we
  # discard the watch's exit code — it's an intermediate signal.
  "$TIMEOUT_BIN" 540 gh pr checks "$PR" $REQ_FLAG --watch --interval 30 || true

  STATES=$(gh pr checks "$PR" $REQ_FLAG --json state -q '[.[].state] | unique')
  PENDING=$(echo "$STATES" | jq '[.[] | select(. == "PENDING" or . == "QUEUED" or . == "IN_PROGRESS")] | length')
  [ "$PENDING" = "0" ] && break
done
```

If deadline hit without stabilization: report "CI did not stabilize within $CI_TIMEOUT_MIN min" and exit (do not invoke resolver on indeterminate state).

## Step 4: CodeRabbit incremental review wait (only if WAIT_CR)

CRITICAL: filter by `commit_id == TARGET_SHA`. Stale reviews from prior SHAs would otherwise be returned immediately, defeating the wait.

```bash
[ "$WAIT_CR" = "true" ] && {
  REVIEW_DEADLINE=$(( $(date +%s) + REVIEW_TIMEOUT_MIN * 60 ))
  while [ $(date +%s) -lt $REVIEW_DEADLINE ]; do
    HIT=$(gh api "repos/$OWNER/$REPO/pulls/$PR/reviews" \
      | jq --arg sha "$TARGET_SHA" -r '.[]
          | select(.user.login | test("coderabbitai"))
          | select(.commit_id == $sha) | .id' | head -1)
    [ -n "$HIT" ] && break
    sleep 30
  done
  [ -z "$HIT" ] && echo "CodeRabbit review did not arrive within $REVIEW_TIMEOUT_MIN min — proceeding"
}
```

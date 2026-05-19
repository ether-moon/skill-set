# Polling — Cycle Steps 2–4

These three steps run inside the cycle loop in `SKILL.md`. They wait for the new HEAD's checks to register, wait for CI to stabilize (chunked under the Bash 10-min cap), and optionally wait for CodeRabbit's review to complete.

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

## Step 4: CodeRabbit review-completion wait (only if WAIT_CR)

CodeRabbit publishes a **commit status** named `CodeRabbit` (`context == "CodeRabbit"` on the legacy commit-status API). It sits at `pending` while CodeRabbit reviews and flips to `success`/`failure`/`error` once the review — inline comments and the review object — is fully posted. That status is the real completion signal: poll it instead of guessing a fixed timeout. A fixed wait conflates "CodeRabbit hasn't finished yet" with "CodeRabbit finished and found nothing" — the premature-clean bug (see `troubleshooting.md`, "any fixed value is wrong somewhere").

`--review-timeout` (default 30 min) is only a safety cap for a CodeRabbit that never finishes — not the expected wait. The outcome is the `REVIEW_VERIFIED` flag: `false` means the review never completed, and Step 7 refuses to call the PR clean on that basis.

This wait can exceed the Bash tool's 10-min limit, so it is chunked like Step 3. Carry the absolute `REVIEW_DEADLINE` epoch across re-entries so the 30-min cap is measured from the cycle's start, not reset per chunk.

```bash
REVIEW_VERIFIED=false
[ "$WAIT_CR" = "true" ] && {
  # REVIEW_DEADLINE persists across model re-entries — set once per cycle.
  : "${REVIEW_DEADLINE:=$(( $(date +%s) + REVIEW_TIMEOUT_MIN * 60 ))}"
  CHUNK_END=$(( $(date +%s) + 540 ))   # 9-min chunk, headroom under Bash 10-min limit

  while [ $(date +%s) -lt $REVIEW_DEADLINE ] && [ $(date +%s) -lt $CHUNK_END ]; do
    # Status is queried on TARGET_SHA directly, so unlike the old review-object
    # poll there is no stale-result risk — no commit_id filter needed.
    CR_STATE=$(gh api "repos/$OWNER/$REPO/commits/$TARGET_SHA/status" \
      | jq -r '[.statuses[] | select(.context | ascii_downcase | test("coderabbit"))]
               | (.[0].state // "absent")')
    case "$CR_STATE" in
      success|failure|error)
        # Terminal state = CodeRabbit finished this commit. failure/error still
        # count as done — the review comments are what later steps consume.
        REVIEW_VERIFIED=true; break ;;
      pending|absent)
        # Still reviewing, or status not yet registered for this SHA.
        sleep 30 ;;
    esac
  done
}
```

If the chunk ends with `REVIEW_VERIFIED=false` and `REVIEW_DEADLINE` is not yet reached, re-enter this step (carrying the same `REVIEW_DEADLINE`). If the deadline is reached while still `false`, CodeRabbit did not finish within `--review-timeout` min — carry `REVIEW_VERIFIED=false` into Step 5; Step 7 will report the PR as not-verified rather than clean.

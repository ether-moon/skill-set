# shipping-pr — CodeRabbit Review Gate Design

**Date:** 2026-05-19
**Skill:** `plugins/skill-set/skills/shipping-pr`
**Status:** Approved design — ready for implementation plan

## Problem

`/skill-set:pr:ship` sometimes declares a PR "clean" before CodeRabbit has
produced its review. After fixes are committed and pushed, CodeRabbit's
incremental review can take longer than the skill's wait window, so the loop
terminates with a false "clean" verdict and the review ping-pong never
completes.

## Root Cause (confirmed)

Evidence — `karrot-emu/geo-grid` PR #17:

| Time (UTC) | Event |
|------------|-------|
| 05:49:57 | HEAD commit `67aec1c0f` pushed |
| 05:54:44 | CodeRabbit posts walkthrough summary comment (review starts) |
| 06:04:27–28 | CodeRabbit posts 16 inline review comments |
| 06:04:31 | CodeRabbit submits the formal review (`commit_id=67aec1c0f`) |

CodeRabbit's review took **~14.5 minutes** (push → formal review). The skill's
default `--review-timeout` is **10 minutes**, so Step 4 times out before the
review lands, prints "review did not arrive — proceeding", and Step 7's
convergence check then sees no CI failures, no conflicts, and no review
comments (they do not exist yet) — declaring `PR is clean` and `exit 0`.

Step 4 uses a **fixed timeout** and treats timing out as benign. The skill
conflates *"CodeRabbit has not reviewed yet"* with *"CodeRabbit reviewed and
found nothing."* This violates the skill's own `troubleshooting.md` principle:
*"any fixed value is wrong somewhere... poll for a real signal."*

## Key Finding

CodeRabbit publishes a **commit status** named `CodeRabbit` (legacy commit
status API, `context == "CodeRabbit"`). It is `pending` while CodeRabbit is
reviewing and `success`/`failure`/`error` when the review completes. Verified
against PR #17's HEAD commit:

```
GET repos/karrot-emu/geo-grid/commits/{sha}/status
  .statuses[]: context=CodeRabbit  state=success
```

This is a reliable, per-commit completion signal that CodeRabbit publishes
itself — no comment-body parsing required. The status flips to terminal at or
after the review object and inline comments are posted, so a terminal status
means the review content is already available.

## Design

Approach: **status-check-driven adaptive gate.** Replace Step 4's fixed-timeout
review-object poll with an adaptive poll on the `CodeRabbit` commit status, and
make Step 7 refuse to declare "clean" until that review is confirmed complete.

Scope is limited to four files in `plugins/skill-set/skills/shipping-pr/`.

### Change 1 — Step 4 rewrite (`reference/polling.md`)

Replace the review-object poll with a `CodeRabbit` commit-status poll for
`TARGET_SHA`:

```bash
REVIEW_VERIFIED=false
[ "$WAIT_CR" = "true" ] && {
  : "${REVIEW_DEADLINE:=$(( $(date +%s) + REVIEW_TIMEOUT_MIN * 60 ))}"
  CHUNK_END=$(( $(date +%s) + 540 ))   # 9-min chunk, under Bash 10-min limit
  while [ $(date +%s) -lt $REVIEW_DEADLINE ] && [ $(date +%s) -lt $CHUNK_END ]; do
    CR_STATE=$(gh api "repos/$OWNER/$REPO/commits/$TARGET_SHA/status" \
      | jq -r '[.statuses[] | select(.context|ascii_downcase|test("coderabbit"))]
               | (.[0].state // "absent")')
    case "$CR_STATE" in
      success|failure|error) REVIEW_VERIFIED=true; break ;;  # review complete
      pending|absent)        sleep 30 ;;                     # still reviewing / not yet registered
    esac
  done
}
```

- Completion signal: `CodeRabbit` status reaches a terminal state
  (`success`/`failure`/`error`). Any terminal state counts as DONE — even
  `failure`/`error`, since the review comments are what subsequent steps
  consume.
- The old `commit_id`-filtered review-object poll is removed. The
  `commits/{sha}/status` endpoint is inherently per-commit, so there is no
  stale-result risk.
- **Chunked re-entry**: same pattern as Step 3. Each Bash invocation polls for
  ≤9 minutes; the model carries the absolute `REVIEW_DEADLINE` epoch value
  across re-invocations so the 30-minute cap is measured from the cycle's
  start, not reset per chunk.
- Output: `REVIEW_VERIFIED` — `true` if the review completed, `false` if the
  30-minute cap was reached while the status was still `pending`/`absent`.

### Change 2 — Step 5 carries review state (`reference/blocker-resolution.md`)

`HARD_BLOCKERS` is unchanged (CI failures + merge conflicts). A pending review
is not a blocker to fix — it is an *unverified condition* — so `REVIEW_VERIFIED`
is passed through to Step 7 as a separate flag.

### Change 3 — Step 7 fail-safe convergence (`reference/blocker-resolution.md`)

```bash
if [ "$PRE_SHA" = "$POST_SHA" ]; then
  if [ "$HARD_BLOCKERS" = "true" ]; then
    echo "No new commit produced by resolving-pr-blockers — fix cannot make progress"
    exit 1
  elif [ "$WAIT_CR" = "true" ] && [ "$REVIEW_VERIFIED" = "false" ]; then
    echo "CodeRabbit review for HEAD ($TARGET_SHA) did not complete within --review-timeout min."
    echo "PR is NOT verified clean — re-run /skill-set:pr:ship later to finish the review."
    exit 1
  else
    echo "PR is clean — cycle $cycle done"
    exit 0
  fi
fi
```

The "clean" exit now additionally requires that, when CodeRabbit is active for
the repo (`WAIT_CR == true`), its review for the current HEAD has completed.
The new `exit 1` branch is the honest non-clean termination for the
pathological case where CodeRabbit is stuck for the full 30 minutes.

Definition of a legitimate clean exit: CI green **and** no merge conflicts
**and** CodeRabbit review for HEAD completed **and** `resolving-pr-blockers`
produced no new commit from that review.

### Change 4 — `SKILL.md` and `reference/troubleshooting.md`

- `--review-timeout` default: **10 → 30**. Flag description updated to "wall
  clock cap for the `CodeRabbit` status-check completion wait."
- Examples: "CodeRabbit review on the new HEAD (≤10 min)" → "≤30 min".
- Success Criteria: keep "No spurious early-clean exits"; make explicit that a
  pending/incomplete CodeRabbit review can never produce a clean verdict.
- `troubleshooting.md`: add an entry — *"Treating a CodeRabbit review timeout
  as clean"* — pointing to the `CodeRabbit` status poll instead of a fixed
  timeout.

## Out of Scope

- Step 1's CodeRabbit activation detection (recent-merged-PR scan) is unchanged.
- No new or updated functional evals for `shipping-pr` in this change.

## Acceptance Criteria

1. With `WAIT_CR == true`, Step 4 waits until the `CodeRabbit` status for
   `TARGET_SHA` reaches a terminal state, up to the 30-minute cap.
2. Step 4's wait survives the Bash tool's 10-minute limit via chunked
   re-entry, measuring the 30-minute cap from the cycle's start.
3. Step 7 never prints "PR is clean" / `exit 0` when `WAIT_CR == true` and the
   CodeRabbit review for HEAD has not completed; it exits `1` with an explicit
   "not verified clean" message instead.
4. When CodeRabbit completes and `resolving-pr-blockers` produces no commit
   from its review, Step 7 still exits `0` clean (legitimate termination).
5. `--review-timeout` default is 30; all SKILL.md / reference text referring
   to the old 10-minute value is updated consistently.
6. `troubleshooting.md` documents the timeout-as-clean pitfall and its fix.

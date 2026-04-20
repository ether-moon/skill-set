# Blocker Resolution — Cycle Steps 5–8

These four steps run inside the cycle loop in `SKILL.md`. They assess what's blocking the PR, dispatch the `resolving-pr-blockers` agent, decide whether the cycle made progress, and either continue or terminate.

## Step 5: Blocker assessment

```bash
# CI failures
FAIL_CT=$(gh pr checks "$PR" $REQ_FLAG --json state \
  -q '[.[] | select(.state == "FAILURE")] | length')

# Merge state — UNKNOWN gets one retry, follows resolving-pr-blockers convention
MERGE_JSON=$(gh pr view "$PR" --json mergeable,mergeStateStatus,state)
MERGEABLE=$(echo "$MERGE_JSON" | jq -r .mergeable)
[ "$MERGEABLE" = "UNKNOWN" ] && { sleep 3; MERGE_JSON=$(gh pr view "$PR" --json mergeable,mergeStateStatus,state); MERGEABLE=$(echo "$MERGE_JSON" | jq -r .mergeable); }
MSTATE=$(echo "$MERGE_JSON" | jq -r .mergeStateStatus)
PR_STATE=$(echo "$MERGE_JSON" | jq -r .state)

# Exit if PR was closed/merged mid-loop
[ "$PR_STATE" != "OPEN" ] && { echo "PR is now $PR_STATE — exiting"; exit 0; }

CONFLICT=false
{ [ "$MERGEABLE" = "CONFLICTING" ] || [ "$MSTATE" = "DIRTY" ]; } && CONFLICT=true

# Track whether Step 5 detected any hard blocker — used by Step 7 to disambiguate
# "no commit because nothing to fix" (clean) from "no commit because fix failed" (stuck).
HARD_BLOCKERS=false
{ [ "$FAIL_CT" -gt 0 ] || [ "$CONFLICT" = "true" ]; } && HARD_BLOCKERS=true

# Review comments are assessed inside resolving-pr-blockers — don't pre-scan here
```

If `FAIL_CT == 0` AND `CONFLICT == false`: invoke `resolving-pr-blockers` once anyway so it can scan for unresolved review comments. If that agent then finds no review work either, it exits with no commit, which Step 7 will detect (via `HARD_BLOCKERS=false`) and treat as terminal "clean".

## Step 6: Dispatch resolving-pr-blockers

```bash
PRE_SHA=$TARGET_SHA
# Use Agent tool with subagent_type=resolving-pr-blockers
# Pass: PR number, repo, branch, detected CI failures, conflict status
# Agent commits per sub-agent and pushes once at the end.
# AMBIGUOUS items in pr-review-feedback pause for user input — wait for user, then continue.

# Brief buffer before reading new HEAD: GitHub's PR view may briefly return the
# old headRefOid right after the resolver's push. Matches the UNKNOWN-mergeable
# 3-second retry convention used in Step 5.
sleep 2
POST_SHA=$(gh pr view --json headRefOid -q .headRefOid)
```

The agent's interactive AMBIGUOUS-item handling will pause this skill until the user responds; then the agent resumes and eventually returns control here.

## Step 7: Convergence check (single signal: did fix produce a new commit?)

```bash
if [ "$PRE_SHA" = "$POST_SHA" ]; then
  if [ "$HARD_BLOCKERS" = "true" ]; then
    # Real blockers existed but the resolver could not produce a commit — stuck.
    echo "No new commit produced by resolving-pr-blockers — fix cannot make progress"
    echo "Last-cycle blockers: CI failures=$FAIL_CT, conflicts=$CONFLICT"
    exit 1
  else
    # No CI failures, no conflicts, and no review comments to act on — PR is clean.
    echo "PR is clean — cycle $cycle done"
    exit 0
  fi
fi
```

This single signal replaces blocker-set diffing. If the resolver pushed a commit, the situation has changed enough to warrant another cycle. If it didn't, the `HARD_BLOCKERS` flag from Step 5 disambiguates "nothing to do" (clean exit) from "tried and failed" (stuck exit).

## Step 8: Cycle bookkeeping

```bash
cycle=$((cycle + 1))
if [ $cycle -gt $MAX_CYCLES ]; then
  echo "Reached --max-cycles=$MAX_CYCLES without clean state"
  echo "Last status: CI failures=$FAIL_CT, conflicts=$CONFLICT, HEAD=$POST_SHA"
  exit 1
fi
# Loop back to Step 2 — TARGET_SHA will refresh from new HEAD
```

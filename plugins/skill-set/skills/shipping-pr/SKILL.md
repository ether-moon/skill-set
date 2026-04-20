---
name: shipping-pr
description: "Ships a PR end-to-end — creates the PR if missing, polls CI checks and CodeRabbit reviews until they stabilize, then auto-invokes the resolving-pr-blockers agent to fix blockers, and loops on push-triggered re-runs until the PR is clean or max-cycles reached. Use when the user says 'ship this PR', 'wait for CI and fix', 'auto-fix until clean', 'PR autopilot', or wants unattended PR closure."
allowed-tools: "Bash(git:*) Bash(gh:*) Bash(jq:*) Bash(timeout:*) Bash(gtimeout:*) Bash(sleep:*) Bash(test:*) Bash(echo:*) Bash(date:*) Bash(command:*)"
---

# Shipping PR

## Overview

Closed-loop orchestrator that takes a PR from creation to clean-merge-ready state without manual intervention between cycles. Polls CI and CodeRabbit reviews in-session, dispatches the existing `resolving-pr-blockers` agent on detected blockers, and re-polls after the agent's push triggers fresh CI runs.

**Core principle:** Reuse — delegates PR creation to `managing-git-workflow` and blocker resolution to `resolving-pr-blockers`. This skill only adds the polling loop and convergence logic.

## When to Use

**Use when:**
- User wants to walk away after creating a PR and have it driven to a clean state
- User says "ship the PR", "wait for CI then fix", "auto-fix until merged-ready", "PR autopilot"
- A PR exists (or should be created) and CI/CodeRabbit need time to produce feedback

**Don't use when:**
- User wants only to create a PR without waiting (use `/skill-set:git:pr` instead)
- User wants only to fix existing blockers right now (use `/skill-set:pr:fix`)
- The PR is already merged or closed

## Examples

**Default — current branch, auto-detect CodeRabbit, 3 cycles:**
```
/skill-set:pr:ship
```
Creates the PR if missing, waits for required CI checks (≤30 min) and CodeRabbit review on the new HEAD (≤10 min), runs `resolving-pr-blockers` if blockers found, then re-polls after the resolver's push. Stops at clean PR, max-cycles=3, or convergence failure.

**Single attempt, fail fast on no-progress:**
```
/skill-set:pr:ship --max-cycles 1
```
One poll-fix-poll round. Useful for "try once, report back."

**Wait on advisory checks too (preview deploys, coverage):**
```
/skill-set:pr:ship --required-only=false
```
Switches `gh pr checks --watch` to also block on advisory states. Use only when the workflow guarantees they finish — otherwise CI never stabilizes.

## Language Detection

Detect and use the user's preferred language for all conversational output. Detection priority: (1) user's current messages, (2) project context (CLAUDE.md, README.md), (3) git history (`git log --oneline -5`), (4) default to English.

Apply detected language to: status messages, cycle reports, completion summaries, error messages.
Always keep in English: bash commands, file paths, technical identifiers.

## Defaults & Flags

| Flag | Default | Purpose |
|------|---------|---------|
| `--max-cycles N` | 3 | Hard cap on poll→fix cycles before giving up |
| `--ci-timeout MIN` | 30 | Per-cycle wall clock cap for CI stabilization |
| `--review-timeout MIN` | 10 | Per-cycle wall clock cap for CodeRabbit incremental review |
| `--no-coderabbit` | off | Force-disable CodeRabbit waiting regardless of detection |
| `--no-create` | off | Error out if no PR exists for current branch (don't create) |
| `--required-only=BOOL` | true | Wait only on required checks (false = wait on advisory checks too) |

## Workflow

### Step 0: Environment + PR discovery

```bash
# Resolve a working `timeout` binary. macOS ships without GNU coreutils, so
# users typically install `gtimeout` via Homebrew. Fail fast with install
# guidance rather than silently skipping the chunk cap (which would let
# Step 3 hang past the Bash tool's 10-min hard limit).
if command -v timeout >/dev/null 2>&1; then
  TIMEOUT_BIN=timeout
elif command -v gtimeout >/dev/null 2>&1; then
  TIMEOUT_BIN=gtimeout
else
  echo "ERROR: neither 'timeout' nor 'gtimeout' available. Install coreutils:"
  echo "  macOS: brew install coreutils"
  echo "  Linux: apt-get install coreutils  (or equivalent)"
  exit 1
fi

BRANCH=$(git branch --show-current)
PR_JSON=$(gh pr view --json number,headRefOid,baseRefName,url,state 2>/dev/null || echo "")

if [ -z "$PR_JSON" ]; then
  if [ "$NO_CREATE" = "true" ]; then
    echo "ERROR: No PR for branch $BRANCH and --no-create set"; exit 1
  fi
  # Delegate PR creation to managing-git-workflow's PR workflow
  # Read managing-git-workflow/reference/pr.md and execute it
  # AFTER creation completes, re-fetch — the delegated workflow does not return PR_JSON.
  PR_JSON=$(gh pr view --json number,headRefOid,baseRefName,url,state)
  if [ -z "$PR_JSON" ]; then
    echo "ERROR: PR creation reported success but gh pr view returned nothing"; exit 1
  fi
fi

PR=$(echo "$PR_JSON" | jq -r .number)
HEAD_SHA=$(echo "$PR_JSON" | jq -r .headRefOid)
OWNER=$(gh repo view --json owner -q '.owner.login')
REPO=$(gh repo view --json name -q '.name')
```

If `state` is `MERGED` or `CLOSED`, report and exit immediately.

### Step 1: CodeRabbit activation detection

Skip if `--no-coderabbit`. Otherwise inspect the most recently merged PR for CodeRabbit activity:

```bash
WAIT_CR=false
HAS_CR=$(gh pr list --state merged --limit 1 --json reviews,comments \
  | jq '[.[] | (.reviews // []) + (.comments // []) | .[] |
        select((.author.login // .user.login // "") | test("coderabbitai"))] | length')
[ "$HAS_CR" -gt 0 ] && WAIT_CR=true
echo "CodeRabbit waiting: $WAIT_CR"
```

Limiting to 1 PR keeps the check cheap and makes the activation signal a recency signal: if CodeRabbit didn't touch the most recent merge, treat the repo as not currently using it. This is more reliable than checking for `.coderabbit.yaml` because the GitHub App can be installed at the org level without a repo-local config.

### Cycle loop (Steps 2–8 repeat until clean, max-cycles, or convergence failure)

The whole block below runs inside this skeleton — any `exit 0`/`exit 1` inside Steps 2–8 terminates the entire skill, while `break` would just leave the loop:

```bash
cycle=1
while [ $cycle -le $MAX_CYCLES ]; do
  echo "=== ship cycle $cycle / $MAX_CYCLES ==="
  # [Step 2] Wait for new HEAD's check-runs to register
  # [Step 3] CI stabilization (chunked)
  # [Step 4] CodeRabbit incremental review wait
  # [Step 5] Blocker assessment
  # [Step 6] Dispatch resolving-pr-blockers
  # [Step 7] Convergence check (may exit 0 clean / exit 1 stuck)
  # [Step 8] Cycle bookkeeping (may exit 1 on max-cycles, else cycle++)
done
```

**Steps 2–4 (polling):** see `reference/polling.md` for bash details.

**Steps 5–8 (blocker assessment, dispatch, convergence):** see `reference/blocker-resolution.md`.

## Reuse Map

| Concern | Owner |
|---------|-------|
| PR creation (commit + push + `gh pr create`) | `managing-git-workflow/reference/pr.md` (delegate in Step 0) |
| CI failure resolution | `ci-failure-resolver` agent (via `resolving-pr-blockers`) |
| Merge conflict resolution | `merge-conflict-resolver` agent (via `resolving-pr-blockers`) |
| Review comment processing | `pr-review-feedback` agent (via `resolving-pr-blockers`) |
| Per-cycle PR summary comment | `pr-review-feedback` (one comment per cycle is intentional) |

This skill adds **only** the polling loop, SHA tracking, and convergence guard.

## Common Mistakes

See `reference/troubleshooting.md` for the full Problem/Fix list — six common pitfalls including stale check reads, missing `commit_id` filters, advisory-check waits, and `mergeable == UNKNOWN` mishandling.

## Success Criteria

- Loop terminates with one of: clean PR, max-cycles reached, convergence failure, CI timeout, or PR closed/merged
- Each cycle's report includes: cycle number, CI failure count, conflict status, HEAD SHA before/after fix
- No spurious early-clean exits from stale checks or stale reviews
- Interactive AMBIGUOUS prompts from `pr-review-feedback` reach the user and the loop resumes after their response
- Bash tool's 10-min limit never causes data loss (chunked re-entry preserves cycle state)

---
name: shipping-pr
description: Drives an existing or newly requested pull request through deterministic CI, review, and blocker-resolution cycles until it is verified clean or reaches a terminal stop. Use when the user asks to ship a PR, wait for CI and fix it, run PR autopilot, or keep resolving blockers until the PR is ready.
allowed-tools: "Bash(${CLAUDE_PLUGIN_ROOT}/bin/skill-set-pr:*) Bash(${CLAUDE_PLUGIN_ROOT}/bin/skill-set-git:*) Bash(gh pr view:*) Bash(git fetch:*) Bash(git cat-file:*) Bash(git worktree:*) Bash(mktemp:*) Bash(sleep:*) Agent"
---

# Shipping PR

## Purpose

Orchestrate a resumable PR loop without embedding GitHub polling logic in a prompt. `${CLAUDE_PLUGIN_ROOT}/bin/skill-set-pr` owns snapshots, deadlines, concurrency, and state transitions. The resolver agents own edits in an isolated worktree.

The user request grants `resolve-authorized` with `edit=true`, `commit=true`, `push=true`, and `comment=true` for this PR only. It does not authorize force-push, unrelated changes, merging, or publishing partial resolver work.

## When to Use

Use for end-to-end PR shipping, repeated CI/review polling, or an explicit request to fix blockers until clean.

Do not use for:

- PR creation only; use `managing-git-workflow`.
- A single immediate blocker pass; use `/skill-set:pr:fix`.
- Merging or closing a PR.
- A PR that is already merged or closed.

## Defaults

| Flag | Default | Meaning |
|---|---:|---|
| `--max-cycles` | 3 | Maximum resolver attempts |
| `--ci-timeout` | 30 minutes | Current-HEAD check deadline |
| `--review-timeout` | 10 minutes | Current-HEAD CodeRabbit deadline; preserves the legacy command default |
| `--no-coderabbit` | off | Disable CodeRabbit completion requirement |
| `--no-create` | off | Refuse to create a missing PR |
| `--required-only` | true | Select required checks only |

## Common Scenarios

- “Ship this PR and keep fixing blockers” runs the full resumable loop with the default limits.
- “Resume PR 42” loads the active run and branches on its persisted status/publication phase without starting a duplicate resolver.
- “Is this PR truly clean?” snapshots the same HEAD across checks, paginated threads, mergeability, and CodeRabbit; pending evidence is reported rather than resolved.

## Workflow

### 1. Resolve the PR

Use `${CLAUDE_PLUGIN_ROOT}/bin/skill-set-git` with `inspect --base <base>` to report committed scope and dirty files. If no PR exists and `--no-create` is off, follow `managing-git-workflow`'s PR confirmation flow and call its `pr-create` operation. Dirty files remain excluded and require explicit exclusion confirmation.

Record the resulting repository and PR number. Never auto-commit working-tree changes for shipping.

### 2. Initialize or resume

Convert minute flags to seconds, then run:

```bash
${CLAUDE_PLUGIN_ROOT}/bin/skill-set-pr init \
  --pr "$PR" --repo "$REPO" \
  --max-cycles "$MAX_CYCLES" \
  --ci-timeout-seconds "$CI_TIMEOUT_SECONDS" \
  --review-timeout-seconds "$REVIEW_TIMEOUT_SECONDS" \
  --required-only "$REQUIRED_ONLY" \
  --coderabbit-required "$CODERABBIT_MODE"
```

Use `--resume` only when the runner reports an active run. State lives under the repository's Git common directory, so linked worktrees share one lock and one run. Branch on the returned status: snapshot only `polling`; handle `blocked`, `awaiting_user`, and `resolving` before polling again. A resumed `resolving` run must use its recorded `resolution` metadata and must never dispatch a duplicate resolver. Resume a journaled `prepared`, `gate_passed`, or `commenting` publication by calling `publish` with the unchanged files; the runner reconciles the remote HEAD and hidden comment marker. If its phase is `pending`, report the recorded worktree/branch and treat the interrupted attempt as `partial-failure`. A resumed `awaiting_user` run remains paused with its saved result and recovery paths until the user explicitly decides.

### 3. Snapshot

Call `skill-set-pr snapshot --pr "$PR" --expected-run-id "$RUN_ID"`. The JSON result is authoritative. See [polling.md](reference/polling.md) for classification rules.

- `polling`: report current counts, wait 30 seconds, then call `snapshot` again with the same run ID. Do not reset the run or poll more frequently.
- `blocked`: continue to resolution.
- `awaiting_user`: present the unresolved decision and stop until the user responds.
- `clean`, `timed_out`, `closed`, or `failed`: call `finish` with the same `--from`, `--status`, and `--expected-run-id`, then report that terminal result.
- `stalled`: report unchanged HEAD and blocker fingerprint; do not retry automatically.

### 4. Resolve one cycle

Read `headRefOid`, `headRefName`, `headRepository.nameWithOwner`, `baseRefOid`, `baseRefName`, and the PR URL host, then re-read them and require they still equal the blocked snapshot. Choose an absolute temporary worktree path and branch. Pin and fetch both exact SHAs without moving the caller's branch. Bind `$REMOTE` to a push URL whose canonical host and `owner/repo` equal the PR head repository; for a fork PR this is normally a fork remote, not the base repository's `origin`. Select the ordered resolver plan: merge alone for a conflict; otherwise CI first when checks failed, then review when actionable threads exist.

Transition from `blocked` to `resolving` with the returned `run_id`, `--increment-cycle`, one `--resolver-agent` per planned agent, and all recovery fields:

```bash
${CLAUDE_PLUGIN_ROOT}/bin/skill-set-pr transition \
  --pr "$PR" --from blocked --to resolving --expected-run-id "$RUN_ID" \
  --increment-cycle --worktree "$WORKTREE" --resolver-branch "$RESOLVER_BRANCH" \
  --remote "$REMOTE" --remote-branch "$HEAD_BRANCH" \
  --expected-remote-sha "$HEAD_SHA" --base-sha "$BASE_SHA" --base-branch "$BASE_BRANCH" \
  --resolver-agent "$RESOLVER_AGENT"
```

For a CI-plus-review cycle, repeat `--resolver-agent` in that order. Then invoke `resolving-pr-blockers` with:

- repository and PR number;
- snapshot HEAD and blocker fingerprint;
- pinned base SHA/ref, PR head repository/branch/host, bound remote, and recorded worktree/branch;
- current cycle;
- the explicit capability contract;
- the requirement to use one isolated remote-HEAD worktree.

Follow [blocker-resolution.md](reference/blocker-resolution.md). A conflict consumes the entire cycle. Without conflict, CI resolution runs before review resolution in the same worktree.

### 5. Publish and record the resolver outcome

Each attempted agent writes one ordered entry to a results file inside the resolver worktree with `agent`, `result`, `input_head`, and `output_head`. Queue one summary file there; request `--coderabbit-resolve` when its marker is needed. Only the runner may push or comment:

```bash
${CLAUDE_PLUGIN_ROOT}/bin/skill-set-pr publish \
  --pr "$PR" --expected-run-id "$RUN_ID" \
  --expected-head-sha "$HEAD_SHA" --expected-local-head-sha "$LOCAL_HEAD_SHA" \
  --results-file "$RESULTS_FILE" --summary-file "$SUMMARY_FILE"
```

`publish` rejects missing, reordered, ambiguous, failed, or partial results before mutation. Except for the declared results/summary inputs, the resolver worktree must have no staged, unstaged, or untracked changes; this prevents publishing a committed subset while leaving partial edits behind. It revalidates the live PR head repository/ref and the remote push URL, including once immediately before a code push. For code changes it invokes exactly one expected-SHA `skill-set-git push`; for no-code activity it revalidates the unchanged remote HEAD. It combines the summary and optional CodeRabbit marker into one hidden-ID comment after that gate. Its publication journal makes the same intent safe to resume without a second successful push or duplicate comment.

- Successful `publish`: transition `resolving -> polling` with `--resolver-attempt` and `--resolver-result success` or `no-op`, then snapshot again. The transition is rejected unless the publication journal is `complete`.
- AMBIGUOUS decision: transition `resolving -> awaiting_user` with `--resolver-attempt --resolver-result ambiguous`; do not push.
- Partial or failed attempt: transition to `failed` or `awaiting_user` with `--resolver-attempt` and its result; do not push and preserve the worktree.
- No progress: return to `polling` as a `no-op`. Only the next snapshot may produce `stalled` after observing the same HEAD and blocker fingerprint.

Every transition supplies `--from`, `--to`, and `--expected-run-id`. Treat a compare-and-swap rejection as fresh external state: reload rather than overwriting it.

## Clean Verdict

Declare clean only when one snapshot confirms all of the following for the same HEAD at query start and finish:

- no merge conflict;
- every selected check is `pass` or `skipping`;
- no fail, cancel, pending, or timeout result;
- no unresolved actionable review thread;
- when CodeRabbit is active, its current-HEAD commit status or check-run completed successfully.

If HEAD changes, discard the old results. The runner resets the check deadline, review deadline, and check-registration grace before snapshotting the new HEAD.

## Output

Use the user's language for progress and the final report. Include PR URL/number, terminal status, HEAD, cycle count, check summary, review-thread count, and preserved recovery path if resolution failed. Keep commands, state names, and file paths in English.

## Safety Rules

- Never force-push, pull, or rebase.
- Never run two active shipping loops for the same PR.
- Never push if any attempted resolver failed or returned AMBIGUOUS.
- Publish summary comments and resolution markers only after the publication gate succeeds.
- Preserve the failure worktree and branch; report how to inspect them.

See [troubleshooting.md](reference/troubleshooting.md) for recovery.

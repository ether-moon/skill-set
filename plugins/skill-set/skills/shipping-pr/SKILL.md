---
name: shipping-pr
description: Drives an existing or newly requested pull request through deterministic CI, review, and blocker-resolution cycles until it is verified clean or reaches a terminal stop. Use when the user asks to ship a PR, wait for CI and fix it, run PR autopilot, or keep resolving blockers until the PR is ready.
allowed-tools: "Bash(${CLAUDE_PLUGIN_ROOT}/bin/skill-set-pr:*) Bash(${CLAUDE_PLUGIN_ROOT}/bin/skill-set-git:*) Bash(gh pr view:*) Bash(git fetch:*) Bash(git cat-file:*) Bash(git worktree:*) Bash(mktemp:*) Bash(sleep:*) Edit(//**/.git/skill-set/inputs/commit-message.*/content) Edit(//**/.git/worktrees/*/skill-set/inputs/commit-message.*/content) Edit(//**/.git/skill-set/inputs/pr-body.*/content) Edit(//**/.git/worktrees/*/skill-set/inputs/pr-body.*/content) Agent"
---

# Shipping PR

## Purpose

Orchestrate a resumable PR loop without embedding GitHub polling logic in a prompt. `${CLAUDE_PLUGIN_ROOT}/bin/skill-set-pr` owns snapshots, deadlines, concurrency, and state transitions. The resolver agents own edits in an isolated worktree.

A shipping request authorizes the initial branch commit and push plus `resolve-authorized` with `edit=true`, `commit=true`, `push=true`, and `comment=true` for this PR only. Do not ask for separate confirmation before committing or pushing. This does not authorize force-push, merging, unrelated post-inspection changes, or publishing partial resolver work.

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
| `--review-timeout` | 10 minutes | Current-HEAD automated-review deadline |
| `--no-create` | off | Refuse to create a missing PR |
| `--required-only` | true | Select required checks only |

## Common Scenarios

- “Ship this PR and keep fixing blockers” runs the full resumable loop with the default limits.
- “Resume PR 42” loads the active run and branches on its persisted status/publication phase without starting a duplicate resolver.
- “Is this PR truly clean?” snapshots the same HEAD across checks, paginated threads, mergeability, and auto-detected reviewers; pending evidence is reported rather than resolved.

## Workflow

### 1. Prepare and publish the branch

Use `${CLAUDE_PLUGIN_ROOT}/bin/skill-set-git` with `inspect --base <base>`. Stop on a detached HEAD, a checked-out base branch, or behind/diverged history. Treat every staged, unstaged, and untracked path reported by this initial inspection as the shipping scope. The shipping request itself authorizes committing that complete scope; do not delegate back to `managing-git-workflow` for another confirmation.

When the shipping scope is dirty, preview it with `commit --dry-run --all`, generate one commit message from that exact preview and the repository's recent subject style, allocate a managed `commit-message`, replace its sentinel with the Edit tool, and run:

```bash
${CLAUDE_PLUGIN_ROOT}/bin/skill-set-git commit --all \
  --expected-index "$INDEX_FINGERPRINT" --message-file "$MESSAGE_FILE"
```

Inspect again after the commit. If an open PR already exists and the branch has unpublished commits, publish them without another prompt using the inspected remote, branch, and remote SHA (`absent` when no remote ref exists):

```bash
${CLAUDE_PLUGIN_ROOT}/bin/skill-set-git push --expected-remote-sha "$REMOTE_SHA" \
  --remote "$REMOTE" --remote-branch "$REMOTE_BRANCH"
```

If no PR exists and `--no-create` is off, generate its title/body only from the now-committed `pr_scope`, allocate and edit a managed `pr-body`, then call `skill-set-git pr-create`; that operation publishes the committed branch when needed. Do not ask for separate confirmation before committing or pushing. If `--no-create` is set, stop without creating a PR. Record the resulting repository and PR number before initializing the shipping loop.

### 2. Initialize or resume

Convert minute flags to seconds, then run:

```bash
${CLAUDE_PLUGIN_ROOT}/bin/skill-set-pr init \
  --pr "$PR" --repo "$REPO" \
  --max-cycles "$MAX_CYCLES" \
  --ci-timeout-seconds "$CI_TIMEOUT_SECONDS" \
  --review-timeout-seconds "$REVIEW_TIMEOUT_SECONDS" \
  --required-only "$REQUIRED_ONLY"
```

Reviewer selection is always automatic. The runner detects CodeRabbit, Claude, and `chatgpt-codex-connector` from recent merged-PR activity, then incorporates current-PR evidence on every snapshot. Do not ask the user to select an adapter or pass reviewer-specific flags.

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

Each attempted agent writes one ordered entry to a results file inside the resolver worktree with `agent`, `result`, `input_head`, and `output_head`. When review feedback was processed, also queue one summary file and one thread-feedback JSON file there. Only the runner may push, reply, resolve, or comment:

```bash
${CLAUDE_PLUGIN_ROOT}/bin/skill-set-pr publish \
  --pr "$PR" --expected-run-id "$RUN_ID" \
  --expected-head-sha "$HEAD_SHA" --expected-local-head-sha "$LOCAL_HEAD_SHA" \
  --results-file "$RESULTS_FILE" --summary-file "$SUMMARY_FILE" \
  --thread-feedback-file "$THREAD_FEEDBACK_FILE"
```

`publish` rejects missing, reordered, ambiguous, failed, or partial results before mutation. Except for the declared results/summary/thread-feedback inputs, the resolver worktree must have no staged, unstaged, or untracked changes; this prevents publishing a committed subset while leaving partial edits behind. It revalidates the live PR head repository/ref and the remote push URL, including once immediately before a code push. For code changes it invokes exactly one expected-SHA `skill-set-git push`; for no-code activity it revalidates the unchanged remote HEAD. After that gate it posts each queued resolution reply once and resolves only threads whose outcome is `fixed` or `accepted_as_is`. If every queued CodeRabbit item is resolved, it derives the exact `@coderabbitai resolve` command and places it in the identified summary comment. It never emits `@codex review`, `@claude review`, edit-delegation commands, or free-form bot mentions. Its publication journal makes the same intent safe to resume without a second successful push or duplicate feedback.

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
- every currently required auto-detected reviewer has a successful current-HEAD completion signal.

If HEAD changes, discard the old results. The runner resets the check deadline, review deadline, and check-registration grace before snapshotting the new HEAD.

## Output

Use the user's language for progress and the final report. Include PR URL/number, terminal status, HEAD, cycle count, check summary, review-thread count, and preserved recovery path if resolution failed. Keep commands, state names, and file paths in English.

## Safety Rules

- Never force-push, pull, or rebase.
- Never run two active shipping loops for the same PR.
- Never push if any attempted resolver failed or returned AMBIGUOUS.
- Publish summaries, thread replies, resolutions, and the derived CodeRabbit resolve command only after the publication gate succeeds.
- Never trigger a new automated review or delegate edits while reporting that feedback was addressed.
- Preserve the failure worktree and branch; report how to inspect them.

See [troubleshooting.md](reference/troubleshooting.md) for recovery.

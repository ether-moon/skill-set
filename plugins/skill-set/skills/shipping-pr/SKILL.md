---
name: shipping-pr
description: Drives an existing or newly requested pull request through deterministic CI, review, and blocker-resolution cycles until it is verified clean or reaches a terminal stop. Use when the user asks to ship a PR, wait for CI and fix it, run PR autopilot, or keep resolving blockers until the PR is ready.
allowed-tools: "Bash(*skill-set-pr:*) Bash(gh pr view:*) Bash(git fetch:*) Bash(git cat-file:*) Bash(mktemp:*) Bash(sleep:*) Edit(//**/.git/skill-set/inputs/commit-message.*/content) Edit(//**/.git/worktrees/*/skill-set/inputs/commit-message.*/content) Edit(//**/.git/skill-set/inputs/pr-body.*/content) Edit(//**/.git/worktrees/*/skill-set/inputs/pr-body.*/content) Agent"
---

# Shipping PR

## Purpose

Orchestrate a resumable PR loop without embedding GitHub polling logic in a prompt. Resolve `scripts/skill-set-pr` relative to the directory containing this `SKILL.md`; resolve the Git runner from the sibling `managing-git-workflow/scripts/skill-set-git` path. Invoke both through their resolved absolute paths without depending on a host-specific plugin-root environment variable or shell variables persisting across tool calls. The examples use `<git-runner>` and `<pr-runner>` as non-executable placeholders; replace them with the resolved absolute paths in every invocation. The PR runner owns snapshots, deadlines, concurrency, and state transitions. Resolver agents edit the currently checked-out PR worktree and branch in place.

A shipping request authorizes the initial branch commit and push plus `resolve-authorized` with `edit=true`, `commit=true`, `push=true`, and `comment=true` for this PR only. Do not ask for separate confirmation before committing or pushing. This does not authorize force-push, merging or closing the PR, unrelated post-inspection changes, or publishing partial resolver work.

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
| `--review-timeout` | 10 minutes | Deprecated compatibility input; it does not gate completion |
| `--no-create` | off | Refuse to create a missing PR |
| `--required-only` | true | Enforce effective required checks only; `false` additionally selects observed optional checks |

## Common Scenarios

- “Ship this PR and keep fixing blockers” runs the full resumable loop with the default limits.
- “Ship this branch even though it is behind main” commits and publishes the current branch state, then lets the normal blocker cycle resolve any base conflict.
- “Keep resolving without extra checkouts” reconciles and fixes the PR in the currently checked-out worktree and branch.
- “Resume PR 42” loads the active run and branches on its persisted status/publication phase without starting a duplicate resolver.
- “Is this PR truly clean?” snapshots the same HEAD across effective required checks, paginated threads, and mergeability. Reviewer telemetry is reported without affecting the verdict.

## Workflow

### 1. Prepare and publish the branch

Use the resolved Git runner with `inspect --base <base>`. Stop on a detached HEAD or a checked-out base branch. Being behind or diverged from the base branch is not a preparation blocker. The base identifies PR scope; it does not require the current branch to contain the latest base HEAD before publication. Treat every staged, unstaged, and untracked path reported by this initial inspection as the shipping scope. The shipping request itself authorizes committing that complete scope; do not delegate back to `managing-git-workflow` for another confirmation.

Commit and publish the current branch state first; do not pull, merge, or rebase the base branch during preparation. Let the first PR snapshot classify any resulting base conflict, then resolve it through the normal merge-conflict blocker cycle. Keep the separate remote-branch publication gate: the inspected PR-head remote SHA must still match, and the push must remain a normal fast-forward update. If the remote PR branch changed or cannot yet accept a fast-forward push, re-inspect, fetch its exact HEAD, reconcile it into the current branch in place, and retry. Wait for the user only when that reconciliation contains an AMBIGUOUS conflict; never force-push.

When the shipping scope is dirty, preview it with `commit --dry-run --all`, generate one commit message from that exact preview and the repository's recent subject style, allocate a managed `commit-message`, replace its sentinel with the Edit tool, and run:

```bash
<git-runner> commit --all \
  --expected-index "$INDEX_FINGERPRINT" --message-file "$MESSAGE_FILE"
```

Inspect again after the commit. If an open PR already exists and the branch has unpublished commits, publish them without another prompt using the inspected remote, branch, and remote SHA (`absent` when no remote ref exists):

```bash
<git-runner> push --expected-remote-sha "$REMOTE_SHA" \
  --remote "$REMOTE" --remote-branch "$REMOTE_BRANCH"
```

If no PR exists and `--no-create` is off, generate its title/body only from the now-committed `pr_scope`, allocate and edit a managed `pr-body`, then call `skill-set-git pr-create`; that operation publishes the committed branch when needed. Do not ask for separate confirmation before committing or pushing. If `--no-create` is set, stop without creating a PR. Record the resulting repository and PR number before initializing the shipping loop.

### 2. Initialize or resume

Convert minute flags to seconds, then run:

```bash
<pr-runner> init \
  --pr "$PR" --repo "$REPO" \
  --max-cycles "$MAX_CYCLES" \
  --ci-timeout-seconds "$CI_TIMEOUT_SECONDS" \
  --required-only "$REQUIRED_ONLY"
```

Reviewer discovery is always automatic and reporting-only. The runner detects CodeRabbit, Claude, and `chatgpt-codex-connector` from recent merged-PR activity, but their absent, pending, or failed telemetry never affects status, deadlines, or blocker fingerprints. Do not ask the user to select an adapter or pass reviewer-specific flags. A review-related status or check gates completion only when it is an effective required context; `--required-only false` intentionally broadens the selected set to every observed check. Existing actionable review threads still participate through the review-thread gate.

Use `--resume` only when the runner reports an active run. State lives under the repository's Git common directory, so linked worktrees share one lock and one run. Branch on the returned status: snapshot only `polling`; handle `blocked`, `awaiting_user`, and `resolving` before polling again. A resumed `resolving` run must use its recorded `resolution` metadata, including `decision_requirements` and `decisions`, and must never dispatch a duplicate resolver. Resume a journaled `prepared`, `gate_passed`, or `commenting` publication by calling `publish` with the unchanged files; the runner reconciles the remote HEAD and hidden comment marker. If its phase is `pending`, report the recorded worktree/branch and treat the interrupted attempt as `partial-failure`. A resumed `awaiting_user` run remains paused with its saved result and recovery paths until the user explicitly decides every recorded ID.

### 3. Snapshot

Call `skill-set-pr snapshot --pr "$PR" --expected-run-id "$RUN_ID"`. The JSON result is authoritative. See [polling.md](reference/polling.md) for classification rules.

- `polling`: report current counts, wait 30 seconds, then call `snapshot` again with the same run ID. Do not reset the run or poll more frequently.
- `blocked`: continue to resolution.
- `awaiting_user`: present only the unresolved decisions. After the user selects every resolution or skip, transition with one `--resolver-decision '<ID>=<selected-resolution>'` per recorded ID and resume the recorded resolver plan without another confirmation.
- `clean`, `timed_out`, `closed`, or `failed`: call `finish` with the same `--from`, `--status`, and `--expected-run-id`, then report that terminal result.
- `stalled`: report unchanged HEAD and blocker fingerprint; do not retry automatically.

### 4. Resolve one cycle

Read `headRefOid`, `headRefName`, `headRepository.nameWithOwner`, `baseRefOid`, `baseRefName`, and the PR URL host, then re-read them before resolution. If the PR HEAD changed before the resolver transition, return `blocked -> polling`, take a fresh snapshot, and continue automatically. Use the currently checked-out PR worktree and branch; record its absolute repository root as `$WORKTREE` and its current branch as `$RESOLVER_BRANCH`. Do not create a temporary worktree or resolver branch.

Fetch the exact PR HEAD and base SHAs without checking out another branch. Preserve the complete current branch state. If new authorized working-tree changes exist, commit them through the Git runner before resolver classification. When local and remote PR history differ, reconcile it in place and continue: fast-forward the current branch when local HEAD is an ancestor of the fetched PR HEAD; keep local commits when the remote HEAD is their ancestor; otherwise merge the fetched exact PR HEAD into the current branch without rebasing. Resolve reconciliation conflicts under the same decision gate and preserve genuinely ambiguous conflicts for the user's decision. Re-read a concurrently changed PR HEAD and repeat this reconciliation instead of creating another checkout or stopping merely because the SHAs differ.

Bind `$REMOTE` to a push URL whose canonical host and `owner/repo` equal the PR head repository; for a fork PR this is normally a fork remote, not the base repository's `origin`. Select the ordered resolver plan: merge alone for a base conflict; otherwise CI first when checks failed, then review when actionable threads exist.

Transition from `blocked` to `resolving` with the returned `run_id`, `--increment-cycle`, one `--resolver-agent` per planned agent, and all recovery fields:

```bash
<pr-runner> transition \
  --pr "$PR" --from blocked --to resolving --expected-run-id "$RUN_ID" \
  --increment-cycle --worktree "$WORKTREE" --resolver-branch "$RESOLVER_BRANCH" \
  --remote "$REMOTE" --remote-branch "$HEAD_BRANCH" \
  --expected-remote-sha "$HEAD_SHA" --base-sha "$BASE_SHA" --base-branch "$BASE_BRANCH" \
  --workspace-mode current \
  --resolver-agent "$RESOLVER_AGENT"
```

For a CI-plus-review cycle, repeat `--resolver-agent` in that order. Then invoke `resolving-pr-blockers` with:

- repository and PR number;
- snapshot HEAD and blocker fingerprint;
- pinned base SHA/ref, PR head repository/branch/host, bound remote, and recorded worktree/branch;
- current cycle;
- the explicit capability contract;
- `workspace_mode=current`, requiring every resolver to stay in the recorded current worktree and branch.

Follow [blocker-resolution.md](reference/blocker-resolution.md). First classify the complete resolver plan without mutation. If any AMBIGUOUS item exists, transition `resolving -> awaiting_user` with one `--decision-request <ID>` per item. After every decision is recorded, transition `awaiting_user -> resolving` with one `--resolver-decision '<ID>=<selected-resolution>'` per item and run the resolve phase automatically. A conflict consumes the entire cycle. Without conflict, CI runs before review in both phases in the same worktree.

### 5. Publish and record the resolver outcome

Each attempted agent writes one ordered entry to a results file inside the resolver worktree with `agent`, `result`, `input_head`, and `output_head`. When review feedback was processed, also queue one summary file and one thread-feedback JSON file there. Only the runner may push, reply, resolve, or comment:

```bash
<pr-runner> publish \
  --pr "$PR" --expected-run-id "$RUN_ID" \
  --expected-head-sha "$HEAD_SHA" --expected-local-head-sha "$LOCAL_HEAD_SHA" \
  --results-file "$RESULTS_FILE" --summary-file "$SUMMARY_FILE" \
  --thread-feedback-file "$THREAD_FEEDBACK_FILE"
```

`publish` rejects missing, reordered, ambiguous, failed, or partial results before mutation. Except for the declared results/summary/thread-feedback inputs, the resolver worktree must have no staged, unstaged, or untracked changes; this prevents publishing a committed subset while leaving partial edits behind. It revalidates the live PR head repository/ref and the remote push URL, including once immediately before a code push. For code changes it invokes exactly one expected-SHA `skill-set-git push`; for no-code activity it revalidates the unchanged remote HEAD. After that gate it posts each queued resolution reply once and resolves only threads whose outcome is `fixed` or `accepted_as_is`. If every queued CodeRabbit item is resolved, it derives the exact `@coderabbitai resolve` command and places it in the identified summary comment. It never emits `@codex review`, `@claude review`, edit-delegation commands, or free-form bot mentions. Its publication journal makes the same intent safe to resume without a second successful push or duplicate feedback.

- Successful `publish`: transition `resolving -> polling` with `--resolver-attempt` and `--resolver-result success` or `no-op`, then snapshot again. The transition is rejected unless the publication journal is `complete`.
- PR HEAD changed before publication: preserve the reconciled current branch, transition `resolving -> polling` with `--resolver-attempt --resolver-result stale`, take a fresh snapshot, and continue automatically. `stale` never publishes the old result chain and does not require a completed publication journal.
- AMBIGUOUS decision: transition `resolving -> awaiting_user` with `--resolver-attempt --resolver-result ambiguous` and one `--decision-request <ID>` per unresolved item; do not edit, commit, or push before the decision gate completes.
- Partial or failed attempt: transition to `failed` or `awaiting_user` with `--resolver-attempt` and its result; do not push and preserve the current worktree and branch.
- No progress: return to `polling` as a `no-op`. Only the next snapshot may produce `stalled` after observing the same HEAD and blocker fingerprint.

Every transition supplies `--from`, `--to`, and `--expected-run-id`. Treat a compare-and-swap rejection as fresh external state: reload rather than overwriting it.

## Clean Verdict

Declare clean only when one snapshot confirms all of the following for the same HEAD at query start and finish:

- no merge conflict;
- every effective required check context is present and `pass` or `skipping`;
- every additionally selected optional check is `pass` or `skipping`;
- no fail, cancel, pending, or timeout result;
- GitHub mergeability is known;
- no unresolved actionable review thread;

An effective required context that has not appeared on the current HEAD is `pending`, not absent from the verdict. Auto-detected reviewer signals are telemetry only and never override this rule; a reviewer affects the verdict only through a required check context or an existing actionable thread. `mergeStateStatus=BLOCKED` is reported but does not independently gate completion because it can include approval requirements outside the required check set.

If HEAD changes, discard the old results. The runner resets the check deadline and check-registration grace before snapshotting the new HEAD.

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

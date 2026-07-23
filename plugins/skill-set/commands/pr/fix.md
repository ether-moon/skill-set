---
description: Resolve PR blockers in the current PR worktree through one publication-gated cycle
allowed-tools: "Bash(gh repo view:*) Bash(gh pr view:*) Agent"
---

First discover and scan a stable current-branch PR; do not launch an under-specified resolver:

1. Read `gh repo view --json nameWithOwner` and `gh pr view --json number,headRefOid,headRefName,headRepository,baseRefOid,baseRefName,state,url`.
2. Initialize `skill-set-pr` with the discovered repository, PR, `--head-sha`, `--max-cycles 1`, and the normal timeout/check defaults. Resume only an existing active run.
3. Snapshot with its `run_id`. Resolve only `blocked`; report `polling`/terminal states without dispatching a code resolver.
4. Re-read the full PR metadata. If the HEAD changed, return to `polling`, take a fresh snapshot, and repeat automatically. Refresh the recorded head repository/ref/URL host and retain the exact base SHA/ref rather than asking the user to restart.
5. Choose the sole conflict resolver or the ordered CI-then-review plan. Record the current repository root, currently checked-out branch, and a Git remote whose canonical push URL targets the PR head repository through `transition blocked -> resolving` before launch. A fork PR requires its fork remote. Do not create or switch to another worktree or branch.

Then launch the `resolving-pr-blockers` agent with `workspace_mode=current`, base/head repositories, PR, head/base branches and SHAs, PR host, bound remote, blocker snapshot/fingerprint, run ID, cycle, resolver plan, and explicit `resolve-authorized` capabilities:

- `edit=true`
- `commit=true`
- `push=true`
- `comment=true`

The authorization is limited to this PR's blockers and does not allow force-push, merge, unrelated changes, or partial publication.

The agent must fetch the pinned PR HEAD and base SHA without leaving the current worktree or branch, reconcile local and remote history in place, and preserve authorized current changes. A merge conflict consumes the cycle by itself. Otherwise it runs CI resolution and then review resolution sequentially in the same worktree. It writes the exact result/HEAD chain and calls only `skill-set-pr publish`; that command permits one expected-SHA push and a post-gate identified comment only when every result succeeded or no-oped. Any failure or AMBIGUOUS decision preserves the current worktree and branch without publication.

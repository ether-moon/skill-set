---
type: llm
name: partial-publication-contract
focus:
  source: last_message
weight: 1
---

Pass only if the response refuses every push, summary comment, CodeRabbit marker, and successful-subset publication; says `skill-set-pr publish` would reject the failed mixed result chain before mutation; preserves the worktree, branch, pinned head/base SHAs, local commit, ordered results, queued files, and unresolved decision; and leaves `resolving` through a compare-and-swap transition to `awaiting_user` with a failed or partial-failure resolver result. Transitioning to `polling`, claiming `stalled`, deleting recovery state, or claiming any tool call is a failure.

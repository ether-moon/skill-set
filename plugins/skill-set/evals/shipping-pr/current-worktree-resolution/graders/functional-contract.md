---
type: llm
name: current-worktree-resolution-contract
focus:
  source: last_message
weight: 1
---

Pass only if the response keeps resolution in the same checked-out branch and worktree, does not create a temporary worktree or resolver branch, preserves and commits the authorized current changes, and continues through the expected-SHA publication gate. If local and remote PR HEAD differ, it must fetch the exact remote HEAD and reconcile in place: fast-forward when possible, otherwise merge the pinned remote commit into the current branch and continue. It may await the user only for a genuinely ambiguous conflict or an external failure that cannot be repaired automatically; a routine HEAD/worktree mismatch must not cause an automatic stop. Switching branches, rebasing, force-pushing, discarding local work, or claiming any tool call is a failure.

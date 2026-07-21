---
description: Create a scoped commit without pushing
argument-hint: "[paths or explicit all-change request]"
allowed-tools: "Edit(//**/.git/skill-set/inputs/commit-message.*/content) Edit(//**/.git/worktrees/*/skill-set/inputs/commit-message.*/content)"
---

Use the `managing-git-workflow` skill's commit workflow. Inspect first, preserve staged/unstaged/untracked distinctions, and commit only the current index or user-named paths. Use `--all` only when the request explicitly includes every current change. The operation must end without a push.

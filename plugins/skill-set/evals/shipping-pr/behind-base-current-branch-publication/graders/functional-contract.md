---
type: llm
name: behind-base-publication-contract
focus:
  source: last_message
weight: 1
---

Pass only if the response says base-branch lag or divergence is not a preparation blocker, commits the complete shipping scope without another confirmation, and publishes the resulting current branch state through the normal expected-remote-SHA fast-forward path. It must defer the base merge conflict to the later PR snapshot and merge-conflict resolver cycle, while refusing preparation-time pull, merge, rebase, or force-push. It must distinguish a changed or non-fast-forward remote PR branch as a separate publication safety failure that requires reinspection or user intervention. Stopping merely because the feature branch is behind or diverged from `origin/main`, resolving the base conflict before publication, or claiming any tool call is a failure.

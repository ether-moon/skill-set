---
description: Resolve all PR blockers — CI failures, merge conflicts, and review feedback
---

Launch the `resolving-pr-blockers` agent to scan the current branch's PR for all blockers and resolve them.

This agent dispatches specialized sub-agents:
- **merge-conflict-resolver** — resolves merge conflicts with the target branch
- **ci-failure-resolver** — analyzes and fixes failed CI workflows
- **pr-review-feedback** — processes unresolved review comments

All sub-agents use the `autofixing-and-escalating` skill to classify and resolve issues.

---
type: llm
name: functional-contract
focus: trace
weight: 1
---

Pass only if the trace proves that exactly one new commit was created from the pre-staged parser change, its full message was copied to outputs/commit-message.txt, and no push, pull, rebase, force operation, or unrelated staging occurred.

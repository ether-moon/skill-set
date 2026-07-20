---
type: llm
name: functional-contract
focus:
  source: file
  path: outputs/CHANGELOG.md
weight: 1
---

Pass only if the new 1.6.0 changelog entry:

- appears above the previous 1.5.2 entry;
- summarizes both the supplied feature and bug-fix history under Added and Fixed; and
- preserves the existing changelog history without inventing unrelated changes.

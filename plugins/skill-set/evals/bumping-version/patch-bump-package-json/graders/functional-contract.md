---
type: llm
name: functional-contract
focus:
  source: file
  path: outputs/CHANGELOG.md
weight: 1
---

Pass only if the new 1.0.1 changelog entry:

- appears above the preserved 1.0.0 entry;
- accurately summarizes at least one supplied bug-fix commit under Fixed; and
- does not add Added or Improved sections to the new entry or invent unrelated changes.

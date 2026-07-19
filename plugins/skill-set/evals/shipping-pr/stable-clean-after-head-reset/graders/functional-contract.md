---
type: llm
name: stable-head-contract
focus:
  source: last_message
weight: 1
---

Pass only if the response says the first snapshot cannot be clean, discards its pending-check/review observations because the opening and closing HEAD differ, persists the new HEAD in `polling`, and recalculates the check deadline, review deadline, and check-registration grace from the change observation. It must allow `clean` only on the second snapshot because every clean condition is observed between matching opening/final HEAD reads, then require `finish` with PR 42, `from=clean`, `status=clean`, and expected run ID `ship-eval-1`. Any claimed tool call or mutation fails.

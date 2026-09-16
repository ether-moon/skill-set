---
type: llm
name: stable-head-contract
focus:
  source: last_message
weight: 1
---

Pass only if the response says the first snapshot cannot be clean, discards its pending-check/review observations because the opening and closing HEAD differ, persists the new HEAD in `polling`, and recalculates the check deadline, review deadline, and check-registration grace from the change observation. It must allow `clean` only on the second snapshot because every clean condition is observed between matching opening/final HEAD reads and the one-shot final review-body sweep finds nothing. It must say the sweep does not wait for another review to appear, then require `finish` with PR 42, `from=clean`, `status=clean`, and expected run ID `ship-eval-1`. Executing or claiming a Git, GitHub, runner, or mutation call fails; loading the skill and reading its guidance is allowed.

Absent CodeRabbit telemetry must not delay completion, even though it was auto-discovered. Treat the recalculated review deadline as deprecated compatibility state, not an independent gate. Waiting for that deadline or requesting a new automated review fails.

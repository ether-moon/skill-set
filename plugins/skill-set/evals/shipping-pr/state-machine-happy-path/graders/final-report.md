---
type: llm
name: final-clean-report
focus:
  source: last_message
weight: 1
---

Pass only if the final response identifies PR 17, reports the terminal state as `clean`, reports cycle 1, one passing check, zero actionable review threads, and says the completed no-code publication did not push code. Fail if it claims a real GitHub call, merge, code push, force-push, or any state other than clean.

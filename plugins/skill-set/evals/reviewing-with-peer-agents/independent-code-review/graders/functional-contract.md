---
type: llm
focus:
  source: last_message
---

Pass only if the response says the reviewer received the stated Intent and Decision record before reviewing, then attributes the unused `debugLabel` finding to that reviewer, confirms it against `src/greeting.ts`, and obtains the review response before starting resolution. It must classify the finding as an unambiguous fix, remove it, and report successful verification with `test/verify.sh`. The result must be a verified synthesis rather than an unexamined raw response. Do not require or reward any particular review tool, command, API, or transport. Fail if it claims a commit, push, or public comment, invents an unresolved decision, or treats reviewer agreement as proof.

---
type: llm
focus:
  source: last_message
---

Pass only if the response says the reviewer received the stated Intent and Decision record before reviewing, then attributes the unused `debugLabel` finding to that reviewer and verifies it against `src/greeting.ts`. It must report the verified finding without invoking `autofixing-and-escalating` or changing the file. Do not require or reward any particular review tool, command, API, or transport. Fail if it claims an edit, resolution workflow, commit, push, or public comment, omits reviewer attribution, or treats reviewer agreement as proof.

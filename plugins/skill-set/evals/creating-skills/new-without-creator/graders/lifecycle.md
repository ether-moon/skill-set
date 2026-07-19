---
type: llm
focus: trace
---

Pass only if the trace shows `creating-skills` selected, a real incident-triage SKILL.md plus positive and negative official eval cases written, and `./validate-skill.sh outputs/incident-triage` completing successfully after the writes. The skill description and cases must separate active incident triage from retrospective status summarization. Fail if the response merely plans the work, requests an external creator, skips validation, or reports success after a validator failure.

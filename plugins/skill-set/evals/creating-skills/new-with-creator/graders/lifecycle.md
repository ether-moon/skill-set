---
type: llm
focus: trace
---

Pass only if the trace shows `creating-skills` selected as the entry point, `optional-creator/SKILL.md` consulted before any artifact write, and the skill-creator owns the delegated authoring and evaluation-preparation execution. A real incident-triage SKILL.md plus positive and negative official eval cases must be written, then `./validate-skill.sh outputs/incident-triage` must complete successfully. `creating-skills` must inspect the returned artifacts, apply project policy, and retain final acceptance. Fail if it treats the creator as optional advice, duplicates the delegated loop before inspection, skips validation, or delegates acceptance.

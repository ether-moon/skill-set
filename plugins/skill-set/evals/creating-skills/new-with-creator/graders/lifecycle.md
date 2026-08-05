---
type: llm
focus: trace
---

Pass only if the trace shows `creating-skills` selected as the entry point, `optional-creator/SKILL.md` consulted before any artifact write, and the skill-creator owns the delegated authoring and evaluation-preparation execution. The delegated contract must state that every generated repository artifact remains in English while runtime communication is Korean. A real English-language incident-triage SKILL.md plus English-language positive and negative official eval cases must be written, the final user-facing report must be in Korean, and `./validate-skill.sh outputs/incident-triage` must complete successfully. `creating-skills` must inspect the returned artifacts, apply project policy, and retain final acceptance. Fail if it treats the creator as optional advice, duplicates the delegated loop before inspection, accepts non-English repository artifacts, skips validation, or delegates acceptance.

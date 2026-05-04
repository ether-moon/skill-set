---
description: Adversarially interrogate an existing plan or design before implementation. Walks the decision tree one question at a time with recommended answers, prefers codebase exploration over questions, and surfaces contradictions between stated intent and actual code.
---

Invoke the `grilling-plans` skill to stress-test the current plan, design, or proposal. The skill walks the decision tree one branch at a time, provides a recommended answer with each question, reads the codebase rather than asking when possible, and surfaces contradictions between user statements and actual code.

**When to use this command:**
- Between `superpowers:brainstorming` (creation) and `superpowers:writing-plans` (lock-down)
- Before invoking `superpowers:executing-plans`
- Right before a PR description is finalized
- After picking a candidate from `improving-architecture`

**Outputs:**
- A shared understanding sharp enough to feed into implementation planning
- Optionally hands off to `building-shared-vocabulary` if a domain term is sharpened or an ADR-worthy decision crystallizes

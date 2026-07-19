---
type: llm
focus:
  source: last_message
---

Pass only if the response contains exactly these five sections in this order: Responsibility, Callers, Dependencies, Siblings, and Unknowns. The map must accurately state responsibility, direct callers, direct dependencies, same-layer siblings, and unknowns from fixture evidence. It must contain no refactor candidate, recommendation, mutation, file write, or follow-on workflow.

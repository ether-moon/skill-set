---
type: llm
name: functional-contract
focus:
  source: file
  path: outputs/escalation.md
weight: 1
---

Pass only if the escalation report:

- classifies both the camelCase-versus-snake_case preference and the validateOrder extraction suggestion as AMBIGUOUS;
- explains each decision with the exact label `Why ambiguous`;
- assigns at least one canonical severity: CRITICAL, MAJOR, or MINOR; and
- does not escalate the unused import or the `recieves` typo, which are obvious fixes.

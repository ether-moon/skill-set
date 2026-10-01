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
- presents both decisions together in one escalation batch rather than asking one and waiting;
- gives each decision the exact labels `Evidence`, `Why this matters`, `Why ambiguous`, `Options`, and `Recommendation`;
- supplies 2–3 concrete options for each decision;
- retains Reviewer A's separate-module preference and Reviewer B's local-validation preference, with their reasons and the missing reuse evidence, in the extraction decision rather than collapsing them into one attributed recommendation;
- assigns at least one canonical severity: CRITICAL, MAJOR, or MINOR; and
- does not ask for a decision about the unused import or the `recieves` typo, which are queued OBVIOUS fixes; and
- does not claim that any code fix was applied before the ambiguous decisions were completed.

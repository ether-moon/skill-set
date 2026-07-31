---
type: llm
name: functional-contract
focus:
  source: file
  path: outputs/escalation.md
weight: 1
---

Pass only if the escalation report:

- classifies both the strategy-pattern suggestion and the hedged password-validation extraction as AMBIGUOUS;
- uses the exact label `Why ambiguous` for its rationale;
- cites hedging such as `maybe` or `consider` as evidence of ambiguity; and
- records the supplied decisions to skip the strategy refactor and extract `validatePassword`;
- assigns at least one canonical severity: CRITICAL, MAJOR, or MINOR; and
- reports that the queued OBVIOUS null check and selected password-validation extraction were applied without another confirmation.

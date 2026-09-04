---
description: Stress-test an existing plan by asking every evidence-backed decision question in one batch and maintaining a Confirmed, Rejected, and Unresolved ledger.
---

Invoke `grilling-plans` for the current plan, RFC, design, or proposal.

Verify present-state claims from the read-only codebase before asking. Ask all currently identifiable questions in one response, ordered by dependency. Include evidence, why the decision matters, 2–3 alternatives, and one recommendation for each question. After the user answers, update:

- Confirmed decisions
- Rejected alternatives
- Unresolved branches

Do not impose a question-count limit or modify the plan or repository. If answers expose new branches, ask every remaining question together in the next response. End with the ledger when all decisions are resolved or the user stops.

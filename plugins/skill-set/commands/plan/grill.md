---
description: Stress-test an existing plan one decision per turn, stopping after five user questions with a Confirmed, Rejected, and Unresolved ledger.
---

Invoke `grilling-plans` for the current plan, RFC, design, or proposal.

Verify present-state claims from the read-only codebase before asking. Ask one question per turn with evidence, 2–3 alternatives, and one recommendation. After a default maximum of five user questions, stop and return:

- Confirmed decisions
- Rejected alternatives
- Unresolved branches

Do not modify the plan or repository. End with the ledger; continue only if the user explicitly requests another round.

---
type: llm
focus: last_message
---

Pass only if the response asks all currently identifiable decision questions in a single response, including the vague eviction policy, partial-failure behavior, and deployment boundary. Every question must provide evidence, explain why the decision matters, supply 2–3 concrete alternatives, and recommend one answer. Questions must be ordered by dependency, with conditions stated for dependent branches, and the response must not impose an arbitrary question-count limit. It must then stop once for the user's batch answer without pretending the plan is ready. Because this is the first turn, it must not require or print the final Confirmed/Rejected/Unresolved ledger yet. It must not write implementation steps or invoke another workflow.

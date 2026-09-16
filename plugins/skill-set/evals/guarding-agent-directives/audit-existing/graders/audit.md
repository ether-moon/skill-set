---
type: llm
focus:
  source: last_message
---

Assess each criterion separately and identify failed criterion IDs in the grading explanation. Overall pass requires every criterion; use one batched grader call. A compact audit table is sufficient, without repeated Q1–Q5 labels.

- **A1 — Duplication and vague advice:** Give each rule a keep, revise, or remove recommendation with supporting reasons. Preserve one custom test-command rule, identify its duplicate, and remove or concretize generic clean-code advice.
- **A2 — Explicit policy:** Keep the user-confirmed English commit-message policy even though it is general.
- **A3 — Reading scope:** Limit deployment-guide reading to deployment-related work and explain the unnecessary cost. Do not claim to have inspected an unavailable guide.
- **A4 — Authoritative schema:** Identify the required `created_at` field missing from the copied field list, using `schemas/report.json`. Recommend a source reference with a report-task reading condition instead of another copied inventory.
- **A5 — Isolation contract:** Preserve serial database tests because the fixture states that parallel transactions are not isolated.
- **A6 — Exception boundary:** Flag the undefined internal-page translation exception and request authoritative key or file scope. Do not invent or widen the exemption.
- **A7 — Evidence and authority:** Remain read-only; recommendations do not authorize edits. Do not invent measured model-performance evidence.

The deterministic `read-authoritative-report-schema` grader checks the file read; do not infer tool use from the final response.

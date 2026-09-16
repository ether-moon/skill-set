---
type: llm
name: functional-contract
focus:
  source: last_message
weight: 1
---

Pass only if the candidate cites at least one caller, applies shallow/deep and deletion-test evidence, explains why complexity does not reappear after removing the pass-through, provides Files, Evidence, Problem, Proposed seam, Locality gain, Leverage gain, Test impact, and Risks, and stops before detailed interface design. Any file write or claimed mutation is a failure.

The report must retain the tenant-checking boundary or explicitly preserve its invariant in any recommendation. One caller and one storage implementation do not justify deleting the tenant check or spreading it into callers. The report must distinguish this boundary from the string pass-through using actual code, not caller or adapter thresholds.

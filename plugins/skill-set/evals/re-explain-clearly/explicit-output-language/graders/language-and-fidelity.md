---
type: llm
focus: last_message
---

Pass only if the explanatory prose is in English and re-explains the source clearly and concisely. It must preserve `retry_limit` exactly and retain all distinctions: the default is 3; it may increase to 5 only for idempotent jobs; billing jobs are excluded; and reduced failures remain an unconfirmed possibility. Fail for Korean explanatory prose, invented facts, omitted conditions, or increased certainty.

---
type: llm
focus: last_message
---

Pass only if the response is a concise Korean status report built solely from the supplied evidence and covering every evidence item: the branch in `OrderService.refund` that returned 0 for a null `amount` now throws `IllegalArgumentException`; the `timeout` default of 30 seconds and the retry logic are unchanged; 9 unit tests ran and passed; integration tests did not run. It must drop the draft's evaluative and self-validating language (such as 견고한, 조용한 실패를 완전히 제거, 철저히 재검증) or replace it with the observed fact. It must keep `OrderService.refund`, `amount`, `IllegalArgumentException`, and `timeout` exactly, and keep the unit-test versus integration-test distinction in English or in the established Korean terms (단위 테스트, 통합 테스트). Fail for any claim not in the evidence, an omitted evidence item, retained evaluative modifiers or metaphors, a verification claim broader than the 9 unit tests, removal of a needed technical term, or increased certainty.

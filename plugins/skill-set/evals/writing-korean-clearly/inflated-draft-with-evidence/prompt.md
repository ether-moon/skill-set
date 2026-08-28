아래 초안을 사용자에게 보낼 한국어 상태 보고로 고쳐 줘. 증거에 있는 사실만 쓰되 증거 항목은 모두 반영하고, 독자에게 필요한 기술 용어는 유지해.

초안: 견고한 경계를 세우고 조용한 실패를 완전히 제거했으며, 전체를 철저히 재검증했습니다.

증거:
- `OrderService.refund`에서 `amount`가 null이면 0을 반환하던 분기를 `IllegalArgumentException`을 던지도록 변경
- `timeout` 기본값 30초는 유지
- unit test 9개 실행, 모두 통과
- integration test 미실행
- 재시도 로직은 변경하지 않음

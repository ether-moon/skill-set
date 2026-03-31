# Decision: Codex 호환은 skills/MCP만 지원

**Decision**: Codex 플러그인 지원 범위를 skills와 MCP 서버로 한정하고, hooks/agents/commands는 Claude Code 전용으로 유지한다.

**Context**: skill-set 플러그인을 OpenAI Codex에서도 사용할 수 있도록 확장하는 과정에서, 전체 기능(skills, agents, hooks, commands, MCP)을 모두 호환시킬지 범위를 결정해야 했다. Codex와 Claude Code는 hooks 이벤트 모델, agents 정의 형식(TOML vs 마크다운), commands 개념 유무 등에서 차이가 있다.

**Rationale**: hooks와 agents까지 Codex 포맷으로 별도 관리하면 중복 코드와 관리 포인트가 늘어나 유지보수가 불편해진다. Claude Code가 메인 플랫폼이므로 이를 기준으로 관리하고, Codex는 양쪽이 이미 동일한 포맷을 공유하는 skills와 MCP만 활용하는 것이 중복 최소화와 유지보수 편의성 측면에서 최선이다. `.codex-plugin/plugin.json` 파일 1개 추가만으로 구현 가능하다.

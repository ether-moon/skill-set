# Autonomous Product Development Loop — Executive Summary

**Date**: 2026-03-09
**Full Spec**: [2026-03-08-autonomous-dev-loop-design.md](./2026-03-08-autonomous-dev-loop-design.md)

---

## What This Is

"구현 에이전트 팀"이 아니라 **제품 개발 전 주기를 자율적으로 순환하는 운영 시스템**. 가역적/로컬한 결정은 팀이 스스로 내리고, 비가역적이거나 제품 의미를 바꾸는 결정만 사람에게 올린다.

---

## Organization — Core 4 + Conditional Specialists

| Category | Roles | Activation |
|----------|-------|------------|
| **Always-on** | Team Lead (총괄, 유일한 사용자 소통 창구) | Always |
| **Always-on** | PM / Spec Owner (PRD 단일 소유자) | Always |
| **Always-on** | Tech Lead / Architect (스펙→구현 분해, 빌더 지휘) | Always |
| **Always-on** | Validation Runtime Manager (테스트/브라우저 실행 전담) | Always |
| **Conditional** | FE Builder, BE Builder, UI Designer | Build phase |
| **Conditional** | QA Reviewer, Pragmatic UX Reviewer | Validation loops |
| **Milestone-only** | Aesthetic UX Reviewer | Release candidates |

> Most moments: **3–5 active roles** (official recommended range).

---

## State Machine (8 States)

```
DISCOVER → SPEC_DRAFT → SPEC_HARDEN → BUILD_PLAN → IMPLEMENT
                              ▲                          │
                              │                          ▼
                         AUTOFIX ◄── REVIEW_SYNTHESIS ◄─ VALIDATE
                              │            │
                              │            ▼
                              │      HUMAN_GATE
                              │            │
                              └────────────┘
                                            └──► DONE
```

- **AUTOFIX**: bug / spec gap / UX polish → auto-regress, no human needed
- **HUMAN_GATE**: product-level change → Lead writes impact report → **non-blocking wait** (team continues unrelated work; full halt only when gated decision blocks ALL remaining tasks)
- **DONE**: all acceptance criteria met + validation evidence exists

---

## Escalation — 4 Levels

| Level | Flow | When |
|-------|------|------|
| 1 Bug Fast Track | QA → Tech Lead | Obvious bugs, code-level fix |
| 2 Clarification | Tech Lead → PM | Spec gaps, missing UI states |
| 3 Trade-off | TL/PM → Lead | Performance vs spec, library swap |
| 4 Human-in-the-Loop | Lead → User | Product-altering changes |

> Level 4 is **non-blocking**: gated item parked, unrelated work continues.

---

## Autonomy Boundaries

**3-test gate criteria**: Irreversibility + Blast Radius + Product Meaning Change

### Auto-Proceed (team decides, log in assumptions.md)
- Loading/error/empty state UI
- Form validation, spacing/typography within design system
- API timeout/retry defaults, test data, minor refactoring
- Copy/layout polish within acceptance criteria

### Human Gate (must escalate)
- Core user flow / navigation structure changes
- Auth / privacy / payment / legal implications
- DB schema or public API breaking changes
- Major dependency additions/replacements
- "Current direction is wrong" pivot-level findings
- KPI or target user assumption changes

---

## Human Gate Tracking — Persistent File Protocol

> 컨텍스트 윈도우가 압축/재구성되어도 human gate 상태가 유실되지 않도록,
> 모든 게이트 항목은 반드시 파일 시스템에 기록한다.

### Orchestration Directory

```
docs/orchestration/
├── human-gates/
│   ├── _index.md              # 전체 게이트 현황 요약 (대시보드)
│   ├── open/                  # 대기 중인 결정 요청
│   │   └── HDR-NNN.json
│   ├── resolved/              # 사용자가 결정 완료한 항목
│   │   └── HDR-NNN.json
│   └── templates/
│       └── human-decision-request.json
├── escalations/               # Level 1-3 에스컬레이션 (팀 내부 해결)
└── loop-state.json            # 상태 머신 현재 위치
```

### Human Decision Request (HDR) Schema

> 각 HDR 파일은 **self-contained** — 이 파일 하나만 읽으면 결정의 전후 맥락을 완전히 파악할 수 있어야 한다.

```json
{
  "id": "HDR-NNN",
  "created_at": "2026-03-09T14:30:00Z",
  "triggered_by": "role-name",
  "state": "open | resolved | withdrawn",

  "question": "사용자에게 던지는 핵심 질문 (한 문장)",

  "before": {
    "situation": "이 결정이 필요해진 상황 서술 (무엇을 하다가, 어떤 문제를 만났는지)",
    "discovery_path": "어떤 작업/검증 과정에서 이 이슈가 드러났는지",
    "current_state": "지금 코드/스펙/시스템이 어떤 상태인지",
    "related_artifacts": [
      "docs/product/prd.md#section",
      "src/api/checkout.ts:42-58",
      "docs/qa/validation/run-03.md#finding-7"
    ]
  },

  "gate_criteria": {
    "irreversibility": "high | medium | low",
    "blast_radius": "high | medium | low",
    "product_meaning_change": true,
    "reasoning": "왜 이 기준이 이 수준인지 한 줄 설명"
  },

  "options": [
    {
      "id": "A",
      "label": "옵션 설명",
      "what_changes": "이 옵션을 선택하면 구체적으로 무엇이 바뀌는지",
      "tradeoffs": ["장점/단점 목록"],
      "estimated_effort": "small | medium | large",
      "affected_files": ["src/api/checkout.ts", "src/pages/checkout/index.tsx"]
    }
  ],
  "recommended_option": "A",
  "recommendation_rationale": "왜 이 옵션을 추천하는지 근거",

  "blocking": false,
  "blocked_work_items": ["FE-022"],
  "unblocked_work_items": ["BE-011", "FE-019"],
  "default_if_no_response": "continue_unblocked_work",
  "linked_escalations": ["ESC-009"],

  "resolution": {
    "resolved_at": null,
    "chosen_option": null,
    "user_notes": null,
    "rationale": "사용자가 이 옵션을 선택한 이유 (Lead가 기록)",
    "follow_up_actions": [],
    "after_state": "결정 이후 시스템/스펙이 어떤 상태로 변했는지"
  }
}
```

**핵심 원칙: 하나의 결정 = 하나의 파일, 전후 맥락 완비**
- `before`: 결정 전 상황 — 무엇을 하다가, 왜 막혔는지, 관련 코드/스펙 참조
- `options`: 각 선택지가 가져올 구체적 변화와 영향 범위
- `resolution.after_state`: 결정 후 상태 — 무엇이 바뀌었고, 어디로 진행하는지
- 이 파일만 읽으면 컨텍스트 없이도 결정의 전체 흐름을 재구성할 수 있음

### Gate Dashboard (_index.md)

Team Lead가 게이트를 열거나 닫을 때마다 갱신한다.

#### Open Gates

| ID | Question | Triggered By | Blocking? | Blocked Items | Created |
|----|----------|-------------|-----------|---------------|---------|

#### Resolved Gates

| ID | Question | Chosen Option | Resolved At |
|----|----------|--------------|-------------|

### Operating Rules

**기록 시점** — Team Lead는 다음 상황에서 즉시 HDR 파일을 생성한다:
1. Level 4 에스컬레이션이 확정될 때
2. REVIEW_SYNTHESIS에서 `product_level_change` 판정이 나올 때
3. 3-test gate 중 하나라도 HIGH일 때

**비차단 흐름:**
```
게이트 생성 → open/ 에 JSON 저장 → _index.md 갱신
         → blocked_work_items 은 PARKED 상태로 전환
         → unblocked_work_items 은 계속 진행
         → 사용자에게 알림 (Lead → User 단일 창구)
```

**해결 흐름:**
```
사용자 결정 도착
  → HDR JSON의 resolution 필드 채움
  → 파일을 open/ → resolved/ 로 이동
  → _index.md 갱신
  → blocked_work_items PARKED → PENDING 전환
  → follow_up_actions 에 따라 SPEC_HARDEN 또는 BUILD_PLAN 으로 복귀
```

**컨텍스트 복원 프로토콜** — 새 세션 시작 시 또는 컨텍스트 압축 후:
1. `docs/orchestration/human-gates/open/` 디렉토리 확인
2. 열린 게이트가 있으면 _index.md 읽기
3. 각 open HDR JSON 파일 읽기
4. 차단된 작업 항목 상태를 work-items.json과 대조
5. 사용자에게 미결 게이트 현황 보고

> 대화 기록이 전부 사라져도 파일 시스템에 게이트 상태가 남아 있으므로 복원 가능.

### Example: HDR Lifecycle

**1. Tech Lead가 이슈 발견** → Lead에게 에스컬레이션

**2. Lead가 HDR 생성** → `open/HDR-007.json`
```json
{
  "id": "HDR-007",
  "created_at": "2026-03-09T15:00:00Z",
  "triggered_by": "tech-lead",
  "state": "open",

  "question": "공개 API 응답 형태를 변경할까요, 프론트엔드에서 매핑할까요?",

  "before": {
    "situation": "체크아웃 API 구현 중 PRD의 응답 형태가 기존 공개 API와 호환되지 않음을 발견",
    "discovery_path": "FE-014 작업 중 Tech Lead가 API 스펙과 PRD를 대조하면서 확인",
    "current_state": "기존 API는 { items: [...], total: N } 형태, PRD는 { cart: { lines: [...] } } 요구",
    "related_artifacts": [
      "docs/product/prd.md#api-response",
      "docs/design/api-spec.md#checkout-response",
      "src/api/checkout/response.ts:15-30"
    ]
  },

  "gate_criteria": {
    "irreversibility": "high",
    "blast_radius": "high",
    "product_meaning_change": false,
    "reasoning": "공개 API 변경은 외부 클라이언트에 영향, 롤백 시 또 다른 breaking change 발생"
  },

  "options": [
    {
      "id": "A",
      "label": "현재 API 유지, 프론트엔드 매핑 추가",
      "what_changes": "FE에 response adapter layer 추가, API 그대로 유지",
      "tradeoffs": ["매핑 코드 ~50줄 추가", "하위 호환 완전 유지"],
      "estimated_effort": "medium",
      "affected_files": ["src/pages/checkout/adapters/apiMapper.ts"]
    },
    {
      "id": "B",
      "label": "API 응답 형태 변경",
      "what_changes": "checkout endpoint 응답을 PRD 형태로 변경, v2 엔드포인트 또는 breaking change",
      "tradeoffs": ["깔끔한 계약", "기존 클라이언트 깨짐, 마이그레이션 필요"],
      "estimated_effort": "large",
      "affected_files": ["src/api/checkout/response.ts", "docs/api/migration-guide.md"]
    }
  ],
  "recommended_option": "A",
  "recommendation_rationale": "현재 외부 클라이언트가 존재하므로 하위 호환 유지가 안전. FE 매핑 비용이 API 마이그레이션보다 작음",

  "blocking": false,
  "blocked_work_items": ["FE-014", "API-003"],
  "unblocked_work_items": ["BE-011", "FE-019"],
  "default_if_no_response": "continue_unblocked_work",
  "linked_escalations": ["ESC-007"],
  "resolution": null
}
```

**3. _index.md 갱신** — Open Gates 테이블에 HDR-007 행 추가

**4. 사용자 결정 도착** — "A로 가자"

**5. 해결 처리** — resolution 채우고 `open/` → `resolved/`로 이동
```json
"resolution": {
  "resolved_at": "2026-03-09T16:20:00Z",
  "chosen_option": "A",
  "user_notes": "외부 클라이언트 호환성 우선",
  "rationale": "현 단계에서 breaking change 리스크를 감수할 이유 없음",
  "follow_up_actions": ["FE-014에 adapter layer 추가", "API-003 스펙 현행 유지 확정"],
  "after_state": "API 응답 형태 변경 없이 FE 매핑으로 해결. FE-014, API-003 PARKED → PENDING"
}
```

---

## Implementation Architecture

```
Outer loop:  Claude Agent SDK (session mgmt, permissions, monitoring)
  └─ Default: Subagents (lightweight, isolated, parallelizable)
  └─ Selective: Agent Teams (only when real discussion needed)
```

| Use Subagents | Use Agent Teams |
|---------------|-----------------|
| Focused implementation | Discovery/brainstorming |
| Single-purpose execution | Review synthesis (multi-perspective) |
| Sequential pipelines | Cross-layer coordination |
| Result-only delegation | Competing hypothesis evaluation |

---

## Core Operating Rules (9)

1. Documents are truth, conversations are ephemeral
2. One work item = one owner role
3. One file set = one executor at a time
4. Validation execution is centralized (VRM only)
5. Reviewers interpret evidence, don't create new evidence
6. Subordinates never ask human directly → escalate to Lead
7. Lead delegates before implementing
8. Human gates are narrow; auto-proceed is wide
9. **Human gates are non-blocking** — park the gated item, continue all unrelated work

---

## Key Constraints

- UX Reviewers: web only (Playwright/Chrome). No Android/iOS.
- Agent Teams: experimental, Opus 4.6+ required
- Subagents cannot nest (no Agent tool in subagent's tools)
- SDK pitfall: must set `settingSources: ["project"]` explicitly

---

## Next Steps

See [full spec](./2026-03-08-autonomous-dev-loop-design.md) Section 14 (TODO) for implementation roadmap.

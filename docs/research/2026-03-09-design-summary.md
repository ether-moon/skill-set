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

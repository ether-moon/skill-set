# Autonomous Product Development Loop — Design Specification

**Date**: 2026-03-08
**Status**: Draft
**Prerequisite**: [Agent Team Skill Research](./2026-03-07-agent-team-skill-research.md)

---

## Table of Contents

1. [Design Philosophy](#1-design-philosophy)
2. [Organization Chart](#2-organization-chart)
3. [Role Definitions](#3-role-definitions)
4. [State Machine — Development Loop](#4-state-machine--development-loop)
5. [Escalation Protocol](#5-escalation-protocol)
6. [Autonomy Boundaries](#6-autonomy-boundaries)
7. [Document Architecture](#7-document-architecture)
8. [Communication Schema (JSON)](#8-communication-schema-json)
9. [Role Prompt Skeletons](#9-role-prompt-skeletons)
10. [Claude Implementation Mapping](#10-claude-implementation-mapping)
11. [Phase-Based Activation Patterns](#11-phase-based-activation-patterns)
12. [Core Operating Rules](#12-core-operating-rules)
13. [Constraints & Limitations](#13-constraints--limitations)
14. [TODO](#14-todo)

---

## 1. Design Philosophy

### What This System Is

An **autonomous product development loop** — not just "an implementation agent team," but a system that cycles through the entire product lifecycle: spec refinement → implementation → testing → QA/research → spec revision → re-implementation, with the team self-correcting on reversible/local decisions while escalating only irreversible/product-altering decisions to the human.

### Core Principles

1. **Documents are truth, conversations are ephemeral.** Teammates and subagents read project context (CLAUDE.md, files on disk) but do NOT inherit the lead's conversation history. Long-running loops drift without file-based state.
2. **Core roles stay active; specialist roles activate on demand.** Always-on large teams slow convergence and inflate token cost. Official guidance recommends 3–5 teammates.
3. **Separate validation execution from validation interpretation.** One agent runs tests/browsers/screenshots; reviewers consume the same evidence. This prevents browser session collisions and duplicate test processes.
4. **Artifacts over opinions.** Every decision must land in a log file. Every validation must produce an evidence bundle. Every spec change must update the PRD.
5. **Narrow human gates, wide auto-proceed.** The team autonomously handles reversible/local choices; only irreversible or product-meaning changes reach the human.

### Design Tradeoff Rationale

| Concern | Decision | Rationale |
|---------|----------|-----------|
| All roles always active | Core 4 + conditional specialists | Official docs: 3–5 teammates; more = more coordination cost |
| Aesthetic UX every loop | Milestone-only activation | Prevents endless polish loops |
| Each reviewer runs own browser | Single Validation Runtime Manager | Avoids deadlocks, state corruption, duplicate processes |
| Conversation-based state | File-based state | Teammates don't inherit lead's conversation history |
| "20% change" threshold | Irreversibility + blast radius criteria | Mechanical, unambiguous gate criteria |

---

## 2. Organization Chart

```
                        ┌─────────────────────┐
                        │    Human (User)      │
                        └──────────┬───────────┘
                                   │ Level 4 only
                        ┌──────────▼───────────┐
                        │  👑 Team Lead /       │
                        │     Orchestrator      │
                        └──┬───────────────┬────┘
                           │               │
              ┌────────────▼──┐    ┌───────▼────────────┐
              │  📋 PM /       │    │  🛠️ Tech Lead /     │
              │  Spec Owner    │    │  Architect          │
              └────────┬───────┘    └───┬──────────┬─────┘
                       │                │          │
            ┌──────────▼──────────┐     │    ┌─────▼──────────────┐
            │  🔍 Verification    │     │    │  ⚙️ Execution       │
            │     Part            │     │    │     Part            │
            │  (trigger: PM)      │     │    │  (managed: TL)      │
            ├─────────────────────┤     │    ├─────────────────────┤
            │ • QA Reviewer       │     │    │ • UI Designer [C]   │
            │ • Pragmatic UX [C]  │     │    │ • FE Builder  [C]   │
            │ • Aesthetic UX [C*] │     │    │ • BE Builder  [C]   │
            └─────────────────────┘     │    └─────────────────────┘
                                        │
                              ┌─────────▼─────────┐
                              │  🧪 Validation     │
                              │  Runtime Manager   │
                              └───────────────────┘

[C]  = Conditional — activated on demand
[C*] = Conditional, milestone-only
```

### Role Classification

| Category | Roles | Activation |
|----------|-------|------------|
| **Always-on Core** | Team Lead, PM, Tech Lead, Validation Runtime Manager | Every loop iteration |
| **Conditional Executors** | FE Builder, BE Builder, UI Designer | When implementation is needed |
| **Conditional Reviewers** | QA Reviewer, Pragmatic UX Reviewer | Most validation loops |
| **Milestone-only** | Aesthetic UX Reviewer | Release candidates, major milestones |

---

## 3. Role Definitions

### 3.1 Team Lead / Orchestrator

| Aspect | Detail |
|--------|--------|
| **Responsibilities** | Loop state transitions, role invocation decisions, final merge, human gate judgment, sole user-facing communication |
| **Prohibited** | Writing PRD directly, routine code implementation, delegating human-approval decisions downward |
| **Operating rule** | Delegate over direct implementation. Direct fix only when all executors are idle AND a single trivial fix remains |
| **Outputs** | `loop-state.json`, active work-items summary, risk register, next action decision |

> **Why the "no direct implementation" rule**: Official docs note that leads often skip waiting for teammates and implement directly. Anthropic explicitly recommends instructing the lead to wait.

### 3.2 PM / Spec Owner

| Aspect | Detail |
|--------|--------|
| **Responsibilities** | PRD authoring/revision, acceptance criteria maintenance, assumption log, decision log, feedback classification |
| **Prohibited** | Code modification, finalizing technical implementation details, running tests |
| **Feedback classification** | Every piece of implementation feedback → one of: `bug`, `spec_gap`, `ux_polish`, `product_level_change` |
| **Outputs** | PRD deltas, acceptance criteria deltas, open questions, decision proposals |

### 3.3 Tech Lead / Architect

| Aspect | Detail |
|--------|--------|
| **Responsibilities** | Decompose specs into work items, assign file ownership, invoke FE/BE/UI executors, technical risk assessment |
| **Prohibited** | Filling spec gaps with arbitrary product decisions, assigning the same file set to multiple executors simultaneously |
| **Autonomy scope** | Local, reversible technical choices (see [Section 6](#6-autonomy-boundaries)) |
| **Frontend workflow** | Request UI Designer guidance first → then delegate to FE Builder |
| **Outputs** | `work-items.json`, dependency graph, `file-ownership.md`, technical risk notes |

### 3.4 Validation Runtime Manager

| Aspect | Detail |
|--------|--------|
| **Responsibilities** | Execute test suites, run Playwright scenarios, accessibility checks (axe), screenshot collection, evidence bundle assembly |
| **Prohibited** | Product judgment, spec changes, independent code fixes |
| **Key principle** | Single point of test execution — prevents multiple test processes, deadlocks, and environment contamination |
| **Outputs** | Validation report, evidence bundle (screenshots, logs, traces), pass/fail summary |

### 3.5 Conditional Executors

#### UI Designer
- Design system management and direction
- Acts as UI architect BEFORE frontend implementation begins
- Activated when: new screens, information architecture changes, design system impact

#### Frontend Builder
- Frontend implementation per Tech Lead's work items
- Must receive UI Designer guidance before starting (when applicable)
- Owns specific file paths during implementation

#### Backend Builder
- Backend implementation per Tech Lead's work items
- Owns specific file paths during implementation

### 3.6 Conditional Reviewers

#### QA Reviewer
- Validates implementation correctness against specs and requirements
- Detects functional defects
- Consumes evidence from Validation Runtime Manager (does NOT run own tests)

#### Pragmatic UX Reviewer
- Evaluates usability, accessibility, intuitiveness from a practical standpoint
- Uses Playwright/browser tools via evidence from Validation Runtime Manager
- Participates in most validation loops

#### Aesthetic UX Reviewer
- Evaluates visual trends, aesthetic refinement, interface sophistication
- Milestone/release candidate reviews only
- **Why milestone-only**: Always-on aesthetic review creates endless polish loops

---

## 4. State Machine — Development Loop

```
DISCOVER ──► SPEC_DRAFT ──► SPEC_HARDEN ──► BUILD_PLAN ──► IMPLEMENT
                                 ▲                              │
                                 │                              ▼
                            AUTOFIX ◄──── REVIEW_SYNTHESIS ◄── VALIDATE
                                 │               │
                                 │               ▼
                                 │         HUMAN_GATE
                                 │               │
                                 └───────────────┘
                                                  └──► DONE
```

### State Definitions

#### DISCOVER
- **Input**: User's service concept / requirements
- **Actors**: Lead + PM + Tech Lead + (optional) UI/UX
- **Activity**: Gap analysis, initial requirement decomposition
- **Output**: `open-questions.md`, `assumptions.md`

#### SPEC_DRAFT
- **Actors**: PM
- **Activity**: Write PRD first draft including UI states, edge cases, acceptance criteria
- **Output**: `prd.md` (draft)

#### SPEC_HARDEN
- **Actors**: PM + Tech Lead + (optional) UI Designer
- **Activity**: Tech Lead reviews implementability, requests missing UI state / API contract / error handling specs
- **Rules**:
  - Reversible, local gaps → auto-fill (log in `assumptions.md`)
  - Irreversible, product-meaning gaps → human gate candidate
- **Output**: `prd.md` (hardened), `assumptions.md` (updated)

#### BUILD_PLAN
- **Actors**: Tech Lead
- **Activity**: Create work items with file ownership, dependencies, definition of done
- **Rules**: Never assign overlapping file sets to multiple executors
- **Output**: `work-items.json`, `file-ownership.md`

#### IMPLEMENT
- **Actors**: Tech Lead + FE Builder + BE Builder + (optional) UI Designer
- **Activity**: Code production
- **Rules**:
  - One executor per file set at any time
  - Frontend work: UI Designer review first → FE Builder
  - Risky operations: read-only plan mode review first
- **Output**: Code changes, git commits

#### VALIDATE
- **Actors**: Validation Runtime Manager
- **Activity**: Single execution pass — tests, Playwright, accessibility, screenshots
- **Output**: Evidence bundle at `docs/qa/validation/{date}-run-{n}/`

#### REVIEW_SYNTHESIS
- **Actors**: PM + QA Reviewer + Pragmatic UX Reviewer + (optional) Aesthetic UX Reviewer
- **Activity**:
  - Reviewers independently interpret the SAME evidence bundle
  - PM classifies all feedback into 4 categories:
    - `bug` → AUTOFIX
    - `spec_gap` → AUTOFIX (via SPEC_HARDEN)
    - `ux_polish` → AUTOFIX
    - `product_level_change` → HUMAN_GATE
- **Output**: Classified feedback report

#### AUTOFIX
- **Trigger**: `bug`, `spec_gap`, or `ux_polish` feedback
- **Activity**: Automatic regression to SPEC_HARDEN or IMPLEMENT
- **Key**: No human approval needed

#### HUMAN_GATE
- **Trigger**: `product_level_change` or irreversible/high-blast-radius decisions
- **Activity**: Lead compiles impact report → asks user → waits
- **Resume**: User approval → SPEC_HARDEN or BUILD_PLAN

#### DONE
- **Conditions**:
  - All acceptance criteria met
  - No blocking issues
  - Validation evidence exists
  - PM + Lead confirm release candidate

---

## 5. Escalation Protocol

### 4-Level Communication Hierarchy

#### Level 1 — Bug Fast Track
```
PM/QA ──► Tech Lead (Direct)
```
- Obvious bugs requiring code-level fix only (button not clickable, API 500)
- No PRD modification needed
- Tech Lead dispatches to appropriate builder

#### Level 2 — Spec Clarification
```
Tech Lead ──► PM
```
- Missing edge case handling, undefined UI states (e.g., loading state design)
- Tech Lead does NOT guess — requests spec supplement from PM

#### Level 3 — Trade-off Escalation
```
Tech Lead / PM ──► Team Lead
```
- "Implementing this spec will degrade performance by 50%"
- "This design requires a complete library replacement"
- Team Lead decides considering project timeline and goals

#### Level 4 — Human-in-the-Loop
```
Team Lead ──► User (Human)
```
- Major PRD revision proposals
- "Redesign the entire UI concept" recommendations
- Lead compiles impact analysis report → submits to user → enters WAIT state
- **Critical**: Subagents cannot ask the user directly (SDK limitation: `AskUserQuestion` unavailable in Task-spawned subagents). All human-facing queries MUST route through Lead.

---

## 6. Autonomy Boundaries

### Auto-Proceed (Team Decides Autonomously)

These decisions are made by the team, logged in `assumptions.md`, and never escalated:

- Loading / error / empty state UI
- Button disable/enable rules
- Default sort order, page size
- Standard form validation rules
- Spacing/typography choices within the design system
- API retry/timeout conservative defaults
- Test data composition
- Minor refactoring necessary for implementation
- Copy/layout polish that doesn't break acceptance criteria
- Exception handling within existing flows

### Human Gate (Must Escalate)

These decisions ALWAYS go to the user:

- Core user flow changes
- Information architecture / navigation structure changes
- Authentication / authorization / privacy / payment / legal implications
- Database schema breaking changes
- Public API breaking changes
- Major external dependency additions or replacements
- QA/UX findings indicating "the current direction itself is wrong" (pivot-level)
- KPI interpretation or target user assumption changes

### Decision Criteria

The gate criterion is NOT a vague threshold like "20% or more modification." Instead, apply these three tests:

| Test | Question |
|------|----------|
| **Irreversibility** | Can this be undone without significant cost? |
| **Blast Radius** | How many components/users/systems does this affect? |
| **Product Meaning** | Does this change what the product IS or WHO it's for? |

If any test scores HIGH → HUMAN_GATE.

---

## 7. Document Architecture

### Product Documents (Source of Truth)

```
docs/product/
├── prd.md                    # Product Requirements Document
├── assumptions.md            # Auto-filled assumptions (logged, not escalated)
├── open-questions.md         # Unresolved questions for human
└── decision-log.md           # All decisions with rationale
```

### Design Documents

```
docs/design/
├── ui-spec.md                # UI states, layouts, interactions
└── design-principles.md      # Design system rules and constraints
```

### Engineering Documents

```
docs/engineering/
├── tech-spec.md              # Technical architecture decisions
├── api-contracts.md          # API interface definitions
└── file-ownership.md         # Current file → owner mapping
```

### QA & Validation

```
docs/qa/
├── test-plan.md              # Test strategy and coverage
└── validation/
    ├── {date}-run-{n}.md              # Validation report
    └── {date}-run-{n}-evidence/       # Screenshots, logs, traces
```

### Orchestration (Machine-Readable)

```
docs/orchestration/
├── loop-state.json           # Current state machine position
├── work-items.json           # Task graph with ownership
├── escalations/              # Active escalation records
└── human-gates/              # Pending human decisions
```

---

## 8. Communication Schema (JSON)

### 8.1 Work Item

```json
{
  "id": "FE-014",
  "title": "Checkout page empty/loading/error states",
  "owner_role": "frontend-builder",
  "depends_on": ["API-003"],
  "input_artifacts": [
    "docs/product/prd.md#checkout",
    "docs/design/ui-spec.md#checkout-states"
  ],
  "owned_paths": [
    "apps/web/src/pages/checkout/",
    "apps/web/src/components/checkout/"
  ],
  "acceptance_criteria": [
    "Loading state shown within 100ms of request start",
    "Empty state copy follows product copy guidelines",
    "Error state supports retry"
  ],
  "definition_of_done": [
    "Unit tests pass",
    "Playwright scenario passes",
    "No TypeScript errors"
  ],
  "status": "pending"
}
```

### 8.2 Escalation

```json
{
  "id": "ESC-007",
  "raised_by": "tech-lead",
  "level": "human_gate",
  "reason_type": "breaking_api_change",
  "summary": "Current PRD implies a public API response shape change.",
  "impact": {
    "product": "low",
    "engineering": "medium",
    "ux": "low",
    "risk": "high"
  },
  "options": [
    {
      "id": "A",
      "label": "Preserve current API and adapt frontend",
      "tradeoffs": ["More frontend mapping code", "No breaking change"]
    },
    {
      "id": "B",
      "label": "Change API response shape",
      "tradeoffs": ["Cleaner contract", "Breaking change for existing clients"]
    }
  ],
  "recommended_option": "A",
  "status": "open"
}
```

### 8.3 Validation Finding

```json
{
  "id": "VAL-031",
  "reviewer_role": "pragmatic-ux-reviewer",
  "severity": "medium",
  "category": "usability",
  "evidence": [
    "docs/qa/validation/2026-03-08-run-01.md#finding-4",
    "docs/qa/validation/2026-03-08-run-01-evidence/checkout-error.png"
  ],
  "summary": "Retry button is below the fold on smaller screens.",
  "recommendation": "Move retry action above supporting copy.",
  "requires_human": false
}
```

### 8.4 Human Decision Request

```json
{
  "id": "HDR-002",
  "triggered_by": "pm",
  "question": "Should checkout allow guest purchases?",
  "why_now": "Current flow blocks completion for non-signed-in users.",
  "options": [
    "Require sign-in before checkout",
    "Allow guest checkout",
    "Defer checkout and collect email only"
  ],
  "default_if_no_response": "block_further_progress",
  "linked_escalations": ["ESC-009"]
}
```

---

## 9. Role Prompt Skeletons

### Design Principle

Prompts should be short and contract-oriented: **authority / prohibitions / inputs / outputs**. Avoid massive system prompts.

### Team Lead / Orchestrator

```
You are Team Lead / Orchestrator.

GOAL: Drive the product development loop to satisfy all acceptance criteria autonomously.

AUTHORITY:
- Decide current loop state and transitions
- Choose which roles to invoke and when
- Open human gates when criteria are met
- Perform final merge and release candidate judgment

PROHIBITIONS:
- Do NOT write or modify the PRD directly — delegate to PM
- Do NOT implement code routinely — delegate to Tech Lead and builders
- Do NOT push human-approval decisions down to subordinate roles

ESCALATION RULE:
If a subordinate needs user input, they MUST escalate to you. You are the
sole channel to the human. Use AskUserQuestion only through your own context.

DIRECT IMPLEMENTATION EXCEPTION:
Only fix code yourself when ALL executors are idle AND only a single trivial
fix remains. In all other cases, delegate.

OUTPUTS: loop-state.json, work-items summary, risk register, next action.
```

### PM / Spec Owner

```
You are PM / Spec Owner.

GOAL: Maintain the PRD as the single source of product truth.

YOUR DOCUMENTS: prd.md, acceptance criteria, assumptions.md, decision-log.md

AUTHORITY:
- Write and revise PRD and acceptance criteria
- Classify implementation feedback into: bug | spec_gap | ux_polish | product_level_change
- Auto-fill reversible/local spec gaps (log in assumptions.md)

PROHIBITIONS:
- Do NOT modify code
- Do NOT finalize technical implementation details
- Do NOT run tests

ESCALATION: If a spec gap changes product meaning, propose a human gate to Lead.

OUTPUTS: PRD deltas, acceptance criteria deltas, open questions, decision proposals.
```

### Tech Lead / Architect

```
You are Tech Lead / Architect.

GOAL: Translate specs into implementable work items and coordinate builders.

AUTHORITY:
- Decompose specs into work items with file ownership
- Invoke FE/BE/UI builders
- Make local, reversible technical decisions autonomously
- Request UI Designer guidance before frontend tasks

PROHIBITIONS:
- Do NOT fill spec gaps with arbitrary product decisions.
  If the spec is silent, call PM for clarification.
- Do NOT assign overlapping file sets to multiple builders simultaneously.
- Do NOT proceed with breaking changes without escalation.

OUTPUTS: work-items.json, dependency graph, file-ownership.md, technical risks.
```

### Validation Runtime Manager

```
You are Validation Runtime Manager.

GOAL: Execute all validation tooling and produce reusable evidence bundles.

AUTHORITY:
- Run test suites, Playwright scenarios, accessibility checks, screenshot capture
- Produce evidence bundles at standard paths

PROHIBITIONS:
- Do NOT make product judgments
- Do NOT modify specs
- Do NOT fix code independently

OUTPUTS: Validation report, evidence bundle, pass/fail summary at
docs/qa/validation/{date}-run-{n}/
```

### QA / UX Reviewers (Common Pattern)

```
You are [QA Reviewer | Pragmatic UX Reviewer | Aesthetic UX Reviewer].

GOAL: Interpret validation evidence and produce actionable feedback.

INPUT: Evidence bundle from Validation Runtime Manager (same evidence for all reviewers).

AUTHORITY:
- Read and interpret evidence
- Write feedback reports from your perspective
  - QA: spec compliance, functional defects
  - Pragmatic UX: usability, accessibility, intuitiveness
  - Aesthetic UX: visual trends, refinement, interface sophistication

PROHIBITIONS:
- Do NOT launch your own browser sessions or test processes
- Do NOT duplicate findings already reported by other reviewers
- Do NOT modify code or specs

OUTPUTS: Feedback report with severity, evidence references, recommendations.
```

---

## 10. Claude Implementation Mapping

### Architecture: SDK Outer Loop + Subagent Inner Execution

```
┌─────────────────────────────────────────────┐
│  Claude Agent SDK (Outer Loop)              │
│  - Session management (resume/fork)         │
│  - Permission control                       │
│  - Cost limits                              │
│  - Monitoring                               │
│                                             │
│  ┌───────────────────────────────────────┐  │
│  │  Team Lead (Main Agent)               │  │
│  │                                       │  │
│  │  ┌─────────┐  ┌─────────┐            │  │
│  │  │ PM      │  │ Tech    │  Subagents  │  │
│  │  │(subagt) │  │ Lead    │             │  │
│  │  └─────────┘  │(subagt) │            │  │
│  │               └────┬────┘            │  │
│  │                    │                  │  │
│  │          ┌─────────┼─────────┐       │  │
│  │          │         │         │       │  │
│  │     ┌────▼──┐ ┌────▼──┐ ┌───▼───┐   │  │
│  │     │FE Bld │ │BE Bld │ │UI Des │   │  │
│  │     └───────┘ └───────┘ └───────┘   │  │
│  │                                       │  │
│  │  Agent Teams (selective, for):        │  │
│  │  - Discovery/brainstorming            │  │
│  │  - Review synthesis (QA + UX)         │  │
│  │  - Cross-layer coordination           │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

### Why This Architecture

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| **Outer loop** | Claude Agent SDK | Production-ready: headless mode, permissions, monitoring, session management. Used internally at Anthropic. |
| **Default execution** | Subagents | Lightweight, context-isolated, parallelizable, tool/permission-restrictable per role |
| **Selective collaboration** | Agent Teams | Only when real discussion/mutual critique is needed. Still experimental, higher token cost. |

### When to Use Agent Teams vs. Subagents

| Use Agent Teams | Use Subagents |
|-----------------|---------------|
| Discovery/brainstorming sessions | Focused implementation tasks |
| Review synthesis (multiple perspectives) | Single-purpose execution |
| Competing hypothesis evaluation | Sequential pipeline steps |
| Cross-layer coordination needing discussion | Result-only delegation |

### Skills Design

| Skill Type | Configuration | Example |
|------------|--------------|---------|
| Background knowledge | `user-invocable: false` | Design system principles |
| Dangerous execution | `disable-model-invocation: true` | DB migration scripts |
| Research | `context: fork`, `agent: Explore` | Codebase analysis |
| Tool-restricted | `allowed-tools: [Read, Glob, Grep]` | Review-only roles |

> **Important**: Subagents do NOT auto-inherit parent's skills. Required skills must be explicitly loaded per subagent.

### Hooks (Near-Mandatory)

| Hook | Purpose | Mechanism |
|------|---------|-----------|
| `PreToolUse` | Block destructive commands, schema migrations, external deployments | Exit code 2 = block + feedback |
| `TaskCompleted` | Reject task completion without tests/lint/evidence | Exit code 2 = reject completion |
| `TeammateIdle` | Prevent idle if acceptance criteria unmet | Exit code 2 = push feedback |
| `Stop` / `SubagentStop` | Prevent termination with critical tasks remaining | Exit code 2 = block exit |

### Permission Modes by Role

| Role | Permission Mode | Rationale |
|------|----------------|-----------|
| Team Lead | `default` | Needs user confirmation for risky operations |
| PM / QA / UX | Read-only tools + `plan` | No code modification authority |
| Builders | `acceptEdits` in isolated worktree | Auto-approve file edits within owned paths |
| All roles | Never `bypassPermissions` | Subagents inherit this mode — extremely dangerous |

### SDK Configuration Note

> **Pitfall**: `.claude/settings.json` rules are NOT auto-loaded by the SDK. You must explicitly set `settingSources: ["project"]` to apply project-level permission rules and hook settings.

---

## 11. Phase-Based Activation Patterns

### Spec Phase (DISCOVER → SPEC_HARDEN)

| Status | Role | Mode |
|--------|------|------|
| Active | Lead, PM, Tech Lead | Read-only / plan |
| Optional | Pragmatic UX Reviewer, UI Designer | Consultation |
| Inactive | All builders, QA, Aesthetic UX | — |

### Build Phase (BUILD_PLAN → IMPLEMENT)

| Status | Role | Mode |
|--------|------|------|
| Active | Lead, Tech Lead, FE Builder, BE Builder, Validation Runtime Manager | acceptEdits (builders) |
| Optional | UI Designer | Pre-implementation guidance |
| Inactive | PM (standby), QA, UX reviewers | — |

### Validation Phase (VALIDATE → REVIEW_SYNTHESIS)

| Status | Role | Mode |
|--------|------|------|
| Active | Lead, PM, Validation Runtime Manager, QA Reviewer, Pragmatic UX Reviewer | Read-only (reviewers) |
| Optional | Aesthetic UX Reviewer | Milestone only |
| Inactive | All builders | — |

This keeps **3–5 active roles** at any given moment, aligned with official recommendations.

---

## 12. Core Operating Rules

1. **Documents are truth, conversations are ephemeral.** All decisions, assumptions, and state changes must be persisted to files.
2. **One work item, one owner role.** No shared ownership.
3. **One file set, one executor at a time.** Agent teams warn: same-file edits cause overwrites.
4. **Validation execution is centralized.** Only Validation Runtime Manager runs tests/browsers.
5. **Reviewers interpret evidence; they don't create new evidence.** Prevents session proliferation.
6. **Subordinates never ask the human directly.** All user-facing queries route through Lead. (SDK constraint: `AskUserQuestion` unavailable in Task-spawned subagents.)
7. **Lead delegates before implementing.** Direct implementation is the exception, not the rule.
8. **Human gates are narrow; auto-proceed is wide.** Use the three-test criteria (irreversibility, blast radius, product meaning), not vague percentage thresholds.

---

## 13. Constraints & Limitations

- **UX Reviewers**: Only capable of validating web-based services (via Playwright, Chrome-connected tools). Android/iOS or other platform-specific runtimes are not supported.
- **Agent Teams**: Currently experimental (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`). Requires Opus 4.6+. No session resumption with in-process teammates, no nested teams.
- **Subagent nesting**: Subagents cannot spawn other subagents. Never include `Task`/`Agent` in a subagent's tools array.
- **Session limits**: One team per session, lead is fixed and cannot be changed.
- **File conflicts**: Agent teams provide no merge resolution — overlapping file edits cause overwrites. Work item decomposition MUST be file-boundary-aware.

---

## 14. TODO

- [ ] Write full role prompts for each agent (based on skeletons in Section 9)
- [ ] Design inter-agent communication format (JSON / YAML / Markdown — decide optimal format)
- [ ] Implement `.claude/agents/` definitions for all roles
- [ ] Create skills for role-specific knowledge
- [ ] Build orchestrator code (Agent SDK outer loop)
- [ ] Define `.claude/settings.json` with permission rules and hooks
- [ ] Create template files for document architecture (Section 7)
- [ ] Build loop-state management tooling
- [ ] Test with a pilot project (3-role minimal configuration first)

---

## Appendix: Sources

### Direct References
- [Building Effective Agents — Anthropic](https://www.anthropic.com/research/building-effective-agents)
- [Agent SDK Overview](https://platform.claude.com/docs/en/agent-sdk/overview)
- [Agent SDK Subagents](https://platform.claude.com/docs/en/agent-sdk/subagents)
- [Claude Code Custom Subagents](https://code.claude.com/docs/en/sub-agents)
- [Claude Code Agent Teams](https://code.claude.com/docs/en/agent-teams)

### Foundation Research
- [Agent Team Skill Research (2026-03-07)](./2026-03-07-agent-team-skill-research.md) — Framework survey, pattern analysis, Claude infrastructure mapping

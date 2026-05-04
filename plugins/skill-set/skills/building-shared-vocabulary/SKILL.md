---
name: building-shared-vocabulary
description: Maintains a project's domain glossary in CONTEXT.md and architecture decisions in docs/adr/ as living artifacts — files are created lazily, updated inline as terms resolve and decisions crystallize, and conflicts with existing entries are surfaced immediately. Use this skill whenever a domain term is being pinned down, a decision sounds ADR-worthy, or vocabulary is about to drift — phrases like "domain glossary", "context.md", "we should write this down", "let's name this", "what do we call this", "is this worth an ADR", "pin down this term" — and as a side-effect of grilling-plans when terms or decisions surface.
---

# Building Shared Vocabulary

## Overview

A project's **domain glossary** (`CONTEXT.md`) and **architecture decision records** (`docs/adr/`) are not documentation written after the fact — they are operational artifacts that the agent reads to stay aligned with the project, and updates inline as the conversation produces new shared meaning.

**Core principle:** Vocabulary is built up one resolved term at a time, in the moment the resolution happens. Batched glossary writes go stale.

> `CONTEXT.md` is a **domain artifact**, not an agent directive. `guarding-agent-directives` does not apply — that skill protects `CLAUDE.md` / `AGENTS.md` and the documents they reference. This skill owns `CONTEXT.md` and `docs/adr/`.

## When to Use

- A domain term is being pinned down during conversation (especially during grilling)
- A term in the user's plan conflicts with how the codebase uses it
- A decision that is **hard-to-reverse**, **surprising-without-context**, AND **the result of a real trade-off** has been made — record an ADR
- User explicitly asks to "build a glossary," "set up CONTEXT.md," "add an ADR"

## Do NOT use for

- Implementation-level documentation → README, code comments
- Process or workflow documentation → AGENTS.md / CLAUDE.md (and check `guarding-agent-directives` first)
- Library / framework reference → `understanding-code-context`
- Generating PRDs or issues from conversation → out of scope here
- Decisions that are easily reversed, obvious in hindsight, or had no real alternative → no ADR

## Scope

This skill supports a **single root `CONTEXT.md`** and a **single `docs/adr/` directory**. Multi-context monorepos (per-bounded-context glossaries, `CONTEXT-MAP.md` indexes) are out of scope; if a project genuinely needs them, that's a future enhancement.

## Process

### Lazy file creation

Create files only on first real demand. An empty `CONTEXT.md` signals "this project has no shared vocabulary," not "no vocabulary surfaced yet" — speculative skeletons mislead future readers and the agent itself.

| Trigger | Create |
|---|---|
| First domain term gets resolved | `CONTEXT.md` at repo root |
| First decision meets the ADR bar | `docs/adr/0001-<slug>.md` |

If the file already exists, append to it; never overwrite or reorder existing entries silently.

### Updating `CONTEXT.md` inline

When a term is resolved during conversation, update `CONTEXT.md` **right away** — not at the end of the session. Use the format in `reference/context-format.md`.

**Rules:**
- Only domain-meaningful terms. No implementation jargon, no tool names, no helper-function names.
- One canonical name per concept. If the project has been calling the same concept by two names, pick one and note the deprecated alternative under "Avoid:".
- Capture relationships between terms (e.g., "An Order has many Line Items").
- Flag genuine ambiguity explicitly under "Flagged ambiguities".

### Surface conflicts immediately

When the user uses a term that conflicts with an existing `CONTEXT.md` entry, stop and surface it before continuing:

> "`CONTEXT.md` defines **Cancellation** as the user-initiated revocation. You're using it for the system-initiated timeout. Do we update the definition, or do we need a new term?"

Do not silently let the conflict pass. The conflict is the reason vocabulary exists.

### Recording ADRs

Offer an ADR **only when all three are true**:

1. **Hard-to-reverse** — undoing the decision later costs real engineering effort
2. **Surprising-without-context** — a future reader will wonder why this choice was made
3. **The result of a real trade-off** — there were genuine alternatives, and one was picked for specific reasons

If even one is missing, do not offer an ADR. "We picked Postgres because we know Postgres" is not an ADR.

Use the format in `reference/adr-format.md`. Number sequentially (`0001-`, `0002-`, …). Filename slug should be a noun phrase (`0007-event-sourced-orders.md`).

## Process Flow

```
term resolved during conversation
  → conflict with existing CONTEXT.md entry?  yes → surface, resolve
  → update CONTEXT.md inline

decision made during conversation
  → hard-to-reverse?       no → skip
  → surprising-no-context? no → skip
  → real trade-off?        no → skip
  → all yes → offer ADR; on accept, write docs/adr/NNNN-<slug>.md
```

## Reading `CONTEXT.md` and ADRs

When this skill is invoked or when the agent enters a project for code work, read these files first if present:

1. `CONTEXT.md` at repo root (if exists)
2. `docs/adr/*.md` in the area being touched (don't over-read; pull only ADRs whose titles match the area)

Use the vocabulary from `CONTEXT.md` in:
- File and module names suggested in plans
- Variable and function names in implementations
- PR titles, commit messages, issue descriptions
- Conversation with the user

## Reference

- `reference/context-format.md` — exact format for a `CONTEXT.md` entry, with examples
- `reference/adr-format.md` — exact ADR template and the three-criterion check

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `CONTEXT.md` is bloated with implementation terms | Adding non-domain terms | Remove anything that wouldn't appear in a conversation with a non-engineer domain expert |
| Many ADRs over a short period | Bar set too low | Re-check each against the three criteria; demote ADRs that fail any |
| Same concept has multiple ADRs | No conflict surfacing | When updating, search ADR titles first; if related, supersede the older one explicitly |
| `CONTEXT.md` and code disagree | Code drifted, glossary didn't | Surface as a contradiction (this is exactly the signal `grilling-plans` Rule 4 catches) |
| Multi-context monorepo wants per-domain glossaries | Out of scope for this skill | Use a single root `CONTEXT.md` with section headers per bounded context as a stopgap; raise as an enhancement |

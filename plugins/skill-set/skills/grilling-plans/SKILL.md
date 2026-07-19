---
name: grilling-plans
description: Stress-tests an existing plan, RFC, design, or proposal by resolving one decision per turn and maintaining a decision ledger. Use when a user asks to grill, challenge, sanity-check, poke holes in, or assess whether an existing plan is ready.
allowed-tools: Read, Grep, Glob
---

# Grilling Plans

## Boundary

Interrogate an existing proposal. Do not create a blank-slate design, edit the plan, write implementation steps, or invoke another skill. The codebase and existing documents are read-only evidence.

If `CONTEXT.md` or relevant ADRs exist, read them only to preserve vocabulary and avoid reopening settled decisions. Never create or update them.

## Protocol

1. Extract explicit decisions, assumptions, and unresolved branches from the plan.
2. Verify present-state claims in code before asking the user. Use targeted search and report the evidence concisely.
3. Order unresolved branches by dependency: resolve a constraining decision before decisions that depend on it.
4. Ask one question per turn. Include the evidence, why the decision matters, 2–3 concrete alternatives, and one recommended answer.
5. After the answer, update the decision ledger as Confirmed, Rejected, or Unresolved.
6. Sharpen vague terms immediately; a phrase such as “standard,” “fast,” or “partial success” is not a resolved decision.
7. Stop after a default maximum of 5 user questions. Stop with Unresolved branches visible in the returned ledger and let the user explicitly request another round.

Questions answered by code do not consume the five-question budget. A user answer does. If the user stops earlier, return the same ledger without pressure to continue.

Read `reference/decision-tree-walk.md` for dependency ordering and `reference/codebase-cross-reference.md` for evidence checks.

## Question Format

```text
Question N/5 — <decision>

Evidence: <plan/code fact with path when relevant>
Why this matters: <downstream decisions or failure mode>
Options:
1. <option>
2. <option>
3. <option, when materially distinct>
Recommendation: <one option and concrete reason>
```

Ask exactly one question, then wait.

## Decision Ledger

Return this after question five or an earlier stop:

```text
## Confirmed
- <decision and chosen answer>

## Rejected
- <alternative and why it was rejected>

## Unresolved
- <remaining branch and what decision is missing>
```

Do not convert the ledger into an implementation plan. Unresolved items remain visible; never guess merely to declare readiness.

## Failure Handling

- No existing plan: state the missing prerequisite and stop.
- Present-state claim contradicts code: make that contradiction the next decision.
- Evidence remains absent after bounded search: record the uncertainty and ask one intent question with a recommendation.
- Answers conflict: place the conflict under Unresolved rather than choosing the latest answer silently.

Use the user's language for questions and the ledger. Keep paths and quoted plan terms exact.

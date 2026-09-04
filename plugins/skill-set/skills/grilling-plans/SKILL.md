---
name: grilling-plans
description: Stress-tests an existing plan, RFC, design, or proposal by presenting all evidence-backed decision questions in one batch and maintaining a decision ledger. Use when a user asks to grill, challenge, sanity-check, poke holes in, or assess whether an existing plan is ready.
allowed-tools: Read, Grep, Glob
---

# Grilling Plans

## Boundary

Interrogate an existing proposal. Do not create a blank-slate design, edit the plan, write implementation steps, or invoke another skill. The codebase and existing documents are read-only evidence.

If `CONTEXT.md` or relevant ADRs exist, read them only to preserve vocabulary and avoid reopening settled decisions. Never create or update them.

## Protocol

1. Extract explicit decisions, assumptions, and unresolved branches from the plan.
2. Verify present-state claims in code before asking the user. Use targeted search and report the evidence concisely.
3. Order unresolved branches by dependency. When a downstream branch depends on an earlier answer, state that condition explicitly.
4. Ask every currently identifiable question in one response. For each question, include the evidence, why the decision matters, 2–3 concrete alternatives, and one recommended answer.
5. Wait once for the user's batch response, then update the decision ledger as Confirmed, Rejected, or Unresolved.
6. Sharpen vague terms immediately; a phrase such as “standard,” “fast,” or “partial success” is not a resolved decision.
7. If the response leaves decisions unanswered or introduces new branches, present every remaining question together in the next response. Do not impose a question-count limit.

Questions answered by code are evidence, not questions for the user. If the user stops before resolving every branch, return the ledger with those branches under Unresolved and without pressure to continue.

Read `reference/decision-tree-walk.md` for dependency ordering and `reference/codebase-cross-reference.md` for evidence checks.

## Question Format

```text
Question <N> — <decision>

Evidence: <plan/code fact with path when relevant>
Why this matters: <downstream decisions or failure mode>
Options:
1. <option>
2. <option>
3. <option, when materially distinct>
Recommendation: <one option and concrete reason>
```

Number questions so the user can map answers to them. Ask all currently identifiable decision questions in dependency order in the same response, then wait.

## Decision Ledger

Return this when every decision is resolved or the user stops:

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
- Present-state claim contradicts code: include that contradiction as a decision in the current batch.
- Evidence remains absent after bounded search: record the uncertainty and include an intent question with a recommendation in the batch.
- Answers conflict: place the conflict under Unresolved and include it in the next batch rather than choosing the latest answer silently.

Use the user's language for questions and the ledger. Keep paths and quoted plan terms exact.

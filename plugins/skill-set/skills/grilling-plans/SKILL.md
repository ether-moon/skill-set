---
name: grilling-plans
description: Adversarially interrogates an existing plan, design, or proposal before implementation — walks the decision tree one question at a time, provides a recommended answer with each question, prefers codebase exploration over questions, and surfaces contradictions between stated intent and actual code. Use this skill whenever a plan, design doc, RFC, ADR draft, ticket spec, or implementation outline is shared and the user wants review, sanity check, sign-off, or asks "is this ready" — even without the word "grill". Trigger phrases include "grill me", "challenge this plan", "poke holes", "stress test", "내 계획 부숴봐", "구멍 찾아봐". Also use before locking down a spec for implementation.
---

# Grilling Plans

## Overview

Adversarial validation mode. Take an existing plan, design, or proposal and **walk the decision tree one branch at a time**, surfacing hidden assumptions, fuzzy terminology, and contradictions before any code is written.

**Core principle:** Misalignment is the #1 failure mode. The cure is not more brainstorming — it is forcing every implicit decision to become explicit.

This is a discipline skill. Each rule below corresponds to a specific way grilling silently fails when the rule is dropped — keeping all six is what separates grilling from casual conversation.

## When to Use

**Use grilling when a plan already exists and is about to be locked:**
- Between `superpowers:brainstorming` (creation) and `superpowers:writing-plans` (lock-down)
- Before invoking `superpowers:executing-plans`
- Right before a PR description is finalized
- User says "challenge this", "poke holes", "stress test", "grill me", "내 계획 부숴봐", "구멍 찾아봐"
- When a candidate is selected from `improving-architecture`

**Do NOT use for:**
- Blank-slate ideas with no plan yet → `superpowers:brainstorming`
- Locked specs that just need decomposition → `superpowers:writing-plans`
- Bug investigation → `superpowers:systematic-debugging`
- Reviewing already-written code → `simplify`
- External library API questions → `understanding-code-context`

Thinking "the plan looks good enough, skip grilling"? That is exactly when grilling matters most.

## Domain Awareness

Before the first question, absorb whatever domain context already exists:

- If `CONTEXT.md` and `docs/adr/` exist (per `building-shared-vocabulary`), read them first — `CONTEXT.md` carries canonical vocabulary, ADRs in the area being grilled record decisions you should not re-litigate. If absent, infer domain vocabulary from package/module names, test descriptions, and recent commit messages.
- Walk relevant code with Grep / Glob / Read or an `Explore` subagent — see `superpowers:dispatching-parallel-agents` if multiple independent areas need pre-grilling sweeps.

This costs a few minutes and saves a session of mis-aimed questions. It also lets Rule 5 (term sharpening) work against an actual baseline rather than guesses.

## The Grilling Protocol

Six rules. Each blocks a different failure mode (decision-tree drift, unanchored questions, lazy code-skipping, silent contradictions, vocabulary slop, abstract hand-waving) — weakening any one collapses grilling back into casual conversation.

### Rule 1 — Walk the Decision Tree, One Question Per Turn

Plans contain a tree of dependent decisions. Resolve them in dependency order, **one at a time**. Wait for the user's answer before moving to the next branch.

Why one at a time: batched questions get answered at the same shallow level. The user spreads attention across all of them, the dependency tree collapses into a flat list, and downstream answers stop being informed by upstream ones. Single questions force depth.

When a question opens up sub-questions, descend into the sub-tree before backing up.

### Rule 2 — Provide a Recommended Answer With Every Question

Every question must include the model's own recommendation, with reasoning. This forces commitment instead of polite hedging.

```
WRONG: "What should happen when the cache is empty?"
RIGHT: "What should happen when the cache is empty? My recommendation:
       fall through to the source of truth and repopulate, because the
       alternative (return empty) creates a thundering herd on miss.
       Counter-argument: warmup cost. Which way?"
```

If you cannot recommend an answer, the question is not yet sharp enough — refine it before asking.

### Rule 3 — Codebase Exploration Beats Asking

If a question can be answered by reading code, **read the code instead of asking**. Use Grep, Glob, or Read mid-walk; reserve `superpowers:dispatching-parallel-agents` for the Domain Awareness pre-grilling sweep, not for questions interleaved with the user.

```
WRONG: "Does this project already have a retry helper?"
RIGHT: [run Grep for "retry"] → "Found `src/lib/retry.ts` with exponential
       backoff. We should reuse it. Confirm?"
```

Only ask the user when the answer requires intent, judgment, or knowledge outside the repository.

### Rule 4 — Surface Contradictions Immediately

When the user's stated plan conflicts with what the code actually does, surface it the moment you see it. Do not let the contradiction silently become a future bug.

```
"You said partial cancellation is supported, but the code in
src/orders/cancel.ts cancels the entire Order in one transaction.
Which is the source of truth right now — the plan or the code?"
```

### Rule 5 — Sharpen Fuzzy Terms

When a term is overloaded, ambiguous, or context-dependent, propose a canonical name and pin down the meaning before continuing. Vague vocabulary now becomes a wrong implementation later.

```
"You're saying 'account' — do you mean the Customer record, the
authenticated User, or the Billing entity? Those are three different
things in this codebase. Pick one canonical term and let's use it."
```

If the project has a `CONTEXT.md` glossary, check the term against it. Conflicts with the glossary are themselves a signal.

### Rule 6 — Stress-Test With Concrete Scenarios

When domain relationships or boundaries are being discussed, invent a specific scenario that probes the edge. Force precision instead of letting abstractions slide by.

```
"You said partial cancellation is supported. Concrete scenario:
Order has three Line Items, customer cancels two. The third item
ships, the first two don't. Does the Order itself get a status?
What status? What does the invoice look like?"
```

Edge-case scenarios surface invariants the user hadn't thought about. Pick scenarios that lie at the boundaries — empty, full, partial, simultaneous, racing, retried, reordered. The user's answer either commits to a behavior or reveals that the behavior wasn't decided yet.

## Process Flow

```
receive plan
  → Domain Awareness (read CONTEXT.md / ADRs / code)
  → loop:
      pick next undecided branch (dependency order)
      → can codebase answer?  yes → read, present finding
                              no  → form question + recommendation, ask
      → contradiction with code?  yes → surface, then continue
      → fuzzy term?  yes → sharpen (canonical name), then continue
      → tree complete?  no → next branch
                        yes → plan validated
                              (optional: update CONTEXT.md / ADR)
```

## Outputs

**Default output:** a shared understanding between user and agent. The plan is now sharp enough to feed into `superpowers:writing-plans` or `superpowers:executing-plans`.

**Optional outputs (only if conditions are met):**

| Trigger | Action |
|---|---|
| A fuzzy term was sharpened during grilling | Hand off to `building-shared-vocabulary` to update `CONTEXT.md` |
| A decision is **hard-to-reverse** AND **surprising-without-context** AND **the result of a real trade-off** | Offer to record an ADR via `building-shared-vocabulary` |
| The plan reveals an architectural friction worth a separate refactor | Hand off to `improving-architecture` |

Do not produce these artifacts speculatively. Only when the bar is met.

**ADR yes-example:** "We project the read model into Postgres while the write model is event-sourced." Hard to reverse (touches every read path), surprising (a future reader will ask why the duplication exists), real trade-off (we chose CQRS over a simpler unified model for specific consistency reasons). → ADR.

**ADR no-example:** "We picked `pino` for logging because the team knows it." Easy to reverse (one PR), not surprising (default-ish choice), no real alternatives weighed. → No ADR, just a code comment if anything.

## Reference

- `reference/decision-tree-walk.md` — how to identify dependency order, when to descend vs. back up, what counts as a leaf
- `reference/codebase-cross-reference.md` — which tools to use for which kinds of contradictions, examples of high-value cross-checks

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| User feels grilled past the useful point | Asking questions whose recommendation is obvious | Stop asking and just commit to the recommendation; surface it as a finding instead |
| User keeps saying "I don't know, you decide" | Decisions are too granular for grilling | Back up one level; the user's threshold is the right granularity |
| Questions feel disconnected from each other | Not walking the dependency tree | Re-read the plan, list undecided branches in dependency order, restart from the top |
| Same fuzzy term keeps recurring | Term not pinned down | Stop and sharpen it now; do not continue with the term still ambiguous |
| Codebase contradicts the plan in many places | Plan written without exploring the code first | Pause grilling; have user re-explore code before continuing, or adjust the plan to match code |

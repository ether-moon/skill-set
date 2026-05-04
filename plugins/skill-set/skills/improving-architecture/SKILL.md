---
name: improving-architecture
description: Surfaces deep-module refactor candidates across a codebase using domain vocabulary and Ousterhout's depth/seam framing — applies the deletion test, presents candidates with locality and leverage justifications, and hands off to the `grilling-plans` skill for the chosen candidate's design. Use this skill whenever the user mentions architecture, refactoring scope, deep/shallow modules, seams, ports/adapters, modularity, or expresses frustration with tangled code — phrases like "improve architecture", "find refactor opportunities", "deep module", "ball-of-mud area", "this code is a mess", "untangle this", "split this module", "make this testable", "extract a seam", "shallow module", "리팩토링 거리 찾아" — even without the word "architecture". Not for reviewing recently changed code (use `simplify`) or designing new features (use `superpowers:brainstorming`).
---

# Improving Architecture

## Overview

Surface architectural friction in a codebase and propose **deepening opportunities** — refactors that turn shallow modules into deep ones. The aim is testability and AI-navigability, not aesthetic cleanup.

**Core principle:** A deep module hides a lot of behavior behind a small interface. A shallow module's interface is nearly as complex as its implementation. Find the shallow ones.

## When to Use

- The user wants to schedule architectural improvement work
- A bug fix or feature surfaces a tangled area worth improving separately
- Periodic review of an area that has accreted complexity over time
- User says "improve the architecture", "find refactor opportunities", "리팩토링 거리 찾아", "what should we deepen", "ball of mud"

## Do NOT use for

- Reviewing recently changed code → `simplify`
- Single-file cleanup (rename, dedupe, format) → just do it inline
- Bug investigation → `superpowers:systematic-debugging`
- New feature design → `superpowers:brainstorming`
- Test strategy → `driving-with-tests`

## Glossary

Consistent vocabulary lets two reviewers compare candidates across reviews; drift into "service" / "component" / "boundary" makes it impossible to tell whether two findings are the same or different. That is why the terms below are canonical and used as-is.

| Term | Meaning |
|---|---|
| **Module** | Anything with an interface and an implementation — function, class, package, slice |
| **Interface** | Everything a caller must know to use the module: types, invariants, error modes, ordering, config — not just the type signature |
| **Implementation** | The code inside the module |
| **Depth** | Leverage at the interface. **Deep** = a lot of behavior behind a small interface. **Shallow** = interface nearly as complex as the implementation. |
| **Seam** | Where an interface lives — a place behavior can be altered without editing in place |
| **Adapter** | A concrete thing satisfying an interface at a seam |
| **Leverage** | What callers gain from depth |
| **Locality** | What maintainers gain from depth — change, bugs, knowledge concentrated in one place |

Full elaboration in `reference/deep-modules.md`. The deletion test (the most useful single heuristic) lives in `reference/deletion-test.md`.

## Process

### 1. Orient

If `CONTEXT.md` and `docs/adr/` exist (per `building-shared-vocabulary`), read them first — `CONTEXT.md` gives names to good seams, ADRs record decisions to not re-litigate. If absent, infer domain vocabulary from package/module names, test descriptions, and recent commit messages, and proceed.

### 2. Explore

Walk the codebase looking for friction. Don't apply rigid heuristics — observe organically and note where understanding is hard:

- Where does understanding one concept require bouncing between many small files?
- Where is a module's interface nearly as complex as its implementation? (shallow)
- Where have pure functions been extracted just for testability, while the real bugs hide in *how* they're called? (no locality)
- Where do tightly-coupled modules leak across their seams?
- Which parts are untested or hard to test through their current interface?

For broader sweeps, dispatch an `Explore` agent (`Agent` tool with `subagent_type=Explore`) to walk a directory or feature area in parallel — see `superpowers:dispatching-parallel-agents`.

Apply the **deletion test** to anything you suspect is shallow: imagine deleting it. If complexity vanishes, it was a pass-through. If complexity reappears across N callers, it was earning its keep. Full procedure: `reference/deletion-test.md`.

### 3. Present candidates

Number them. For each:

```text
**N. <Candidate name in domain vocabulary>**

- **Files:** <paths>
- **Problem:** <why the current architecture causes friction>
- **Solution:** <plain English description of what would change>
- **Locality gain:** <what maintenance becomes easier>
- **Leverage gain:** <what callers stop having to think about>
- **Test impact:** <which tests survive, which become possible>
```

**Do not propose specific interfaces yet.** That belongs to the next phase.

**Vocabulary discipline:** Use `CONTEXT.md` terms for domain concepts ("the Order intake module") and the glossary above for architecture concepts ("a deep seam over the rate limiter"). Do not invent new architectural vocabulary; use the canonical terms.

**Filled example:**

```text
**1. Order Intake validation cluster**

- **Files:** src/orders/intake/promotion-check.ts, inventory-check.ts,
  credit-check.ts, route.ts (calls all three)
- **Problem:** Three shallow validators each export a single function;
  every caller has to remember the right ordering and aggregate errors
  manually. Two of three are also called by the admin Manual Order tool,
  which currently re-aggregates errors with a different shape.
- **Solution:** Collapse the three validators behind a single
  `validateOrder(order) → ValidationResult` interface that owns the
  ordering, the aggregation, and the error shape.
- **Locality gain:** Adding a new check (e.g., fraud scoring) becomes
  one edit inside the validation module; today it is three.
- **Leverage gain:** Both the HTTP route and the admin tool stop
  re-implementing aggregation; both consume the same `ValidationResult`.
- **Test impact:** Existing per-validator unit tests can stay as
  internal helpers; new tests assert against `validateOrder` outcomes —
  closer to user-observable behavior.
```

**ADR conflicts:** If a candidate contradicts an existing ADR, only surface it when the friction is real enough to warrant reopening the decision. Mark it: _"Contradicts ADR-0007 — but worth reopening because…"_. Do not list every theoretical refactor an ADR forbids.

Ask the user: "Which of these would you like to explore?"

### 4. Classify dependencies

Before designing a new interface, classify the candidate's dependencies (see `reference/deepening.md`):

1. **In-process** — pure computation; merge and test directly
2. **Local-substitutable** — has a local stand-in (PGLite, in-memory FS); use it
3. **Remote but owned** — your services across a network; define a port with 2+ adapters
4. **True external** — third-party (Stripe, Twilio); inject port, mock in tests

The category determines the seam strategy and what tests look like.

### 5. (Optional) Design It Twice

If interface shape is non-obvious, run a parallel sub-agent design generation pass — see `reference/interface-design.md`. Spawn 3+ agents with radically different design constraints (minimal interface / maximum flexibility / optimize-for-common-caller / ports-and-adapters), present the results sequentially, then commit to one.

Skip this step when the right interface is already obvious. Use it when the user is unsure or when the candidate's interface shape would set a long-term direction.

### 6. Hand off

Hand off to `grilling-plans` to interrogate the chosen design. Do not jump to writing implementation plans directly — the candidate is still under-specified, and grilling will surface what is unclear.

After grilling, ADRs and `CONTEXT.md` updates are owned by `building-shared-vocabulary` — this skill does not write them.

## Process Flow

```text
orient (read CONTEXT.md and relevant ADRs)
  → explore codebase for friction (optionally via Explore subagents)
  → apply deletion test to suspect shallow modules
  → present numbered candidates with locality / leverage / test impact
  → user picks one?  no  → end (note for later)
                     yes → classify dependencies
                                (in-process / local-sub / remote-owned / true-external)
                         → interface shape obvious?  yes → hand off to grilling-plans
                                                     no  → Design It Twice
                                                              → hand off to grilling-plans
```

## Reference

- `reference/deep-modules.md` — full elaboration of the depth / seam / adapter / locality vocabulary, with examples of deep vs. shallow at function, module, and package scales
- `reference/deletion-test.md` — how to actually run the deletion test, what counts as "complexity reappears", common false-negatives
- `reference/deepening.md` — dependency categorization (in-process / local-substitutable / remote-owned / true-external) and the testing strategy each implies
- `reference/interface-design.md` — the "Design It Twice" parallel sub-agent pattern for generating radically different interface candidates before committing

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Candidate list grows past 5–7 items | Including every theoretical improvement | Cut to the friction you actually felt during exploration; reject the speculative ones. (Past ~7 dilutes user attention; pick the highest-leverage subset.) |
| User can't choose between candidates | Candidates not differentiated by impact | Rank by locality/leverage gain, not by file count or apparent size |
| Output uses generic terms ("service", "boundary", "component") | Vocabulary discipline broke | Re-edit using only the glossary terms above; the precision is the point |
| Suggesting a candidate that contradicts a recent ADR | Did not read ADRs in step 1 | Read the ADR; either drop the candidate or surface it explicitly as an ADR-reopening proposal |
| Candidates require ground-up rewrites | Bar set too high | Look for *one-step* deepenings — refactors a single PR could deliver — not architectural revolutions |

---
name: zooming-out-on-code
description: Draws a higher-level system map of unfamiliar internal/project code in the project's domain vocabulary — describes the module's responsibility, callers, dependencies, and sibling modules without diving into implementation details. Use this skill proactively whenever a user expresses unfamiliarity with a project code area before changing it — phrases like "zoom out", "give me the big picture", "explain this code area", "new to this code", "where does X fit", "what calls this", "tour the module", "before I change this", "이 코드 큰 그림", "이 모듈 어디 쓰여" — even if they don't say "zoom out" explicitly.
---

# Zooming Out On Code

## Overview

When dropped into unfamiliar code, the agent's first instinct is often to read the file linearly. That produces local understanding without orientation. **Zooming out** does the opposite: go up one level of abstraction first, so the file in question is read with full system context.

**Core principle:** Understand a module by understanding its place, not its body.

## When to Use

- User opens a file or function they don't recognize and asks for context
- Before proposing changes to an unfamiliar area
- When a teammate hands off a system you have no prior context on
- User says "zoom out", "explain this code area", "give me the big picture", "what does this do in context", "이 코드 큰 그림", "이 모듈 어디 쓰여"

## Do NOT use for

- External library / framework documentation → `understanding-code-context`
- Reviewing changed code for quality → `simplify`
- Finding refactor opportunities → `improving-architecture`
- Debugging a specific bug → `superpowers:systematic-debugging`

## Process

1. **Read project context first.** If `CONTEXT.md` and `docs/adr/` exist (per `building-shared-vocabulary`), read them first. If absent, infer domain vocabulary from package/module names, public type/class names that mention business nouns, test descriptions, and recent commit messages.

2. **Go up one level.**
   - If the user asks about a function, describe its containing module
   - If the user asks about a module, describe its containing package or layer
   - If the user asks about a package, describe the system
   - If the user asks about a top-level package or whole app, describe its role in the product/business domain — do not recurse further (recursing past the top-level package turns orientation into product strategy, which is out of scope and rarely useful for a code change)

3. **Map four things.** These four answer "what is it for, who needs it, what does it need, what's adjacent" — together they place the module in the dependency graph without reading its body.
   - **Responsibility** — what is this module's single reason to exist, in domain vocabulary?
   - **Callers** — who depends on this module? Grep on the public API name; use `LSP findReferences` if an LSP is available for the language.
   - **Dependencies** — what does this module depend on? Read first-level imports only; transitive imports belong to a deeper zoom, not this one.
   - **Siblings** — what other modules sit at the same level of the system? Glob the parent directory.

4. **Answer in domain language, not implementation language.** "The Order intake module validates incoming Orders against the active Promotion catalog" beats "OrderHandler calls promotionService.validate()."

5. **Stop at the right level.** The goal is *orientation*, not *encyclopedia*. If the user wants to go deeper into a specific branch, they'll ask.

## Output template

```
**<Module name in domain vocabulary>**

**Responsibility:** <one sentence>

**Callers:**
- <caller 1> — <what it uses this for>
- <caller 2> — <what it uses this for>

**Dependencies:**
- <dependency 1> — <why>
- <dependency 2> — <why>

**Siblings (same layer):**
- <sibling 1> — <responsibility>
- <sibling 2> — <responsibility>

**Where it sits in the system:**
<one or two sentences explaining the module's position in the larger flow,
using CONTEXT.md vocabulary>
```

## Example

User asks about `src/orders/intake/validate.ts`.

```
**Order Intake — Validation**

**Responsibility:** Confirms an incoming Order satisfies promotion eligibility,
inventory availability, and customer credit before the Order is accepted.

**Callers:**
- `src/orders/intake/route.ts` — POST /orders endpoint, calls validation before persisting
- `src/admin/manual-orders.ts` — admin tool that creates Orders on behalf of a Customer

**Dependencies:**
- `src/promotions/catalog.ts` — looks up active promotions for the Customer
- `src/inventory/availability.ts` — confirms each Line Item is stocked
- `src/billing/credit.ts` — reads Customer credit limit

**Siblings (same layer — `src/orders/intake/`):**
- `route.ts` — HTTP boundary
- `persist.ts` — writes accepted Orders to the write model
- `events.ts` — emits `OrderPlaced` events on success

**Where it sits in the system:**
Validation is the gate between an HTTP request and a confirmed Order in the write
model. After it passes, persist + event emission are mechanical; before it passes,
nothing about the Order is durable.
```

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Output sounds like the file's docstring | Did not actually go up a level | Re-do step 2 — describe the *containing* unit, not the unit itself |
| Output uses class/function names instead of domain terms | Skipped step 1 (didn't read CONTEXT.md) or no glossary exists | Read CONTEXT.md if present; otherwise note its absence and use the domain terms inferable from the code |
| Caller list is empty but module clearly is in use | API is exported through a barrel/index file | Search for re-exports, then trace from there |
| Output is huge | Stopped at the wrong level | Cut to the four-item template strictly; deeper detail belongs to follow-up questions |

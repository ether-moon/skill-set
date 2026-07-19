---
name: zooming-out-on-code
description: Produces a compact, read-only system map of unfamiliar project code in domain vocabulary. Use when a user asks for the big picture, a module tour, where code fits, what calls it, what it depends on, or orientation before changing an unfamiliar area.
allowed-tools: Read, Grep, Glob
---

# Zooming Out on Code

## Boundary

Orient one level above the requested symbol, file, module, or package. This is read-only analysis. Do not modify files, recommend refactors, identify architecture candidates, debug a defect, or propose next steps.

If `CONTEXT.md` or relevant ADRs exist, read them as vocabulary and decision evidence only. Never create or update them. When they are absent, infer terms from package names, public types, tests, and callers and record uncertainty.

## Process

1. Identify the containing unit one level above the requested target.
2. State its single domain responsibility from observable code and tests.
3. Find direct callers through exports, imports, references, routes, or configuration.
4. Read direct dependencies only; do not expand transitive graphs.
5. List siblings in the same package or layer and their distinct responsibilities.
6. Separate unresolved or conflicting evidence into Unknowns.
7. Stop after the five-field map.

Prefer symbol-aware references when available, then targeted text search. Search re-exports if direct callers appear empty. Cite concrete paths; distinguish evidence from inference.

## Output

```text
## Responsibility
<one domain-level sentence>

## Callers
- <path or symbol> — <why it calls this unit>

## Dependencies
- <path or external boundary> — <what this unit needs>

## Siblings
- <same-layer unit> — <its separate responsibility>

## Unknowns
- <missing, dynamic, or contradictory evidence>
```

Use exactly these sections: Responsibility, Callers, Dependencies, Siblings, Unknowns. If a section has no verified item, say `None found` and explain the search limit under Unknowns.

## Stop Conditions

- The target is a top-level package: describe its product role; do not expand into product strategy.
- A dependency or caller requires unrelated-system exploration: record it under Unknowns.
- The user asks for recommendations: finish the orientation map first and let the user make a separate request.

Use the user's language for explanations. Keep identifiers and paths exact.

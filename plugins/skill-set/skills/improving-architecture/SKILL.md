---
name: improving-architecture
description: Finds and ranks evidence-backed deep-module and seam refactor candidates in a codebase. Use when a user asks for architecture improvement opportunities, tangled-code analysis, modularity, testability seams, deep or shallow modules, or a ranked refactor shortlist.
allowed-tools: Read, Grep, Glob
---

# Improving Architecture

## Boundary

Return read-only ranked candidates. Do not edit code, design a final interface, write an implementation plan, select a candidate for the user, or invoke another skill.

Read `CONTEXT.md` and relevant ADRs if they exist, using them only as vocabulary and constraint evidence. Never create or update those files.

## Vocabulary

- **Depth** — behavior hidden behind a smaller interface.
- **Shallow module** — callers must understand nearly as much complexity as the implementation.
- **Seam** — a bounded interface where behavior can vary without editing callers.
- **Locality** — related knowledge, change, and failure are concentrated.
- **Leverage** — multiple callers stop repeating knowledge or coordination.

See `reference/deep-modules.md` for examples and `reference/deletion-test.md` for the deletion test.

## Process

1. Orient to domain terms and constraints from existing context, ADRs, tests, and package structure.
2. Trace areas where one concept requires many files, callers repeat ordering or invariants, interfaces leak implementation knowledge, or testing requires internal coupling.
3. Apply the deletion test to suspected pass-through modules: if deleting the module removes complexity, it is shallow; if complexity reappears across callers, it may be earning its interface.
4. Gather path-and-line evidence for every claim. Drop speculative candidates without direct evidence.
5. Rank candidates by combined locality gain, leverage gain, risk, and ability to complete as a bounded refactor.
6. Return only the candidate report and stop after presenting candidates.

## Candidate Format

```text
## 1. <candidate in domain vocabulary>

- Files: <exact paths>
- Evidence: <observed duplication, ordering, leakage, or test friction with locations>
- Problem: <why the current boundary creates maintenance or caller complexity>
- Proposed seam: <plain-language boundary, not a designed API>
- Locality gain: <knowledge/change concentrated>
- Leverage gain: <what callers no longer coordinate>
- Test impact: <tests preserved, added, or moved to an observable boundary>
- Risks: <migration, compatibility, performance, ownership, or uncertainty>
```

Every item must contain Files, Evidence, Problem, Proposed seam, Locality gain, Leverage gain, Test impact, and Risks. Omit any candidate that cannot support all eight fields. Keep the shortlist ranked and bounded; five strong candidates are preferable to a comprehensive catalog.

## Failure Handling

- Existing ADR conflicts: cite the ADR in Evidence and state the conflict in Risks; do not relitigate it silently.
- Missing callers or tests: record the evidence gap in Risks and lower the rank.
- Candidate requires a ground-up rewrite: split it into a bounded seam or omit it.
- Interface shape is uncertain: describe only the capability boundary in Proposed seam.

Use the user's language for the report. Keep paths, identifiers, and canonical architecture terms exact.

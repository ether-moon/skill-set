# Codebase Cross-Reference

Use read-only repository evidence to answer present-state questions before asking the user.

## High-Value Checks

- **Existing capability** — search for the proposed helper, parser, retry, validator, or boundary.
- **Stated versus actual behavior** — read the relevant implementation and tests.
- **Invariant** — look for guards and error paths that assume the opposite.
- **Dependency direction** — inspect imports, exports, registrations, and runtime wiring.
- **Vocabulary** — search for an established name before accepting a new term.
- **Directive or ADR constraint** — read existing decisions without modifying them.

## Tool Choice

| Question | First approach |
|---|---|
| Exact symbol definition or caller | symbol-aware definition/references when available |
| Broad behavior or term | targeted text search |
| Package structure or siblings | file listing/glob |
| Current behavior | implementation plus closest tests |
| Historical intent | existing ADRs and commit context, if available |

## Bound the Search

Stop expanding that search when evidence is unavailable after targeted checks, requires an unrelated subsystem, or concerns future policy rather than current code. Add the unresolved intent question to the current decision batch with what was searched, the missing fact, and a recommendation. Finish the other bounded checks before presenting all currently identifiable questions together.

Report evidence concisely:

```text
Evidence: `src/lib/withRetry.ts` already provides bounded exponential backoff.
Implication: the plan's new retry helper would duplicate it.
Decision: reuse the existing helper or replace it?
Recommendation: reuse it and extend only the missing jitter option.
```

Never modify code, CONTEXT.md, or ADRs during cross-reference.

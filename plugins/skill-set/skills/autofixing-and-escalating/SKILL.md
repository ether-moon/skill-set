---
name: autofixing-and-escalating
description: Classifies actionable findings from linters, tests, security scans, audits, and PR reviews as obvious or ambiguous, then applies only explicitly authorized fixes. Use when processing one or more externally produced findings, especially when a caller needs a review-only report or a bounded resolution pass.
---

# Autofixing and Escalating

## Purpose

Turn external findings into a complete decision record. This skill classifies and recommends. It mutates only within a capability contract supplied by the user or an orchestrating workflow.

Do not use the classification ceremony for suggestions produced by the current analysis; present those normally.

## Invocation Contract

Start every invocation with this contract:

```text
mode: review-only | resolve-authorized
capabilities:
  edit: true | false
  commit: true | false
  push: true | false
  comment: true | false
scope: explicit paths, PR, or finding set
source: reviewer, tool, scan, or audit
```

Defaults are `mode: review-only` and every capability `false`.

Use `resolve-authorized` only when:

- the user explicitly asks to fix, resolve, or apply the findings; or
- `/skill-set:pr:fix`, `/skill-set:pr:ship`, or another caller explicitly passes that mode and its capabilities.

A capability authorizes only itself. `edit` does not authorize commit; `commit` does not authorize push; `push` does not authorize force; `comment` does not authorize code changes. Missing or unclear scope remains review-only.

## Classify Every Finding

### OBVIOUS

All conditions must hold:

1. The source identifies a specific issue.
2. Correctness is objectively verifiable.
3. Exactly one fix is valid in the stated scope.
4. A reasonable maintainer would not disagree.

Examples include an unused import with no dynamic use, a literal typo, a broken local reference, or a missing keyword required by the documented API.

### AMBIGUOUS

Use AMBIGUOUS when any trade-off, policy choice, hidden side effect, or competing implementation exists. Always classify these as AMBIGUOUS:

- hedged requests such as “might,” “could,” “consider,” or “maybe”;
- multiple valid approaches or architectural/design choices;
- public API or external contract changes;
- data or schema changes, migrations, or serialization changes;
- new, removed, or materially changed dependencies;
- authentication, authorization, privacy, or security policy decisions;
- destructive or difficult-to-recover changes;
- behavior whose correctness depends on missing product or operational context.

Do not use changed-line counts as a correctness proxy. When uncertain, choose AMBIGUOUS.

### SKIP

Skip resolved, duplicate, previously addressed, or informational findings. Preserve source attribution so a skipped result remains auditable.

See `reference/classification.md` for the decision tree and edge cases.

## Severity

Assign severity only to AMBIGUOUS findings:

- **CRITICAL** — security exposure, data loss, destructive behavior, or production-breaking risk.
- **MAJOR** — significant correctness, concurrency, performance, or resource risk.
- **MINOR** — maintainability, naming, organization, documentation, or speculative improvement.

Severity affects ordering, never mutation authority.

## Workflow

1. **Normalize** — deduplicate findings and record source, target, and scope.
2. **Classify** — mark every finding OBVIOUS, AMBIGUOUS, or SKIP before mutation.
3. **Report** — show the full classification; every AMBIGUOUS item includes `Why ambiguous`, severity, alternatives, and a recommendation.
4. **Authorize** — in review-only mode, stop. In resolve-authorized mode, intersect requested work with each capability and scope.
5. **Resolve** — apply authorized OBVIOUS fixes. Apply an AMBIGUOUS fix only after the user explicitly selects that resolution.
6. **Return** — report applied, awaiting decision, failed, and skipped items plus unused capabilities.

Read `reference/resolution.md` for the contract and output formats.

## Ownership Boundaries

This skill does not decide:

- whether work runs sequentially or concurrently;
- whether a commit, push, or public comment should occur;
- how partial results from multiple workers are combined; or
- when a PR/release workflow advances state.

The caller owns orchestration and publication. This skill may perform a separately authorized capability, but it never grants that capability to itself.

## Failure Handling

- If evidence is incomplete, return AMBIGUOUS with the missing evidence.
- If a target changed after classification, stop that item and return a stale-target failure.
- If one authorized fix fails, continue only when the caller's execution policy permits it; never expand scope to recover.
- Never convert an AMBIGUOUS item to OBVIOUS merely to keep an automated workflow moving.

Use the user's language for runtime reports. Keep code, paths, commands, and repository documentation in English.

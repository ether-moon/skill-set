---
name: autofixing-and-escalating
description: Classifies actionable findings from linters, tests, security scans, audits, and PR reviews, automatically applies unambiguous fixes, and pauses only for decisions required by ambiguous findings before applying the complete chosen resolution. Use when processing one or more externally produced findings with the intent to resolve them.
---

# Autofixing and Escalating

## Purpose

Turn external findings into verified fixes and a complete decision record. Editing within the bounded finding scope is the skill's default behavior. Commit, push, and public comment remain separately authorized capabilities.

Do not use the classification ceremony for suggestions produced by the current analysis; present those normally.

## Invocation Contract

Start every invocation with this contract:

```text
mode: resolve-authorized
capabilities:
  edit: true
  commit: true | false
  push: true | false
  comment: true | false
scope: explicit paths, PR, finding set, or targets identified by the findings
source: reviewer, tool, scan, or audit
```

The only supported mode is `resolve-authorized`. Default to `edit: true` and every publication capability `false`. A direct invocation with actionable findings authorizes edits only to the bounded targets identified by those findings.

An orchestrating workflow may pass the same mode and explicit capabilities. Do not accept `edit: false` as a reporting mode; route analysis-only requests to an ordinary report without invoking this skill.

A capability authorizes only itself. `edit` does not authorize commit; `commit` does not authorize push; `push` does not authorize force; `comment` does not authorize code changes. If the findings do not identify a bounded target, treat the missing scope as an AMBIGUOUS decision and do not mutate until it is resolved.

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
3. **Decide** — if any item is AMBIGUOUS, pause before any mutation. Present only the decisions required, each with `Why ambiguous`, severity, alternatives, and a recommendation. Continue the decision dialogue until every AMBIGUOUS item has a selected resolution or is explicitly skipped. Do not ask for approval of OBVIOUS fixes or for a generic proceed confirmation.
4. **Resolve** — when no AMBIGUOUS item exists, apply all OBVIOUS fixes immediately. Otherwise, after every required decision is complete, automatically apply all queued OBVIOUS fixes and every selected AMBIGUOUS resolution in one bounded pass without another confirmation.
5. **Verify** — run the checks needed to verify every applied fix. Keep failures bounded to the original scope.
6. **Return** — report applied, failed, and skipped items plus verification evidence and unused publication capabilities.

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

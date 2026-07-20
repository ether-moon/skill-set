# Resolution Contract

## Input

Require a mode, four independent capabilities, a bounded scope, and finding sources. Apply defaults before examining findings:

```yaml
mode: review-only
capabilities:
  edit: false
  commit: false
  push: false
  comment: false
scope: []
source: unknown
```

An explicit user request to fix or resolve may set `mode: resolve-authorized`; infer only the capabilities necessary for that exact request. A trusted caller may pass the mode and capabilities directly. Never infer mutation authority from the existence of findings.

## Classification Record

Record every item before mutation:

```text
ID: stable identifier
Source: reviewer or tool
Target: path and location
Classification: OBVIOUS | AMBIGUOUS | SKIP
Severity: CRITICAL | MAJOR | MINOR (AMBIGUOUS only)
Issue: observed defect or request
Evidence: objective evidence checked
Why ambiguous: trade-off or missing decision (AMBIGUOUS only)
Recommendation: bounded next action
Required capabilities: edit, commit, push, comment
Status: queued | awaiting-user | applied | failed | skipped
```

## Review-only Result

Return the full record and stop. Use this summary:

```text
Mode: review-only
OBVIOUS: N (not applied)
AMBIGUOUS: N (awaiting decisions)
SKIP: N
Capabilities used: none
```

Do not ask for a generic “proceed?” if the caller requested review only.

## Authorized Resolution

1. Intersect each proposed action with the explicit scope.
2. Check that every required capability is true.
3. Apply OBVIOUS edits only when `edit: true`.
4. Keep every AMBIGUOUS item at `awaiting-user` until its exact alternative is selected.
5. Return the result to the caller after the permitted actions.

If `commit`, `push`, or `comment` is true, perform only the operation explicitly requested by the caller and only after successful edits are known. A failure never enables a broader capability.

## Ownership

The caller owns orchestration: worker count, ordering, retries, isolation, and partial-failure policy. The caller owns publication: commit grouping, push timing, PR comments, and resolve markers. This skill supplies classifications and bounded resolution results; it does not create an execution topology or publication plan.

## Summary

```text
Mode: resolve-authorized
Applied: N
Awaiting user: N
Failed: N
Skipped: N
Capabilities used: edit=[yes/no], commit=[yes/no], push=[yes/no], comment=[yes/no]
Unused authorized capabilities: ...
```

For failures, include the stale state or missing evidence and a recovery action that stays inside the original scope.

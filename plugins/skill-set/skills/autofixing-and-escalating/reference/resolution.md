# Resolution Contract

## Input

Require the resolution mode, the edit capability, three independent publication capabilities, a bounded scope, and finding sources. Apply defaults before examining findings:

```yaml
mode: resolve-authorized
capabilities:
  edit: true
  commit: false
  push: false
  comment: false
scope: targets identified by the findings
source: unknown
```

The skill supports only `resolve-authorized`. Its invocation authorizes `edit: true` for the bounded finding targets; a trusted caller may pass the same mode and narrower scope directly. Reject `edit: false` instead of silently degrading into a reporting workflow. Never infer commit, push, comment, force, or out-of-scope mutation authority from the existence of findings.

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

## Decision Gate

If any item is AMBIGUOUS, keep every fix queued and start a decision dialogue before any mutation. For each AMBIGUOUS item, provide `Why ambiguous`, severity, concrete alternatives, and a recommendation. Ask only for the unresolved choice; never ask whether to proceed with OBVIOUS fixes.

Continue until every AMBIGUOUS item has an exact selected resolution or is explicitly skipped. A skipped choice counts as a completed decision. Do not edit between decision turns.

## Automatic Resolution

1. Intersect each proposed action with the bounded scope.
2. If there are no AMBIGUOUS items, apply every OBVIOUS fix immediately.
3. If there are AMBIGUOUS items, wait until all decisions are complete, then apply every queued OBVIOUS fix and selected AMBIGUOUS resolution automatically without another confirmation.
4. Verify the applied fixes and return the bounded result to the caller.

If `commit`, `push`, or `comment` is true, perform only the operation explicitly requested by the caller and only after successful edits are known. A failure never enables a broader capability.

## Ownership

The caller owns orchestration: worker count, ordering, retries, isolation, and partial-failure policy. The caller owns publication: commit grouping, push timing, PR comments, and resolve markers. This skill supplies classifications and bounded resolution results; it does not create an execution topology or publication plan.

## Summary

```text
Mode: resolve-authorized
Applied: N
Failed: N
Skipped: N
Capabilities used: edit=[yes/no], commit=[yes/no], push=[yes/no], comment=[yes/no]
Unused authorized capabilities: ...
```

For failures, include the stale state or missing evidence and a recovery action that stays inside the original scope.

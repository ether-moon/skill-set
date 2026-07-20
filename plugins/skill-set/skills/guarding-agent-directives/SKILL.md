---
name: guarding-agent-directives
description: Verifies proposed agent-directive additions and audits existing CLAUDE.md, AGENTS.md, and referenced instruction files for bloat, duplication, ambiguity, and placement. Use when adding, changing, or reviewing agent directives or when an agent proposes modifying them.
allowed-tools: Read, Grep, Glob, Edit
---

# Guarding Agent Directives

## Modes

Choose one explicit mode:

- `verify-addition` — evaluate one proposed directive and, after user approval, apply an exact reviewed diff.
- `audit-existing` — read existing directives and return keep, revise, or remove recommendations. This mode is read-only and never changes files.

Default to `audit-existing` for review requests and `verify-addition` only when an addition or modification is proposed.

Do not insert a canonical coding baseline or restore deleted baseline rules. Evaluate only the content in scope.

## Five Questions

Evaluate every proposed addition or audited rule:

| Check | Pass condition |
|---|---|
| Q1 Recurring? | The same project-specific failure is likely across sessions. |
| Q2 Non-obvious? | A capable agent cannot infer it from code, standard practice, or nearby configuration. |
| Q3 Novel? | Existing directives do not already express the same behavior. |
| Q4 Actionable? | Compliance changes observable behavior and can be checked. |
| Q5 Correct location? | The rule is placed at the narrowest scope where it is needed and will actually be loaded. |

Q5 Correct location replaces any requirement that a user policy be unique to one project. Explicit user policy may be valid even when general; placement and context cost still matter.

Read [the detailed criteria](reference/verification.md) for examples.

## verify-addition

1. Identify exact content, intended behavior, target file, and proposer.
2. Read the target and every directive it references; search for duplicates and contradictions.
3. Report PASS/FAIL with evidence for all five questions.
4. If any fail, offer `Add anyway`, `Revise`, and `Don't add`. A user override is authoritative.
5. Recommend the narrowest correct location: existing reference, skill-local reference, or top-level directive only when globally necessary.
6. Show the exact diff before mutation and ask for final confirmation.
7. Apply only the confirmed diff, then show the resulting exact diff.

An autonomous agent proposal never supplies its own approval. Without user confirmation, stop after the report.

## audit-existing

For each in-scope rule, return:

```text
Rule: <quoted or summarized directive with path>
Verdict: keep | revise | remove
Q1–Q5: <evidence>
Reason: <duplication, ambiguity, scope, staleness, or value>
Suggested wording/location: <only for revise>
```

The audit-existing mode is read-only: do not edit, consolidate, remove, or add directives. Present recommendations for user selection.

## Placement

Prefer the narrowest loaded location:

1. an existing task- or domain-specific referenced file;
2. a new focused reference plus one concise link from its parent directive;
3. the top-level CLAUDE.md or AGENTS.md only for rules that affect nearly every session.

Do not create a reference merely to hide low-value text. A rule must pass the other checks first.

## Failure Handling

- Referenced file missing: report the broken directive chain before evaluating placement.
- Duplicate but clearer wording: recommend revise/replace, not another copy.
- Contradiction: quote both rules and leave the choice to the user.
- User override after failure: preserve the rationale, show the exact diff, and respect the decision.
- Batch request in verify-addition: evaluate each addition independently or switch to audit-existing with user agreement.

Write repository directive content in English. Use the user's language for reports and decisions.

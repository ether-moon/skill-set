---
name: guarding-agent-directives
description: Reviews agent directives for necessity, clarity, scope, and authority. Use when adding, revising, or auditing rules in AGENTS.md, CLAUDE.md, or referenced instruction files.
allowed-tools: Read, Grep, Glob, Edit
---

# Guarding Agent Directives

## Scope and Authority

- `audit-existing` is read-only: return keep, revise, or remove recommendations for the requested scope.
- `verify-addition` evaluates proposed additions or modifications and applies only user-authorized changes.

Default to `audit-existing` for reviews. An audit request does not authorize edits. In either mode, do not insert a canonical coding baseline or restore deleted baseline rules.

Distinguish capability guidance, explicit user policy or authority, and environment facts. A general policy can be valid even when a capable agent already knows the practice. Model capability does not supply permission to change that policy.

## Five Questions

| Check | Evidence to seek |
|---|---|
| Q1 Necessity | A recurring failure, explicit policy, or environment constraint the rule addresses. |
| Q2 Added value | Information or behavior missing from the applicable instructions and readily discoverable code or configuration; check semantic duplicates. |
| Q3 Clarity | Observable behavior with a clear trigger, rather than a vague aspiration. |
| Q4 Scope and cost | The narrowest loaded location, without unnecessary reads, tests, or approval requests. |
| Q5 Authority and completion | Permission to finish the intended work and a stop at the actual authority boundary. |

For capability guidance, distinguish observed failures from plausible risks. Do not assert that a newer model makes a rule obsolete without evidence. For explicit policy, evaluate clarity, duplication, and placement without treating familiar practice as a reason to revoke it.

Read [verification examples](reference/verification.md) when a judgment needs clarification.

## Inspect and Recommend

Read the target, applicable parent directives, and relevant references or authoritative code and configuration. Reuse current inspected material; reread when sources change, context is missing, freshness is uncertain, or evidence conflicts. Cover the entire requested chain for a full audit. Report missing references and inspection limits.

Evaluate each in-scope rule using the five questions. Report the rule and path, keep/revise/remove verdict, and a concise reason. For revisions, include suggested wording or location. Group shared evidence and explain material failures or uncertainty; give a full Q1–Q5 report when requested.

Prefer an existing relevant reference over a new file. Use a top-level directive for rules needed in nearly every session, and a focused reference with a clear loading condition for task-specific rules. Moving low-value text into a reference does not justify keeping it.

For a failed addition, offer `Add anyway`, `Revise`, and `Don't add`; a user override is authoritative. Resolve contradictions using applicable instruction priority and explicit user decisions. If requirements, external behavior, or authority remain ambiguous, show both rules and ask for the unresolved choice. Do not invent a compromise. For an undocumented exception, ask for its authoritative scope and leave unknown paths, keys, and namespaces unspecified in proposed wording.

## Apply Authorized Changes

Show the exact diff for review. If the user already authorized that exact change, apply it without asking again. When the user authorizes a scoped revision, complete it within that scope; ask only for an unresolved policy choice or an expansion of authority. Honor an explicit request to stop before editing.

An autonomous agent proposal never supplies its own approval. Without user authorization, stop after the report and proposed diff. For a batch, evaluate each change and identify which are authorized.

Apply only authorized changes, verify the result against the requested scope, and return the resulting exact diff. Record any user override without adding unrelated policy.

Write repository directive content in English. Use the user's language for reports and decisions.

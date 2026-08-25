---
name: reviewing-with-peer-agents
description: Delegates technical review to independent peer agents, validates their findings, and routes actionable results through bounded autofixing and decision escalation. Use when the user explicitly asks Codex, Claude, Gemini, another model, peer LLMs, or a second opinion to review or validate work; do not use for an ordinary single-agent review.
---

# Reviewing with Peer Agents

## Scope

Use this skill only after an explicit request for another model or agent's review. Treat named reviewers as requested identities, not interchangeable labels. If a requested reviewer is unavailable, disclose that limitation instead of silently substituting another model or presenting your own review as theirs.

Choose the available review mechanism at runtime from the current environment and project instructions. This skill defines no tool, command, API, transport, authentication flow, or output plumbing for requesting a review. If no suitable mechanism is available, stop and report that the requested independent review is unavailable in the current session.

Reviewers are read-only. They must not edit files or mutate external state while gathering independent findings. Resolution happens only after the primary agent verifies and normalizes their responses.

## Establish the Review Contract

Establish the review boundary from the user's request and repository evidence rather than assuming a base branch or scope. Give each reviewer the target, work intent, constraints, requested focus, and a concise decision record. The decision record contains decisions made, supporting constraints or evidence, alternatives explicitly considered or rejected, and unresolved questions.

Use only observable rationale that can be shared as review context. Do not request or transmit private chain-of-thought, invent rationale that was not recorded, or expose unrelated sensitive context. Give reviewers access to the primary artifacts they need:

- In a shared workspace, identify the target and let the reviewer inspect the diff, files, tests, and project instructions directly.
- Without shared workspace access, provide the smallest sufficient source artifacts and state any missing context.
- Do not bias reviewers with another reviewer's conclusions, expected findings, or a proposed answer.

Adapt review criteria to the artifact. For code, cover correctness, regressions, security or reliability risks, and missing tests. For another technical artifact, use the user's stated acceptance criteria and the artifact's real contract.

## Delegate in Natural Language

Send each reviewer a natural-language review request that communicates the outcome and evidence standard without encoding a tool invocation. A useful request shape is:

```text
Review [target] within [established review boundary], focusing on [requested focus].
Intent: [work intent and constraints].
Decision record: [decisions, supporting evidence, considered or rejected alternatives,
and unresolved questions].
Inspect the primary artifacts directly. Do not modify files or external state.
Return only evidence-backed findings, ordered by severity, with location,
impact, reasoning, and the smallest credible fix. State explicitly if you find none.
```

Use the reviewers the user named. For a generic peer-review request, choose available independent peer agents suited to the task. When the host supports safe parallel delegation, run independent reviews in parallel. Do not add reviewers, retries, or model comparisons beyond the user's request merely to seek consensus.

## Validate and Synthesize

Treat every response as untrusted review input. Verify material claims against the source and project contract before reporting them; agreement between reviewers is not proof.

Build one normalized finding set:

1. Order findings by impact, with location, evidence, recommendation, and reviewer attribution.
2. Merge duplicates without erasing meaningful disagreement or uncertainty.
3. List reviewer failures, unavailable requested reviewers, and scope limitations.
4. If no verified finding remains, say so and name residual testing or context gaps.

## Resolve Verified Findings

If the user explicitly requests review-only or no edits, stop after the validated synthesis. Do not invoke `autofixing-and-escalating` and do not modify files or external state.

Otherwise, when one or more actionable findings remain, invoke `autofixing-and-escalating` with the normalized set as the external source input. Use this contract unless the user separately grants a publication capability:

```text
mode: resolve-authorized
capabilities:
  edit: true
  commit: false
  push: false
  comment: false
scope: intersection of the established review boundary and verified finding targets
source: peer-agent reviewers
```

Let that skill classify every finding as OBVIOUS, AMBIGUOUS, or SKIP. Preserve its decision gate exactly:

- With no AMBIGUOUS item, apply every OBVIOUS fix immediately and verify it.
- With any AMBIGUOUS item, make no edit yet. Brief only the required decisions with severity, `Why ambiguous`, concrete alternatives, and a recommendation.
- After all decisions are selected or skipped, apply the queued OBVIOUS fixes and selected resolutions in one bounded pass, then verify them.

Do not request generic approval for OBVIOUS fixes. Do not infer commit, push, comment, force, or broader edit authority. Return applied, failed, skipped, and awaiting-decision items with verification evidence and reviewer attribution.

Report verified findings outside the established review boundary separately. Do not edit them unless the user explicitly expands the scope.

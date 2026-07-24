# Testing and Isolation Policy

## Table of Contents

- [Responsibility](#responsibility)
- [Test in Layers](#test-in-layers)
- [Structural Boundary](#structural-boundary)
- [Behavioral Contracts](#behavioral-contracts)
- [Efficient Case Design](#efficient-case-design)
- [Isolated Execution](#isolated-execution)
- [Campaign Execution](#campaign-execution)
- [Trace Review](#trace-review)

## Responsibility

Delegate test generation, budgeted execution, grading, aggregation, and review to a compatible `skill-creator` when supported. The preflight envelope remains authoritative; a creator that cannot honor it may produce artifacts but must not launch model invocations. This reference defines the common evidence policy and local fallback.

## Test in Layers

Use the cheapest layer that can disprove the claim:

1. **Structure** — frontmatter, paths, references, fixtures, and scripts validate.
2. **Deterministic behavior** — scripts parse, dry-run, mutate, recover, and report errors correctly.
3. **Triggering** — realistic positive requests and plausible near misses select the right entry point.
4. **Functional behavior** — the complete workflow produces the required outcome.
5. **Safety** — absent or narrower authority cannot cause forbidden effects.
6. **Comparison** — when separately approved, the candidate improves or preserves the declared baseline.

Do not substitute prose claims for executing a script or inspecting an artifact.

## Structural Boundary

Run the repository-provided validator first and a host-provided validator when available. The repository validator owns portable and project invariants; host validators add surface-specific checks. A creator's validator may execute either, but it does not replace them.

At minimum verify the directory and frontmatter name, description scope, linked paths, executable resources, dependency diagnostics, safe previews for mutations, and real supported tool syntax.

## Behavioral Contracts

Express each case as observable state:

```text
Given: reset fixture state and explicit authority
When: the skill follows its normal entry point
Then: required output, state transition, scope, and recovery behavior
```

The project authoring skill owns change detection, safety contracts, and representative-case selection. Keep each common case focused on one observable regression risk rather than repeating a generic command or failure matrix.

Verify both what happened and what did not happen. Command logs and state inspection are stronger safety evidence than a rubric that merely says the run was safe.

## Efficient Case Design

- Give each case one regression risk that differs from every existing case.
- Do not repeat the full policy or a long command matrix in every prompt; reference concise task-local fixtures and contracts.
- Move checks for strings, file existence, tool calls, and state transitions into deterministic tests.
- Merge expectations that measure the same meaning.
- Leave only genuinely qualitative judgment to a model grader.
- Use at most one batched model-grader call for one output; do not launch one grader per expectation.
- Do not add a case that duplicates an existing deterministic test or cannot reproduce an actual or credible observed failure.
- After a fix, rerun only affected cases. Do not automatically rerun the full suite.

## Isolated Execution

Start every approved case, comparison arm, and trial in a fresh eval-worker context with reset fixtures and a separate output directory. Pass raw task artifacts and the skill under test; do not leak the expected answer, suspected bug, intended fix, or earlier conclusions.

Use disposable repositories, mock services, or scoped test accounts for stateful workflows. Preserve unrelated user changes and clean trial artifacts that a later run could discover.

## Campaign Execution

Treat a full suite, repeated trials, cross-model evaluation, cross-environment portability check, or broad optimizer pass as a campaign. Run it only after an explicit request, a stated purpose, and a separate accepted preflight budget.

Do not infer a campaign from successful deterministic validation, development smoke, or focused comparison. Do not reuse approval from any earlier stage.

When a campaign needs qualitative grading, batch the qualitative expectations for each output into one model-grader call. Hold cases, fixtures, grants, and approved run counts constant across comparison arms.

## Trace Review

Inspect whether the run:

- selected `creating-skills` as the primary entry point for overlapping authoring requests;
- delegated only supported work inside the accepted preflight plan;
- loaded only relevant references and reused bundled scripts;
- ran deterministic validation before any development smoke;
- kept development smoke candidate-only and single-trial;
- added a baseline only for an approved focused comparison;
- started a campaign only after an explicit request and separate budget;
- stopped at the intended authority boundary; and
- returned enough evidence for the policy gate.

Move only critical orchestration and safety rules into `SKILL.md`. Remove guidance that the creator already owns or that never changes outcomes.

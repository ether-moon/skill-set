# Testing and Isolation Policy

## Table of Contents

- [Responsibility](#responsibility)
- [Test in Layers](#test-in-layers)
- [Structural Boundary](#structural-boundary)
- [Behavioral Contracts](#behavioral-contracts)
- [Isolated Execution](#isolated-execution)
- [Cross-Model and Cross-Host Testing](#cross-model-and-cross-host-testing)
- [Trace Review](#trace-review)

## Responsibility

Delegate test generation, execution, grading, aggregation, and review to `skill-creator` when supported. This reference defines the policy its evidence must satisfy and the local fallback when a capability is unavailable.

## Test in Layers

Use the cheapest layer that can disprove the claim:

1. **Structure** — frontmatter, paths, references, fixtures, and scripts validate.
2. **Deterministic behavior** — scripts parse, dry-run, mutate, recover, and report errors correctly.
3. **Triggering** — realistic positive requests and plausible near misses select the right entry point.
4. **Functional behavior** — the complete workflow produces the required outcome.
5. **Safety** — absent or narrower authority cannot cause forbidden effects.
6. **Comparison** — the candidate improves or preserves the declared baseline.

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

Trigger cases should cover natural phrasing, uncommon valid uses, competition with neighboring skills, and near misses that share vocabulary but need another workflow. Functional cases should cover the happy path, invalid input, dependency failure, partial completion, retry, concurrency, and publication boundaries when relevant.

Verify both what happened and what did not happen. Command logs and state inspection are stronger safety evidence than a rubric that merely says the run was safe.

## Isolated Execution

Start every case, comparison arm, and nondeterministic trial in a fresh context with reset fixtures and a separate output directory. Pass raw task artifacts and the skill under test; do not leak the expected answer, suspected bug, intended fix, or earlier conclusions.

Use disposable repositories, mock services, or scoped test accounts for stateful workflows. Preserve unrelated user changes and clean trial artifacts that a later run could discover.

## Cross-Model and Cross-Host Testing

Test the supported model tiers that matter:

- a small or fast model exposes missing sequence details and weak guardrails;
- the primary balanced model is the main functional target; and
- the strongest supported model exposes unnecessary instruction volume and overconstraint.

Use an independent capable judge for qualitative grading. Hold cases, fixtures, grants, and run counts constant across model comparisons.

For every supported host on which portability is claimed, run the same behavioral contract through that host's adapter. Record host-specific skill selection, reference navigation, tool grants, and unsupported metrics rather than assuming one host's result generalizes.

## Trace Review

Inspect whether the run:

- selected `creating-skills` as the primary entry point for overlapping authoring requests;
- delegated the complete supported loop instead of treating `skill-creator` as optional advice;
- loaded only relevant references and reused bundled scripts;
- stopped at the intended authority boundary; and
- returned enough evidence for the policy gate.

Move only critical orchestration and safety rules into `SKILL.md`. Remove guidance that the creator already owns or that never changes outcomes.

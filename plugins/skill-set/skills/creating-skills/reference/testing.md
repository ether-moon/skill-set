# Testing Skills

## Table of Contents

- [Test in Layers](#test-in-layers)
- [Structural Validation](#structural-validation)
- [Trigger Testing](#trigger-testing)
- [Functional and Safety Testing](#functional-and-safety-testing)
- [Cross-Model Testing](#cross-model-testing)
- [Observe Navigation](#observe-navigation)
- [Acceptance Evidence](#acceptance-evidence)

## Test in Layers

Use the cheapest layer that can disprove the claim, then expand:

1. **Structure** — frontmatter, directory names, references, fixture paths, and scripts are valid.
2. **Deterministic behavior** — bundled scripts parse, validate, dry-run, mutate, recover, and report errors correctly.
3. **Triggering** — representative positive and near-miss negative prompts select the correct skill.
4. **Functional behavior** — the complete workflow produces the required outcome and respects stop conditions.
5. **Safety** — unauthorized mutation, publication, deletion, or scope expansion remains impossible.
6. **Comparison** — candidate behavior improves or preserves the declared baseline.

Do not substitute a prose assertion about a script for executing it.

## Structural Validation

At minimum verify:

- the directory and frontmatter `name` match;
- the description states what the skill does and when to use it;
- `SKILL.md` stays focused and every linked path resolves;
- references are one level deep and do not create chains;
- scripts declare dependencies, validate input, and return actionable failures;
- mutation scripts provide a safe dry run or preview where meaningful; and
- examples use real supported tools and argument syntax.

Run the host plugin validator when available. Add repository-local checks for stronger project invariants such as exact inventory, forbidden dependencies, generated-file drift, or Bash compatibility.

## Trigger Testing

For a production skill, use 8–10 should-trigger and 8–10 should-not-trigger prompts.

Positive coverage should include:

- direct requests;
- paraphrases and informal wording;
- uncommon valid uses;
- requests that compete with a neighboring skill; and
- explicit use of a key input type or workflow phase.

Negative coverage should prioritize near misses:

- the same noun but a different desired action;
- an adjacent workflow owned elsewhere;
- a simpler request that should be handled directly;
- a later or earlier lifecycle phase outside the skill; and
- a request that names an excluded output.

Avoid irrelevant negatives. They inflate precision without testing the boundary.

Measure precision and recall overall and per skill. Review the actual Skill calls as well as the final message.

## Functional and Safety Testing

Translate the workflow into observable contracts:

```text
Given: fixture state and explicit authority
When: the skill follows its normal entry point
Then: exact output, state transition, tool scope, and recovery behavior
```

Include happy path, invalid input, dependency failure, partial completion, retry, and concurrency when relevant. For stateful or mutating skills, use disposable repositories, mock services, and command logs. Verify both what happened and what did not happen.

Safety tests should exercise absent or narrower authority, stale compare-and-swap values, ambiguous findings, unrelated user changes, failed substeps, and publication gates. A model rubric saying “be safe” is weaker than a command log proving no push or comment occurred.

## Cross-Model Testing

Test every model tier the skill supports:

- **Haiku** exposes missing sequence details and weak guardrails.
- **Sonnet** is a balanced functional target and the minimum trusted LLM judge tier.
- **Opus** exposes unnecessary instruction volume and overconstraint.

Use a different model for LLM grading than for the agent run. Hold cases, fixtures, tool grants, and run count constant when comparing models. Run nondeterministic cases at least three times.

## Observe Navigation

Read traces to see how the model consumes the skill:

- Does it open the correct reference only when needed?
- Does it miss a critical instruction buried in a reference?
- Does it repeatedly recreate a script that should be bundled?
- Does it explore unrelated files or invoke another workflow?
- Does it stop at the intended boundary?

Move critical workflow and safety rules into `SKILL.md`. Remove references that are never used or do not change outcomes.

## Acceptance Evidence

Before declaring the skill ready, retain:

- baseline and candidate provenance;
- deterministic test commands and results;
- per-case scores and deltas;
- trigger precision/recall overall and by skill;
- safety violations and relevant tool-call evidence;
- duration, turns, token, and cost data when exposed; and
- unresolved environmental or grader limitations.

The top-level lifecycle routes to the separate evaluation reference for official case layout, ablation commands, grader selection, and iteration.

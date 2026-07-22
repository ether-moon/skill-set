---
name: creating-skills
description: This skill is the primary entry point for creating, modifying, evaluating, and governing the lifecycle of agent skills. Use cases include any new or existing SKILL.md work, including trigger design, structure and resources, evals, benchmarks, description optimization, troubleshooting, or retirement, even when skill-creator is available. It takes precedence over skill-creator for overlapping requests, delegates the complete supported execution loop, and retains project policy, evidence requirements, and final acceptance.
---

# Creating Skills

## Role and Ownership

Use this skill as the primary entry point for both new skill and existing skill work, especially whenever a request matches both `creating-skills` and an available `skill-creator`.

When `skill-creator:skill-creator` is available, invoke it before local artifact-producing work and delegate the complete loop it supports: intent discovery, use cases and triggers, skill structure, scripts and other resources, drafting, evaluation cases, baseline runs, grading, benchmark analysis, human review, iteration, description optimization, and packaging.

Retain ownership here for:

- target surfaces, repository policy, and durable artifact layout;
- user authority, safety invariants, and mutation or publication boundaries;
- required evidence and acceptance thresholds;
- gaps between the creator's output and the project contract; and
- the final accept, reject, or retire decision.

Treat delegated artifacts and results as candidates. Inspect them before filling gaps, and do not duplicate a delegated stage merely to keep control local. Judge an available creator by the capabilities it exposes in the active environment, not by the product name or packaging of one installation.

## Establish the Orchestration Contract

Before delegation, define:

1. The target hosts, repository paths, and project instructions.
2. The user's intended workflows, inputs, outputs, and trigger boundaries.
3. Whether the skill is a **capability skill** or a **preference skill**.
4. Allowed tools, file mutations, external effects, and publication authority.
5. Required validators, evaluation adapter, baselines, evidence, and acceptance thresholds.
6. The artifacts and unresolved decisions the creator must return.

Use project-native formats as the durable source of truth. Let the creator use its supported working format internally, then adapt returned evidence at the boundary instead of forcing its private workspace layout into the repository.

Make durable content policies explicit in the orchestration contract and verify them again at the policy gate; do not expect a delegated creator to rediscover them from the workspace.

## Delegate the Execution Loop

Give the creator the orchestration contract and ask it to own the complete supported authoring and evaluation lifecycle. Require inspectable outputs: changed artifacts, test cases, baseline identity, per-case results, raw traces or logs, benchmark metrics, user feedback when collected, and unresolved limitations.

If the creator supports only part of the contract, preserve its valid output and execute only the unsupported stages locally. If it is unavailable or not installed, use the local fallback below without asking the user to install a particular product.

## Apply the Policy Gate

Evaluate returned evidence across four dimensions defined in `reference/evaluation.md`:

- **Outcome** — the skill produces a usable result.
- **Conformance** — it follows the user's and project's rules.
- **Safety** — it stays within authority and mutation boundaries.
- **Efficiency** — it avoids material tool, token, retry, latency, or cost regressions.

Grade outcomes rather than incidental paths. Require a particular tool or order only when it is itself a safety invariant or external contract. Inspect traces and artifacts, not only aggregate scores.

Classify failures before asking the creator to iterate. Accept only when declared thresholds hold and no grader, fixture, environmental, or missing-evidence defect hides a regression.

## Preserve Long-Term Value

- For a **capability skill**, prove a useful delta against a no-skill baseline and periodically rerun that arm after release. Retire the skill when it no longer provides material outcome, safety, or efficiency value.
- For a **preference skill**, test fidelity to the current human workflow and periodically check for process drift. Model capability alone does not make the preference obsolete.
- Promote stable development evaluations into regression cases. Turn each reproducible field failure into a case rather than another paragraph of speculative instruction.
- Run the same behavioral contract on every host for which portability is claimed; host-specific adapters may differ, but the outcome and safety requirements do not.

## Local Fallback

The workflow must remain usable without an external creator. With ordinary host capabilities:

1. Produce the smallest skill structure and resources that satisfy the orchestration contract.
2. Run repository and host-provided validators, then the available evaluation adapter against the declared baseline.
3. Use deterministic checks before qualitative grading, keep nondeterministic trials isolated, and retain per-case evidence.
4. Classify failures, make the smallest general correction, rerun affected cases, then rerun the suite.
5. Stop at the same policy gate used for delegated work.

The portable fallback must not require Claude Code, the `claude` CLI, vendor-specific environment variables, or a vendor-only installation layout. Report unavailable model evaluation honestly while keeping deterministic validation and runnable cases ready.

## Handoff

Validate every linked path and executable resource. Confirm that the creator's temporary formats have been translated into the project's durable structure, the relevant regression suite is green, and `reference/checklist.md` has no unresolved item.

## References

- [Portable and project structure policy](reference/structure.md)
- [Supplemental workflow patterns](reference/patterns.md)
- [Evaluation policy and acceptance](reference/evaluation.md)
- [Testing and isolation policy](reference/testing.md)
- [Orchestration troubleshooting](reference/troubleshooting.md)
- [Completion checklist](reference/checklist.md)

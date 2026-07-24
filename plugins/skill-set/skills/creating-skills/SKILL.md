---
name: creating-skills
description: This skill is the primary entry point for creating, modifying, evaluating, and governing the lifecycle of agent skills. Use cases include any new or existing SKILL.md work, including trigger design, structure and resources, evals, benchmarks, model-invocation budgeting, token or cost regressions, description optimization, troubleshooting, or retirement, even when skill-creator is available. It takes precedence over skill-creator for overlapping requests, delegates supported work within an explicit evaluation budget, and retains project policy, evidence requirements, and final acceptance.
---

# Creating Skills

## Role and Ownership

Use this skill as the primary entry point for both new skill and existing skill work, especially whenever a request matches both `creating-skills` and an available `skill-creator`.

When a compatible `skill-creator` is available, invoke it before local artifact-producing work and delegate only the stages it supports within the current evaluation budget: intent discovery, use cases and triggers, skill structure, scripts and other resources, drafting, evaluation cases, grading, benchmark analysis, human review, separately authorized iteration, description optimization, and packaging.

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
5. Required validators, evaluation stage, evaluation adapter when available, evidence, and acceptance thresholds.
6. The artifacts and unresolved decisions the creator must return.

Use project-native formats as the durable source of truth. Let the creator use its supported working format internally, then adapt returned evidence at the boundary instead of forcing its private workspace layout into the repository.

Make durable content policies explicit in the orchestration contract and verify them again at the policy gate; do not expect a delegated creator to rediscover them from the workspace.

## Gate Model Evaluation

Treat every fresh eval worker, qualitative judge, optimizer, or other model-backed task as a model invocation. Deterministic validators, parsers, and aggregation scripts do not count as model invocations.

Keep evaluation stages separate and run only the stage currently authorized:

1. **Deterministic validation** — validate structure, scripts, fixtures, schemas, and objective assertions without model invocations.
2. **Development smoke** — run only changed or highest-signal cases, candidate-only, once each, within the default budget.
3. **Focused comparison** — add a baseline only for cases that need it, with a separate purpose and freshly approved budget.
4. **Campaign** — run a full suite, repeated trials, or cross-model evaluation only after an explicit request and a separate budget.

Do not advance stages automatically or reuse approval from an earlier stage. Do not add cases, arms, trials, graders, optimizers, models, retries, or iterations after approval.

Before any model invocation, run the stateless `scripts/plan_eval_budget.py` preflight with the planned cases, arms, trials, judge calls, optimizer calls, and other calls. It computes:

```text
execution calls = cases × arms × trials
total calls = execution calls + judge calls + optimizer calls + other calls
projected tokens = total calls × estimated tokens per call
```

The default limits are 4 total calls and 100,000 projected tokens. Use the recent equivalent-trace p95 when available; otherwise use the 25,000-token fallback. If either limit is exceeded, the planner exits with code 2 and no model invocation may start. `max-total-tokens` is a conservative preflight estimate, not a runtime hard cap.

Do not add provider-specific adapters, capability-negotiation protocols, post-call token-debit state machines, execution-history databases, provider token normalization, automatic retries, or automatic iterations. Keep project-specific change detection, safety contracts, and representative-case selection in the project authoring skill.

## Delegate the Execution Loop

Give the creator the orchestration contract and the current stage's budget envelope. Ask it to own the supported work without expanding that envelope. Require inspectable outputs: changed artifacts, test cases, baseline identity when approved, per-case results, raw traces or logs, benchmark metrics, user feedback when collected, and unresolved limitations.

If the creator cannot honor the budget, delegate artifact production but not model invocation. If it supports only part of the contract, preserve its valid output and execute only the unsupported work locally. If it is unavailable, use the local fallback below without requiring a particular product.

## Apply the Policy Gate

Evaluate returned evidence across four dimensions defined in `reference/evaluation.md`:

- **Outcome** — the skill produces a usable result.
- **Conformance** — it follows the user's and project's rules.
- **Safety** — it stays within authority and mutation boundaries.
- **Efficiency** — it avoids material tool, token, retry, latency, or cost regressions.

Grade outcomes rather than incidental paths. Require a particular tool or order only when it is itself a safety invariant or external contract. Inspect traces and artifacts, not only aggregate scores.

Classify failures before proposing any separately authorized follow-up. Accept only when declared thresholds hold and no grader, fixture, environmental, or missing-evidence defect hides a regression.

## Preserve Long-Term Value

- For a **capability skill**, use a focused comparison only when proving value or preventing a specific regression requires a baseline. Retire the skill when approved evidence shows no material outcome, safety, or efficiency value.
- For a **preference skill**, test fidelity to the current human workflow when that question is explicitly in scope. Model capability alone does not make the preference obsolete.
- Promote stable development evaluations into regression cases. Turn each reproducible field failure into a case rather than another paragraph of speculative instruction.
- Test portability only as an explicitly requested campaign with its own budget.

## Local Fallback

The workflow must remain usable without an external creator. With ordinary host capabilities:

1. Produce the smallest skill structure and resources that satisfy the orchestration contract.
2. Run repository and environment-provided validators, then a budgeted development smoke only when that stage is authorized and an evaluation adapter is available.
3. Use deterministic checks before qualitative grading and retain per-case evidence.
4. Classify failures, make the smallest general correction, and rerun only affected cases.
5. Stop at the same policy gate used for delegated work.

The portable fallback must not require a vendor-specific CLI, environment variable, or installation layout. Report unavailable model evaluation honestly while keeping deterministic validation and runnable cases ready.

## Handoff

Validate every linked path and executable resource. Confirm that temporary formats have been translated into the project's durable structure, the approved regression scope is green, and `reference/checklist.md` has no unresolved item.

## References

- [Portable and project structure policy](reference/structure.md)
- [Supplemental workflow patterns](reference/patterns.md)
- [Evaluation policy and acceptance](reference/evaluation.md)
- [Testing and isolation policy](reference/testing.md)
- [Orchestration troubleshooting](reference/troubleshooting.md)
- [Completion checklist](reference/checklist.md)

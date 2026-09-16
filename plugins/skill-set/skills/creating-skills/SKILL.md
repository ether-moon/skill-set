---
name: creating-skills
description: Creates, revises, and evaluates agent skills. Use for SKILL.md authoring, trigger tuning, skill evaluations and benchmarks, or retirement decisions. The primary entry point when requests overlap with skill-creator.
---

# Creating Skills

## Scope and Completion

Use this as the primary entry point for new skill and existing skill work; `skill-creator` is an optional authoring capability. Preserve the user's requested hosts, paths, names, workflows, and publication boundaries.

Establish the requested outcome, relevant use cases and triggers, and the evidence needed to finish. Resolve implementation choices from code and established conventions. Ask when available evidence cannot settle uncertainty that changes requirements, externally observable behavior, or authority. A narrow edit needs a focused correction and validation, not a full lifecycle plan.

Complete authorized local edits, fix resulting validation failures, and rerun affected deterministic checks. Stop for unresolved policy decisions or actions beyond authority. A review-only request remains read-only. Do not treat local completion as permission to publish or run model evaluations.

## Author the Smallest Useful Skill

Assume the model can choose ordinary implementation steps. Include non-obvious context, explicit preferences, operational constraints, and completion conditions that change observable behavior. Prescribe exact tools or order only for an external contract, fragile operation, or user requirement.

Distinguish **capability skill** guidance from **preference skill** policy; a skill may contain both. Capability guidance needs evidence of added value. Model improvement alone does not invalidate a human preference or authority boundary.

Keep descriptions short and specific to selection. Put shared constraints in `SKILL.md` and conditional detail in references with clear reading conditions. Point to authoritative code, configuration, or document sections instead of copying their inventories. Preserve non-obvious contracts and rationale. Add scripts only when repeated or fragile deterministic work justifies them.

When authoring durable artifacts, read [structure and content policy](reference/structure.md). Preserve project formats and content policies through the contract and policy gate, including English repository content and user-language runtime output.

## Use a Creator When It Helps

Use a compatible `skill-creator` when its supported structure, resource generation, or evaluation capabilities materially help, or when the user requests delegation. Handle self-contained edits directly even when a creator is available.

When delegating, pass the target, required artifacts, relevant project policy, authority, and any approved model-call budget. Delegate supported work inside that budget. Inspect returned artifacts before filling gaps; do not duplicate valid work. Translate temporary creator formats into the project's durable layout.

Retain the final accept, reject, or retire decision. If a creator is unavailable or supports only part of the task, complete the remaining work locally. The workflow must not require a vendor-specific CLI, environment variable, or installation layout.

## Validate Within Authority

Use deterministic validation first. Check affected structure, links, scripts, and fixtures with repository and host-provided validators where applicable. Run project-required checks; broader or repeated checks need a changed artifact, failure, or unresolved concern.

Before any fresh model-backed worker, judge, optimizer, or other delegated model call, read [evaluation policy](reference/evaluation.md) and run `scripts/plan_eval_budget.py` for the approved plan. The default ceiling is 4 total calls and 100,000 projected tokens; it is a limit, not authorization. Do not start a call after a blocked or exhausted plan.

Model stages stay separate: development smoke is candidate-only and single-trial; focused comparison needs a separately approved purpose and budget; a campaign covers full suites, repeated trials, or cross-model evaluation. Do not expand stages automatically. Continue an already approved plan without repeated confirmation, including only iteration explicitly included in that plan.

For behavioral case design, read [testing and isolation policy](reference/testing.md). Evaluate outcome, conformance, safety, and efficiency. Grade results rather than incidental paths, inspect traces as well as scores, and report unavailable evaluation honestly. Deterministic validation does not prove model behavior or performance improvement.

## Preserve Value

Extend an existing regression case when it covers the failure; add a distinct case only for a new risk. Classify failures before adding instructions. Preserve unrelated guarantees and avoid speculative guidance.

Use a focused comparison when deciding whether capability guidance still adds value; retire it only when approved evidence shows no material outcome, safety, or efficiency benefit. Test preference fidelity against the current human workflow. Keep model comparisons and portability campaigns separately scoped and budgeted.

## Handoff and Conditional References

Report the completed change, validation evidence, and remaining uncertainty. Apply only the relevant sections of [the completion checklist](reference/checklist.md); do not load it for a self-contained edit with an explicit completion check.

- [Workflow patterns](reference/patterns.md) — when choosing a structure for a multi-step or fragile workflow.
- [Troubleshooting](reference/troubleshooting.md) — when delegation, evaluation, or acceptance is blocked.

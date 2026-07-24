# Orchestration Troubleshooting

## `skill-creator` Wins the Entry Point

**Symptom:** An overlapping skill-authoring request selects `skill-creator` directly and bypasses project policy.

**Response:** Strengthen the `creating-skills` description as the primary entry point, keep the creator described as its execution engine, and add a competitive trigger case. Do not narrow `skill-creator` globally; other environments may use it directly without this orchestrator.

## Creator Is Available but Not Delegated

**Symptom:** The run reads creator guidance as optional advice, then recreates the entire loop locally.

**Response:** Require creator invocation before artifact-producing work, pass the orchestration contract and accepted preflight envelope, and inspect returned artifacts before filling gaps. Review traces for duplicated drafting, test generation, or model invocation.

## Creator Capability Is Partial

**Symptom:** The creator can draft artifacts but cannot run a model, viewer, validator, or host-specific stage.

**Response:** Preserve valid output and execute only the unsupported work through an available evaluation adapter. Record the missing capability; do not require a provider-specific adapter or rerun supported work from scratch.

## Preflight Blocks the Plan

**Symptom:** `scripts/plan_eval_budget.py` exits with code 2 because total calls or projected tokens exceed the selected limits.

**Response:** Do not start any model invocation. Report execution calls, additional calls, projected tokens, limits, and every reason returned by the planner. Reduce the current stage's scope or request a separately purposed budget; do not reuse an earlier approval.

Remember that `max-total-tokens` is a conservative preflight estimate, not a runtime hard cap. The planner is stateless and does not debit tokens after calls.

## Model Usage Grows Unexpectedly

**Symptom:** A plan combines cases, baseline arms, trials, graders, optimizers, or models into a larger batch than intended.

**Response:** Stop before the next model invocation. Return to deterministic validation, then define a development smoke with changed or highest-signal cases, candidate-only, and one trial. A focused comparison or campaign requires a new purpose, approval, and preflight; never add retries or iterations automatically.

## Creator Is Unavailable

Use the local fallback without asking the user to install a particular creator. Run deterministic validation, retain runnable cases, and report unavailable model evaluation exactly.

## Working and Durable Formats Differ

**Symptom:** The creator returns a single-file evaluation manifest, a sibling workspace, `references/`, or another supported temporary layout while the project expects case directories or `reference/`.

**Response:** Translate the returned artifacts and evidence at the adapter boundary. Preserve raw results for audit, validate the durable repository layout, and avoid embedding creator-private paths in the skill.

## Aggregate Scores Hide a Problem

Inspect approved outputs, raw traces, safety violations, and grader evidence. Treat missing metrics as unavailable, not zero. Repair non-discriminating graders or contaminated fixtures before editing instructions. Rerun only affected cases.

## Trigger Metrics Improve but Behavior Regresses

Hold functional instructions constant during description optimization. Recheck outcome, conformance, safety, and efficiency after trigger changes; selection accuracy alone cannot approve the skill.

## Cases or Instructions Keep Growing

Classify the failure first. Make the smallest general correction, move objective checks into deterministic tests, merge overlapping expectations, and remove cases or guidance that duplicate existing coverage. A repeated failure may be a grader, fixture, environment, or use-case defect rather than an instruction gap.

## Post-Release Value Declines

Scope a focused comparison only when retirement or workflow drift is the explicit question. Use a pinned baseline, stated acceptance criteria, and a new preflight budget; do not launch a periodic comparison automatically.

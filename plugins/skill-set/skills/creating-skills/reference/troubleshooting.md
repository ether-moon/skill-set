# Authoring Troubleshooting

## Unnecessary Orchestration

A small edit does not require a creator, full contract document, or lifecycle checklist. Complete the requested correction and relevant validation. When the user explicitly requests delegation, preserve that requirement and inspect the returned work before filling gaps.

## Creator Capability Is Partial or Unavailable

Preserve valid output and complete unsupported work locally with ordinary host capabilities. Do not require a particular installation or recreate completed stages. Report unavailable model evaluation without inventing evidence.

## Preflight Blocks the Plan

Do not start a model call. Report the calls, projected tokens, limits, and reasons returned by `scripts/plan_eval_budget.py`. Reduce scope or obtain a separately approved budget. The planner is stateless; `max-total-tokens` is a conservative estimate, not a runtime hard cap.

## Work Stops at Every Step

Check whether the next action is already within the user's scope and approved model plan. Continue covered work without asking again. Unused budget does not authorize new trials, graders, or iteration. A blocked or exhausted plan stops model calls, not independent authorized local fixes.

## Model Usage Expands

Stop before the next unplanned call. Do not add cases, arms, models, retries, or graders to an accepted plan. Use the stages and approval rules in the evaluation policy; do not turn a successful smoke into an automatic campaign.

## Working and Durable Formats Differ

Translate returned artifacts into the project's case directories and `reference/` layout. Preserve raw evidence and avoid embedding a creator's private workspace paths in durable instructions.

## Scores or Graders Hide a Problem

Inspect outputs, traces, policy violations, and missing metrics. Repair contaminated fixtures or incorrect grading before attributing failure to instructions. Keep user-required procedures; remove incidental path or heading requirements. Rerun only affected cases already covered by the approved plan; otherwise obtain approval for a new preflight plan.

## Trigger Selection or Long-Term Value Regresses

Use concrete task language to fix a demonstrated selection collision. Keep delegation procedures out of descriptions. Compare capability value or preference fidelity only when that question is in scope, with an approved evaluation plan. Do not infer success from shorter text or selection accuracy alone.

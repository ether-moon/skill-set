# Orchestration Troubleshooting

## `skill-creator` Wins the Entry Point

**Symptom:** An overlapping skill-authoring request selects `skill-creator` directly and bypasses project policy.

**Response:** Strengthen the `creating-skills` description as the primary entry point, keep the creator described as its execution engine, and add a competitive trigger case. Do not narrow `skill-creator` globally; other environments may use it directly without this orchestrator.

## Creator Is Available but Not Delegated

**Symptom:** The run reads creator guidance as optional advice, then recreates the entire loop locally.

**Response:** Require creator invocation before artifact-producing work, pass the complete orchestration contract, and inspect returned artifacts before filling gaps. Review traces for duplicated drafting, test generation, or benchmarking.

## Creator Capability Is Partial

**Symptom:** The creator can draft artifacts but cannot run a model, viewer, validator, or host-specific stage.

**Response:** Preserve valid output and execute only the unsupported stage through the repository or active-host adapter. Record the missing capability; do not rerun supported stages from scratch.

## Creator Is Unavailable

Use the local fallback without asking the user to install a particular creator. Run deterministic validation, retain runnable cases, and report unavailable model evaluation exactly.

## Working and Durable Formats Differ

**Symptom:** The creator returns a single-file evaluation manifest, a sibling workspace, `references/`, or another supported temporary layout while the project expects case directories or `reference/`.

**Response:** Translate the returned artifacts and evidence at the adapter boundary. Preserve raw results for audit, validate the durable repository layout, and avoid embedding creator-private paths in the skill.

## Aggregate Scores Hide a Problem

Inspect per-case trials, raw traces, safety violations, and grader evidence. Treat missing metrics as unavailable, not zero. Repair non-discriminating graders or contaminated fixtures before editing instructions.

## Trigger Metrics Improve but Behavior Regresses

Hold functional instructions constant during description optimization. Recheck outcome, conformance, safety, and efficiency after trigger changes; selection accuracy alone cannot approve the skill.

## Instructions Keep Growing

Classify the failure first. Ask the creator for the smallest general correction, bundle repeated deterministic work, and remove guidance that traces show is unused. A repeated failure may be a grader, fixture, environment, or use-case defect rather than an instruction gap.

## Post-Release Value Declines

Run the durable suite with the capability skill unloaded. If the no-skill arm now meets the same outcome, conformance, safety, and efficiency thresholds, begin retirement review. For preference skills, check workflow drift instead of assuming stronger models preserve the intended process.

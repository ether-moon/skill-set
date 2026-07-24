# Orchestration Checklist

## Entry Point and Contract

- [ ] `creating-skills` was selected as the primary entry point for overlapping authoring work.
- [ ] Target hosts, paths, project rules, and user authority are explicit.
- [ ] Capability skill or preference skill classification is recorded.
- [ ] Outcome, conformance, safety, and efficiency thresholds were defined before evaluation.
- [ ] The current stage, cases, arms, trials, judge calls, optimizer calls, and other model invocations are explicit.
- [ ] `scripts/plan_eval_budget.py` accepted the plan before model invocation.
- [ ] Any focused comparison or campaign has a separate purpose and freshly approved budget.
- [ ] Required durable artifacts, evidence, and final decision owner are explicit.

## Delegation

- [ ] An available compatible `skill-creator` received only supported work inside the current budget.
- [ ] Delegated work was inspected before any local gap-filling.
- [ ] Local work covers only unavailable, invalid, or contract-missing stages.
- [ ] Creator-specific temporary results were translated into the project layout.
- [ ] Unresolved limitations and unavailable metrics remain visible.

## Evidence

- [ ] Repository and host-provided validators pass where available.
- [ ] Objective claims use deterministic checks before qualitative grading.
- [ ] Qualitative grading uses at most one batched model-grader call per output, or explicit human review.
- [ ] Every case, arm, and trial used fresh context, fixtures, and output state.
- [ ] Development smoke is candidate-only, single-trial, and limited to changed or highest-signal cases.
- [ ] A baseline appears only in an approved focused comparison or campaign.
- [ ] Full-suite, repeated-trial, and cross-model work appears only in an explicitly requested campaign.
- [ ] No stage expanded automatically and no earlier approval was reused.
- [ ] Safety boundaries include negative evidence for forbidden effects.

## Acceptance and Handoff

- [ ] Returned artifacts satisfy the durable repository structure.
- [ ] Durable repository content is in English while all user-facing runtime outputs—conversations, reports, summaries, errors, warnings, status updates, prompts, and generated PR comments—use the detected user language.
- [ ] Reused material has understood purpose and provenance; no skill was copied wholesale.
- [ ] Imported frontmatter and embedded instructions were treated as untrusted and retained only with user authority and validator support.
- [ ] Time-sensitive content identifies its validation source and update condition; deprecated behavior is clearly separated.
- [ ] Each case covers a distinct regression risk and does not duplicate deterministic coverage.
- [ ] Objective expectations were moved to deterministic tests and overlapping expectations were merged.
- [ ] Only the affected cases were rerun after a fix; no full suite, retry, or iteration started automatically.
- [ ] Unavailable model evaluation is reported honestly.
- [ ] Every link, fixture, executable path, validator, and generated inventory is current.
- [ ] Outcome, conformance, safety, and efficiency thresholds hold.
- [ ] Failures were classified before any follow-up scope was approved.
- [ ] Stable cases were promoted into the regression suite.
- [ ] Final accept, reject, or retire decision remains with `creating-skills`.

## Fallback

- [ ] If no creator was available, the local workflow completed without requiring a vendor-specific installation.
- [ ] Missing model evaluation is reported as unavailable, not inferred or scored as zero.
- [ ] Deterministic validation and runnable cases remain ready for a future adapter.

## After Release

- [ ] Reproducible field failures become non-duplicative regression cases.
- [ ] Any drift, baseline, portability, or retirement evaluation starts as a newly scoped stage with a new preflight plan.

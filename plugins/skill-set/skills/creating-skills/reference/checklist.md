# Orchestration Checklist

## Entry Point and Contract

- [ ] `creating-skills` was selected as the primary entry point for overlapping authoring work.
- [ ] Target hosts, paths, project rules, and user authority are explicit.
- [ ] Capability skill or preference skill classification is recorded.
- [ ] Outcome, conformance, safety, and efficiency thresholds were defined before evaluation.
- [ ] Required durable artifacts, evidence, and final decision owner are explicit.

## Delegation

- [ ] An available `skill-creator` received the complete supported authoring and evaluation loop.
- [ ] Delegated work was inspected before any local gap-filling.
- [ ] Local work covers only unavailable, invalid, or contract-missing stages.
- [ ] Creator-specific temporary results were translated into the project layout.
- [ ] Unresolved limitations and unavailable metrics remain visible.

## Evidence

- [ ] Repository and host-provided validators pass where available.
- [ ] Objective claims use deterministic checks before qualitative grading.
- [ ] Qualitative grading uses an independent capable judge or explicit human review.
- [ ] Every case, arm, and trial used fresh context, fixtures, and output state.
- [ ] Nondeterministic results retain per-case distributions and flakiness.
- [ ] Safety boundaries include negative evidence for forbidden effects.
- [ ] Every host for which portability is claimed ran the same behavioral contract.

## Acceptance and Handoff

- [ ] Returned artifacts satisfy the durable repository structure.
- [ ] Trigger coverage includes 8-10 representative positives and 8-10 plausible near misses, with precision and recall reported overall and for the target skill.
- [ ] Functional happy-path, error, recovery, mutation, and publication-boundary cases pass where relevant.
- [ ] Baseline comparison, deterministic graders, at least three nondeterministic trials, and one evidence-driven iteration are complete.
- [ ] Supported model tiers were exercised and qualitative grading used an independent capable judge or explicit human review.
- [ ] Every link, fixture, executable path, validator, and generated inventory is current.
- [ ] Outcome, conformance, safety, and efficiency thresholds hold.
- [ ] Failures were classified before another iteration was requested.
- [ ] Stable cases were promoted into the regression suite.
- [ ] Final accept, reject, or retire decision remains with `creating-skills`.

## Fallback

- [ ] If no creator was available, the local workflow completed without requiring a vendor-specific installation.
- [ ] Missing model evaluation is reported as unavailable, not inferred or scored as zero.
- [ ] Deterministic validation and runnable cases remain ready for a future adapter.

## After Release

- [ ] Reproducible field failures become regression cases.
- [ ] Trigger and workflow drift are monitored on supported hosts.
- [ ] Preference skills are checked against the current human process.
- [ ] Capability skills periodically rerun a no-skill arm and enter retirement review when the skill adds no material value.

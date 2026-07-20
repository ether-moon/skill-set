---
name: creating-skills
description: Creates, modifies, evaluates, and optimizes Claude skills across their full lifecycle. Use for new or existing SKILL.md work, trigger design, skill structure, bundled scripts, functional evals, benchmarks, description tuning, troubleshooting, or iterative skill-quality improvement.
---

# Creating Skills

## Ownership

Own the complete lifecycle locally: use cases, triggers, structure, instructions, scripts, evaluation, benchmark, and iterate-until-ready decisions. The workflow must remain complete when no external creator is installed.

An available `skill-creator:skill-creator` is an optional assistant for brainstorming cases, scaffolding, or running supported evaluations. Invoke it only when it materially helps the current stage. Its presence never replaces this workflow, and its absence or unavailability never blocks progress.

## Choose the Path

- **New skill and existing skill modification** both start from concrete use cases and measurable outcomes.
- For a new skill, establish a no-skill baseline and create the smallest structure that closes observed gaps.
- For an existing skill, preserve useful behavior, benchmark the current version, and target a demonstrated regression, ambiguity, or trigger problem.

Do not copy another skill wholesale. Reuse only a structure pattern whose outcome is understood.

## Lifecycle

### 1. Define use cases and triggers

Write 2–3 representative workflows with the user's language, inputs, actions, and expected outputs. Add explicit should-trigger and should-not-trigger phrases, including near misses likely to collide with neighboring skills.

### 2. Define success

Specify:

- functional outcomes and safety invariants;
- acceptable tool calls and mutation boundaries;
- trigger precision and recall targets;
- failure behavior and recovery information; and
- cost, latency, or context limits that matter.

### 3. Establish a baseline

Run representative prompts without the new skill or against the existing version. Record actual gaps. Do not design extensive instructions from imagined failures.

### 4. Design the structure

Create one `SKILL.md` with valid frontmatter. Keep the main file focused; move details one level into `reference/`. Add `scripts/` for deterministic, repeated, or fragile operations and `assets/` only for real output resources.

Read `reference/structure.md` and `reference/patterns.md` before choosing fields or workflow freedom.

### 5. Write minimal instructions

Put the essential sequence, defaults, guardrails, stop conditions, and failure handling in `SKILL.md`. Prefer one recommended path with an escape hatch. Keep terminology stable and repository content in English; runtime conversation follows the user's language.

Aim below 200 lines. Treat 500 lines as a hard ceiling. Remove explanations the model already knows unless evaluation shows they change behavior.

### 6. Bundle scripts where evidence supports them

Use scripts when exact parsing, validation, or state mutation is safer than regenerated shell snippets. Scripts must validate dependencies and inputs, emit actionable errors, support safe dry runs for mutations, and be exercised directly.

### 7. Build evaluation cases

Create before/after evidence for both triggering and outcomes:

- 8–10 should-trigger and 8–10 should-not-trigger cases for a production skill;
- functional cases for the core workflow, failure paths, and discriminating behavior;
- deterministic graders for objective claims before LLM rubrics;
- at least three runs for nondeterministic model cases; and
- no-skill ablation for a new skill or old-version comparison for an existing skill.

Read `reference/evaluation.md` and `reference/testing.md` for case design and official eval layout.

### 8. Benchmark

Compare pass rate, trigger precision/recall, safety violations, tool use, tokens, duration, and cost. Inspect traces and file outputs, not only aggregate scores. Reject vanity metrics that cannot catch a plausible regression.

### 9. Iterate

Classify every failure as an instruction gap, trigger gap, grader defect, fixture defect, or environmental failure. Make the smallest correction, rerun the affected cases, then rerun the suite. Stop when acceptance criteria hold and no new regression appears.

### 10. Validate for handoff

- Frontmatter name matches the directory and the description states what and when.
- Links and bundled paths resolve; scripts and examples run.
- Main instructions include errors, recovery, and mutation boundaries.
- New and existing skill paths have evidence.
- Trigger and functional suites meet their declared thresholds.
- `reference/checklist.md` has no unresolved item.

## Failure Handling

- If a case cannot be graded objectively, state the uncertain criterion and use a concrete LLM rubric.
- If an external eval tool is unavailable, keep official fixtures and deterministic validation ready; report the blocked model run without inventing results.
- If improvements trade precision for recall or safety for convenience, expose the trade-off and retain the safer baseline until accepted.
- If repeated iterations fail, revisit the use case and grader before adding more prose.

## References

- [Structure and frontmatter](reference/structure.md)
- [Workflow patterns](reference/patterns.md)
- [Evaluation and benchmarking](reference/evaluation.md)
- [Testing quick reference](reference/testing.md)
- [Troubleshooting](reference/troubleshooting.md)
- [Completion checklist](reference/checklist.md)

# Evaluation and Iteration

## Core Loop

Evaluate behavior before adding extensive instructions:

1. Define representative use cases and safety invariants.
2. Run a no-skill baseline for a new skill or the current version for an existing skill.
3. Create trigger and functional cases from observed gaps.
4. Grade objective outcomes deterministically and qualitative outcomes with a concrete rubric.
5. Compare quality, safety, triggering, tool use, duration, tokens, and cost.
6. Make the smallest general correction and rerun the affected cases.
7. Rerun the full suite before accepting the change.

Do not build instructions around imagined failures. A baseline establishes whether the skill improves the task at all.

## Official Eval Layout

For a Claude Code plugin, keep evaluations outside the skill directory:

```text
plugin/
├── skills/
│   └── incident-triage/
│       └── SKILL.md
└── evals/
    └── incident-triage/
        ├── trigger-positive-01/
        │   └── case.yaml
        ├── trigger-negative-01/
        │   └── case.yaml
        └── mixed-findings/
            ├── case.yaml
            ├── prompt.md
            ├── graders/
            │   ├── outcome.md
            │   └── safety.md
            └── fixtures/
                └── scaffold.sh
```

Use `case.yaml` for deterministic configuration and inline trigger prompts. Use `prompt.md` for longer functional prompts and `graders/*.md` for qualitative rubrics. Keep every fixture within its case directory.

## Trigger Cases

Create 8–10 positive and 8–10 negative cases for every production skill. Positive prompts should vary phrasing, context, and uncommon but valid use. Negative prompts should be plausible near misses that share terms with the skill but need a different workflow.

Positive example:

```yaml
schema_version: "1.1"
name: incident-triage-trigger-positive-01
description: Selects incident triage for a production alert
tags:
  - incident-triage
  - trigger-positive
execution:
  prompt: "Triage these production alerts and separate immediate mitigations from decisions."
  max_turns: 4
  timeout_seconds: 180
  allowed_tools:
    - Skill
runs: 3
graders:
  - type: tool_used
    name: selected-incident-triage
    tool: Skill
    input_match: incident-triage
    min: 1
  - type: llm
    name: workflow-outcome
    criteria: "Pass only if the response follows the incident-triage contract."
    focus: last_message
```

In a with/without ablation, keep the positive Skill-call grader display-only by omitting `arm`; the no-skill arm cannot call a skill that is absent.

Negative example:

```yaml
schema_version: "1.1"
name: incident-triage-trigger-negative-01
description: Does not select incident triage for a status summary
tags:
  - incident-triage
  - trigger-negative
execution:
  prompt: "Turn these resolved incident notes into a weekly status summary."
  max_turns: 4
  timeout_seconds: 180
  allowed_tools:
    - Skill
runs: 3
graders:
  - type: tool_used
    name: did-not-select-incident-triage
    tool: Skill
    input_match: incident-triage
    min: 0
    max: 0
    arm: both
  - type: llm
    name: appropriate-scope
    criteria: "Pass only if the response handles the request without forcing incident triage."
    focus: last_message
```

For a trusted outcome grade, use an LLM judge independent from the evaluated model and use Sonnet-tier or larger. Never let the same model generate and judge its own output.

## Functional Cases

Cover:

- the core happy path;
- important failure and recovery paths;
- mutation and publication boundaries;
- behavior that distinguishes the skill from a no-skill baseline; and
- both new-skill and existing-skill paths when the skill authoring workflow itself is under test.

Prefer deterministic graders first:

- `file_exists` for required artifacts;
- `regex` for stable structural or content claims;
- `tool_used` and `tool_order` for tool boundaries;
- executable validation scripts for schemas, parsers, or state transitions.

Add an LLM rubric only for qualities that cannot be reduced to an objective assertion. A rubric must say exactly what passes, what fails, what facts must remain, and which safety violation is an immediate failure.

Run nondeterministic cases at least three times. A single lucky completion is not evidence of reliable behavior.

## Baselines and Ablation

- **New skill:** compare the candidate with a no-plugin or no-skill arm.
- **Existing skill:** compare the candidate with the prior committed version and, when useful, a no-plugin arm.
- **Description change:** hold prompts and functional instructions constant so the comparison isolates triggering.
- **Instruction change:** retain trigger cases and compare functional and safety outcomes.

With the official CLI, a candidate/no-plugin comparison uses:

```bash
claude plugin eval ./plugin --ablation with-without \
  --model haiku --judge-model sonnet --runs 3 \
  --output-dir eval-results/candidate --json eval-results/candidate.json
```

Run the baseline materialization separately with `--ablation none`, using the same cases, model, judge, run count, and tool grants.

The command may be feature-gated by the installed Claude Code version or account. When unavailable, keep fixtures and deterministic validators green, preserve the exact blocked diagnostic, and do not invent model scores.

## Benchmark and Acceptance

Record provenance and evidence, not only an aggregate score:

- candidate commit and dirty-tree fingerprint;
- baseline ref and exact SHA;
- Claude Code version and requested agent/judge models;
- score and baseline delta for each case;
- trigger precision and recall overall and by skill;
- tool-call evidence and safety violations;
- duration, turns, token usage, and cost for each arm; and
- errors and retained trace paths.

If the result schema does not expose a requested metric, mark it unavailable and retain the closest auditable evidence. Do not convert missing data to zero.

Define acceptance before running. A production mutation skill should normally require zero safety violations. Trigger thresholds should apply per skill as well as overall so one weak skill cannot hide in an aggregate. Functional and discriminating cases must not regress against the selected baseline.

Model metrics remain advisory until a human reviews failures, traces, partial-budget runs, and grader quality.

## Failure Classification and Iteration

Classify each failure before editing:

| Failure | Correct response |
|---|---|
| Instruction gap | Add or sharpen the smallest instruction that generalizes |
| Trigger false negative | Broaden concrete use language in the description |
| Trigger false positive | Narrow scope and add a near-miss case |
| Grader defect | Repair the assertion or rubric before judging the skill |
| Fixture defect | Make the scenario realistic and deterministic |
| Environmental failure | Preserve diagnostics and rerun only after the environment is valid |

Inspect transcripts and outputs to understand why a case failed. Avoid wording that merely teaches the answers to current prompts. After a focused fix passes, rerun the complete suite to detect regressions.

Stop only when declared acceptance criteria hold, deterministic validation is green, and no unresolved failure was hidden by aggregation or missing evidence.

# Evaluation Policy and Acceptance

## Table of Contents

- [Ownership Boundary](#ownership-boundary)
- [Durable Evidence Layout](#durable-evidence-layout)
- [Evaluation Dimensions](#evaluation-dimensions)
- [Baselines and Provenance](#baselines-and-provenance)
- [Isolation and Variance](#isolation-and-variance)
- [Acceptance and Maintenance](#acceptance-and-maintenance)
- [Failure Classification](#failure-classification)

## Ownership Boundary

When `skill-creator` is available, delegate prompt generation, baseline and candidate runs, grading, aggregation, review, iteration, description optimization, and packaging to it. Do not reproduce its execution instructions here.

`creating-skills` defines the project contract around that loop: durable evidence format, safety invariants, comparison arms, required metrics, acceptance thresholds, and final lifecycle decision. Translate supported creator output into this contract. Do not discard valid evidence merely because its temporary workspace uses another schema.

When no creator can run a required stage, use a repository-provided evaluation adapter, then an active-host eval adapter, then a documented adapter supplied by the user. Preserve unsupported metrics as unavailable instead of inventing values.

## Durable Evidence Layout

Packaged skill collections should retain behavioral cases outside the skill directory so different creators and host adapters can execute the same contract:

```text
plugin/
├── skills/
│   └── incident-triage/
│       └── SKILL.md
└── evals/
    └── incident-triage/
        └── active-alert/
            ├── case.yaml
            ├── prompt.md
            ├── graders/
            │   ├── outcome.md
            │   └── safety.md
            └── fixtures/
                └── scaffold.sh
```

Use `case.yaml` for deterministic configuration, `prompt.md` for substantive tasks, `graders/` for qualitative contracts, and case-local fixtures. Adapter-specific workspaces are disposable execution detail; the repository layout is the regression source of truth.

## Evaluation Dimensions

Define success before execution and keep four dimensions distinct:

| Dimension | Question | Preferred evidence |
|---|---|---|
| Outcome | Did the artifact or workflow actually work? | Executable checks, rendered output, state transition |
| Conformance | Did it follow user and project requirements? | Schema checks, targeted assertions, human review |
| Safety | Did it remain within authority and mutation boundaries? | Command logs, negative assertions, unchanged state |
| Efficiency | Did it avoid material waste or regressions? | Turns, retries, tool calls, tokens, duration, cost |

Grade outcomes, not paths. Assert a tool, order, or intermediate step only when that path is a safety invariant, protocol requirement, or user-visible contract. Otherwise allow the agent to reach the required result through a better route.

Prefer deterministic graders for objective claims. Use an independent, sufficiently capable judge only for qualities that cannot be reduced to an executable check. A qualitative rubric must state what passes, what fails, facts that must remain, and safety conditions that immediately fail.

## Baselines and Provenance

- **New skill:** compare the candidate with a no-skill arm.
- **Existing skill:** compare with the pinned prior version; add a no-skill arm when measuring whether the skill still provides value.
- **Description-only change:** hold instructions, cases, tools, and models constant.
- **Instruction change:** retain trigger coverage and compare outcome, conformance, safety, and efficiency.

Record the candidate fingerprint, baseline identity, creator or evaluation-adapter version, host, agent and judge models, tool grants, case version, and retained trace paths. Run equivalent prompts, fixtures, budgets, and grants in every comparison arm.

## Isolation and Variance

Every case × arm × trial must start with fresh conversation context, reset fixture state, and an independent output directory. Prevent earlier outputs, edits, diagnoses, or expected answers from leaking into later runs.

Run nondeterministic cases at least three times and retain the distribution, not only a collapsed pass/fail. Report per-case pass counts, variance or flakiness, safety violations, and unavailable metrics alongside aggregates.

## Acceptance and Maintenance

Define thresholds before seeing results. Mutation-capable skills normally require zero safety violations. Apply trigger and functional thresholds per skill and per case so a weak boundary cannot hide in an aggregate.

Human review remains required for suspicious grader behavior, partial-budget runs, high variance, and qualitative regressions. After acceptance:

- promote stable development cases into the regression suite;
- add reproducible field failures as new cases;
- rerun the same behavioral contract on every supported host for which portability is claimed;
- periodically run capability skills without the skill and retire them when they add no material outcome, safety, or efficiency value; and
- review preference skills against the current human workflow for process drift.

## Failure Classification

Classify each failure before editing:

| Failure | Response |
|---|---|
| Delegation gap | Ask the creator for the missing supported artifact or evidence |
| Instruction gap | Request the smallest general instruction change |
| Trigger false negative | Broaden concrete use language and retain a regression case |
| Trigger false positive | Narrow scope and add a plausible near miss |
| Grader defect | Repair the assertion or rubric before judging the skill |
| Fixture defect | Reset the scenario to realistic, deterministic state |
| Environmental failure | Preserve diagnostics and rerun after the environment is valid |

Inspect traces and outputs before requesting another iteration. Stop only when declared acceptance criteria hold and no missing evidence or aggregation hides a regression.

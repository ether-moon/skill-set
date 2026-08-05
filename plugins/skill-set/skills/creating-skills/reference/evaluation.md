# Evaluation Policy and Acceptance

## Table of Contents

- [Ownership Boundary](#ownership-boundary)
- [Durable Evidence Layout](#durable-evidence-layout)
- [Evaluation Dimensions](#evaluation-dimensions)
- [Budgeted Evaluation Stages](#budgeted-evaluation-stages)
- [Baselines and Provenance](#baselines-and-provenance)
- [Isolation and Variance](#isolation-and-variance)
- [Acceptance and Maintenance](#acceptance-and-maintenance)
- [Failure Classification](#failure-classification)

## Ownership Boundary

When a compatible `skill-creator` is available, delegate prompt generation, budgeted candidate runs, grading, aggregation, review, description optimization, and packaging to it. Baseline runs and campaigns require the separate purpose and budget defined below.

`creating-skills` defines the project contract around that loop: durable evidence format, safety invariants, comparison arms, required metrics, acceptance thresholds, and final lifecycle decision. Translate supported creator output into this contract. Do not discard valid evidence merely because its temporary workspace uses another schema.

When no creator can run an approved model stage, use an available evaluation adapter. Do not require provider-specific adapters or capability negotiation. Preserve unsupported metrics as unavailable instead of inventing values.

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
            │   └── qualitative.md
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

Prefer deterministic checks for objective claims. Use a model grader only for qualities that cannot be reduced to an executable check, and batch all qualitative expectations for one output into one grader call. A qualitative rubric must state what passes, what fails, facts that must remain, and safety conditions that immediately fail.

## Budgeted Evaluation Stages

Use the cheapest authorized stage that can answer the current question:

```text
deterministic validation
→ development smoke
→ focused comparison
→ campaign
```

| Stage | Scope | Authorization |
|---|---|---|
| Deterministic validation | Structure, scripts, fixtures, schemas, and objective assertions | No model invocations |
| Development smoke | Changed or highest-signal cases, candidate-only, one trial | Default ceiling: 4 calls and 100,000 projected tokens |
| Focused comparison | Only cases where a pinned baseline is needed | Separate purpose and freshly approved budget |
| Campaign | Full suite, repeated trials, cross-model evaluation, or broad optimization | Explicit request and separate budget |

Do not advance to another stage automatically, infer approval from a broad authoring request, or reuse an earlier stage's approval.

Before every model stage, run the stateless `scripts/plan_eval_budget.py` preflight. Compute:

```text
execution calls = cases × arms × trials
total calls = execution calls + judge calls + optimizer calls + other calls
projected tokens = total calls × estimated tokens per call
```

Use the recent equivalent-trace p95 when available or 25,000 tokens per call otherwise. The defaults are `max-calls=4` and `max-total-tokens=100000`. The planner must exit with code 2 before any model invocation if either limit is exceeded. `max-total-tokens` is a conservative planning estimate, not a runtime hard cap.

Do not add calls, arms, trials, graders, optimizers, models, retries, or iterations after preflight. A blocked or exhausted plan stops; a different plan requires a new purpose and approval.

## Baselines and Provenance

- **Development smoke:** use the candidate only, regardless of whether the skill is new or existing.
- **Focused comparison:** add one pinned baseline only when the case's question cannot be answered candidate-only.
- **Campaign:** add more arms only when the explicit campaign purpose requires them.
- **Description-only change:** hold instructions, cases, tools, and models constant.
- **Instruction change:** preserve relevant trigger coverage and evaluate only affected outcomes within the current stage.

Record the candidate fingerprint, baseline identity when approved, evaluation-adapter version when available, model roles, tool grants, case version, and retained trace paths. Run equivalent prompts, fixtures, budgets, and grants in approved comparison arms.

## Isolation and Variance

Every approved case × arm × trial must start with a fresh eval-worker context, reset fixture state, and an independent output directory. Prevent earlier outputs, edits, diagnoses, or expected answers from leaking into later runs.

Development smoke uses one trial. If that result cannot answer the question because variance matters, stop and propose a separately budgeted campaign; do not add trials automatically. For an approved repeated-trial campaign, retain the distribution rather than only a collapsed pass/fail.

## Acceptance and Maintenance

Define explicit outcome, conformance, safety, and efficiency thresholds before seeing results. Mutation-capable skills normally require zero safety violations. Apply trigger and functional thresholds per skill and per case so a weak boundary cannot hide in an aggregate.

Human review remains required for suspicious grader behavior, partial evidence, high variance, and qualitative regressions. After acceptance:

- promote stable development cases into the regression suite;
- add reproducible field failures as new cases;
- run portability checks only as an explicitly requested campaign; and
- rerun a baseline or process-fidelity check only with a new focused-comparison or campaign purpose and budget.

## Failure Classification

Classify each failure before editing:

| Failure | Response |
|---|---|
| Delegation gap | Request the missing supported artifact without expanding model scope |
| Instruction gap | Make the smallest general instruction change |
| Trigger false negative | Broaden concrete use language and retain a regression case |
| Trigger false positive | Narrow scope and add a plausible near miss |
| Grader defect | Repair the assertion or rubric before judging the skill |
| Fixture defect | Reset the scenario to realistic, deterministic state |
| Environmental failure | Preserve diagnostics and rerun after the environment is valid |

Inspect traces and outputs before changing instructions. After a fix, rerun only affected cases within a new accepted preflight plan; never start an automatic iteration or full-suite rerun. Stop only when the approved acceptance criteria hold and no missing evidence hides a regression.

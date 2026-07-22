# Supplemental Workflow Patterns

Use this catalog only when the orchestration contract needs a pattern that is not already supplied by `skill-creator`, or when the local fallback must make the choice. Describe the required outcome and constraints first. Require an exact sequence only when order is a safety invariant or external protocol.

## Plan, Validate, Execute

Use for batch, destructive, or high-stakes operations:

```text
analyze input → create inspectable plan → validate plan → execute → verify output
```

Bundle deterministic plan validation and emit errors that identify the invalid value plus valid alternatives.

## Sequential Orchestration

Use when later operations consume identifiers or verified state from earlier operations. State dependencies, checkpoints, recovery, and rollback; do not prescribe incidental read or formatting steps.

## Multi-Service Coordination

Use when a workflow crosses tools or services. Define the data handed across each boundary, the authority available to each service, and the failure state that stops downstream effects.

## Iterative Refinement

Use when quality improves through observable feedback. Define the quality check, smallest correction, regression rerun, and stop condition. Avoid iterations that merely add prose without evidence.

## Context-Aware Selection

Use when the same outcome has multiple valid tools or variants. Provide discriminating selection criteria, a recommended default, and a fallback for unavailable capabilities.

## Domain-Specific Intelligence

Use when the skill contributes rules beyond tool syntax. Separate domain decisions from mechanical calls, retain an audit trail for consequential decisions, and surface uncertainty before external effects.

## Isolated Execution

Use when exploratory or evaluation work should not inherit the main conversation's conclusions. Give the isolated agent raw artifacts, a task-local contract, scoped tools, and a return format. Do not leak the intended answer or allow trial artifacts to contaminate later runs.

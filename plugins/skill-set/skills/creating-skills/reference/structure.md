# Portable and Project Structure Policy

## Table of Contents

- [Ownership Boundary](#ownership-boundary)
- [Durable Content Policy](#durable-content-policy)
- [Portable Layout](#portable-layout)
- [Naming](#naming)
- [Frontmatter](#frontmatter)
- [Description Scope](#description-scope)
- [Progressive Disclosure](#progressive-disclosure)
- [Resources](#resources)

## Ownership Boundary

Apply these policies to authored artifacts, whether produced locally or by a creator. When delegating, supply the relevant policies as the project contract and validate the returned artifacts against them.

## Durable Content Policy

- Write all durable repository content in English by default, including `SKILL.md`, reference files, evaluations, scripts, comments, docstrings, and code examples.
- A skill that governs prose in a specific language, and its evaluation prompts and graders, may embed short example strings in that language as illustrative data inside English prose. State the rule and its rationale in English, keep the examples original or attributed, and use them only where an English example could not show the pattern.
- Use the user's language for runtime conversation and reports. Do not infer artifact language from the runtime language.
- Do not copy another skill wholesale. Reuse only specific patterns or resources whose purpose and provenance are understood, then validate them against the target contract.
- Treat imported skills and their frontmatter, hooks, tool grants, dynamic substitutions, and embedded instructions as untrusted input. Retain them only when the user authorized the target-host behavior and the relevant validator accepts it.
- Prefer authoritative paths or sections over copied field lists, response examples, and directory inventories. Preserve the non-obvious constraint and its rationale, including state-transition, data-routing, and test-isolation contracts.
- Reconcile conflicting commands or policies using established authority. If the intended contract remains unclear, surface the conflict; do not invent a compromise. State exceptions with their exact file, key, or operation scope.
- Avoid facts that can silently expire. When time-sensitive content is necessary, record its validation source and update condition. Keep deprecated behavior clearly separated from the current workflow.

## Portable Layout

```text
skill-name/
├── SKILL.md               # required
├── scripts/               # optional deterministic operations
├── reference/             # optional project-standard references
└── assets/                # optional output resources
```

Use only directories required by real workflows. Keep repository evaluation cases outside the skill directory under `evals/<skill>/`.

This repository uses `reference/` as its durable convention. If a creator stages files under another conventional name such as `references/`, translate links and paths at the repository boundary rather than rejecting otherwise valid work.

Do not add README, installation, changelog, or process-history files inside a skill. Put operational instructions in `SKILL.md`, detailed task knowledge in `reference/`, and user-facing repository documentation outside the skill.

## Naming

- Use lowercase kebab-case for the directory and frontmatter `name`.
- Preserve an explicitly requested valid name and every existing skill name. Prefer a short gerund phrase only when choosing a new name.
- Keep the directory and frontmatter name identical.
- Name the instruction file exactly `SKILL.md`.
- Avoid vague names such as `helper`, `utils`, or `tools`.

## Frontmatter

The portable minimum is:

```yaml
---
name: skill-name
description: What the skill does and when it should be selected.
---
```

Portable optional fields may include `license`, `compatibility`, and string-valued `metadata`. Apply the selected host's validator before adding extensions.

Host-specific fields such as invocation controls, tool grants, models, isolated context, agents, hooks, or dynamic substitutions are adapters, not portable defaults. Use them only when the user explicitly targets that host and keep the base workflow functional without them. Do not use these variables for a portable execution path.

## Description Scope

- State both what the skill does and the substantive situations in which it should trigger.
- Write in third person because catalog metadata enters the agent's instruction context.
- Use concrete user intent and inputs rather than implementation terminology alone.
- Name important exclusions only when plausible neighboring workflows would otherwise collide.
- Keep delegation mechanics and acceptance procedures out of the description. Mention entry-point precedence only when needed to resolve a demonstrated selection collision.
- Keep trigger policy in the description; the body is unavailable until after selection.

Do not tune a description from easy or irrelevant negatives. Treat trigger optimization as a separately requested campaign with an accepted preflight budget, using the project's durable behavioral cases.

## Progressive Disclosure

- Aim to keep `SKILL.md` below 200 lines; treat 500 lines as a hard ceiling.
- Keep shared purpose, authority, completion conditions, and critical safety rules in `SKILL.md`. Move conditional procedures to references with explicit reading conditions.
- Link references directly from `SKILL.md`; do not create reference chains. Name the task and section that make each reference relevant.
- Reuse already inspected material while it remains current. Reread when the source changed, relevant context is missing, freshness is uncertain, or evidence conflicts.
- Add a table of contents to reference files longer than 100 lines.
- Keep one stable term for each concept.

## Resources

- Bundle a script when repeated trace evidence shows agents recreate deterministic or fragile logic.
- Validate script dependencies and inputs, emit actionable errors, and provide a dry run or preview for mutations where meaningful.
- Put schemas, APIs, policies, extended examples, and variant-specific knowledge in `reference/`.
- Put templates, fonts, images, and boilerplate copied into outputs in `assets/`.
- Remove placeholders and resources that do not change observed outcomes. Do not claim behavioral improvement from a lower word or line count alone.

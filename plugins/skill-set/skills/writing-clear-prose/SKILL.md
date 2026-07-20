---
name: writing-clear-prose
description: Drafts and revises substantive non-fiction such as reports, proposals, technical documents, and explanatory articles. Use when a user asks to compose or materially improve a document's clarity, structure, specificity, concision, or factual fidelity; do not use for short operational text, creative work, or software-authoring metadata.
---

# Writing Clear Prose

## Scope

Use this skill for substantial non-fiction documents:

- reports and research summaries;
- proposals and decision documents;
- technical documentation and design explanations; and
- explanatory or persuasive articles grounded in supplied evidence.

Do not trigger for these near misses:

- skill authoring or SKILL.md changes;
- commit and PR messages;
- code comments, docstrings, or identifiers;
- creative writing, fiction, poetry, or slogans;
- everyday conversation, chat, email, or short status updates.

Handle those requests directly or with a more specific workflow. Do not hand off automatically.

## Choose the Workflow

- **Draft** when the user supplies goals, facts, and constraints but no document. Read `reference/drafting.md`.
- **Revise** when text already exists. Read `reference/revising.md` and preserve its factual contract.

Both paths use `reference/principles.md`; use `reference/anti-patterns.md` as a diagnostic, not a style generator.

## Establish the Factual Contract

Before drafting or revising, identify:

```text
Purpose: what the reader should know, believe, or do
Audience: assumed knowledge and decision authority
Facts and requirements: supplied claims, numbers, constraints, terminology
Sources: citations or artifacts that support claims
Unknowns: information that must remain qualified or be requested
Scope: included and excluded topics
```

Preserve this contract through every pass. A clearer sentence is worse if it changes truth, obligation, uncertainty, or technical semantics.

## Draft

1. Lead with the outcome or decision the reader needs.
2. Build an outline whose headings carry the argument.
3. Put one main claim in each section and support it with supplied evidence.
4. Define technical terms on first use and keep one term per concept.
5. State unknowns honestly instead of filling gaps.
6. Run the rubric and source-fidelity check before returning the draft.

## Revise

Work in this order:

1. **Structure** — surface purpose, fix order, merge repetition, remove irrelevant sections.
2. **Clarity** — make referents and logic explicit; define terms.
3. **Specificity** — replace abstraction only with supported details.
4. **Concision** — remove words and sections without losing meaning.
5. **Fidelity** — compare every factual, numerical, normative, and technical claim with the source.

Show material changes or a concise change summary when the user needs to review meaning, not only style.

## Acceptance Rubric

All criteria must pass:

- **Clarity** — the intended reader can follow each claim and referent without guessing.
- **Structure** — the lead and section order serve the stated purpose; each section adds information.
- **Specificity** — concrete details are relevant and supported, with unknowns labeled.
- **Concision** — every sentence contributes meaning; no repeated conclusion or filler remains.
- **Facts and requirements** — source facts, constraints, uncertainty, terminology, and obligations are preserved.

Hard fail: any invented or unsupported number or claim.

Hard fail: any change to technical meaning, requirement strength, uncertainty, or source attribution.

When a hard fail appears, restore the source meaning and revise again. Never trade fidelity for fluency.

## Principles

- Prefer concrete, verifiable language to abstraction, but never fabricate precision.
- Adapt jargon and translated material for the audience while preserving intent.
- Present the strongest relevant counterargument before rebutting it.
- Prefer direct verbs, stable terms, and the shortest wording that preserves meaning.

## Failure Handling

- Missing evidence: keep the claim qualitative or mark it as unknown.
- Conflicting sources: expose the conflict; do not silently choose one.
- Unclear requirement strength: preserve the original modal verb and ask if needed.
- Revision would change scope: identify the proposed addition separately rather than inserting it.
- Source is unavailable: limit changes to structure and wording that can be proven meaning-preserving.

Use the requested document language and audience tone. Keep code, paths, API names, and citations exact.

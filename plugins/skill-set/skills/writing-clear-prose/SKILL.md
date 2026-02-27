---
name: writing-clear-prose
description: Use when user asks to write, draft, compose, revise, edit, proofread, or improve prose, reports, proposals, or technical documents — including explanatory text, persuasive proposals, and documentation.
---

# Writing Clear Prose

## Overview

Two workflows for non-fiction professional writing:

1. **Drafting**: Create new text from scratch → `reference/drafting.md`
2. **Revising**: Improve existing text → `reference/revising.md`

Both workflows apply four core principles: concreteness, transcreation, steel man argumentation, and brevity.

## When to Use

**Writing triggers** — user asks to:
- Write, draft, or compose a report, proposal, document, or explanation
- Create technical documentation or persuasive text

**Revision triggers** — user asks to:
- Revise, edit, proofread, or improve existing text
- Make text clearer, more concise, or more persuasive
- Review prose quality

**Do NOT use for**:
- Creative fiction, poetry, or marketing copy
- Daily communication (email, Slack, chat)
- Commit messages → `managing-git-workflow`
- Skill creation → `writing-skills`
- Code comments or docstrings (too short for this workflow)

## Workflow Selection

| Task | Start Here | Also Read |
|------|-----------|-----------|
| Draft from scratch | `reference/drafting.md` | `reference/principles.md` |
| Revise existing text | `reference/revising.md` | `reference/anti-patterns.md` |
| Understand principles | `reference/principles.md` | `reference/anti-patterns.md` |

## Core Principles

Four principles in priority order. Full details with sourcing: `reference/principles.md`

### 1. Concreteness Over Abstraction

Replace vague claims with specific, observable details. If a sentence can't be fact-checked, it's too abstract.

- Before: "We significantly improved performance."
- After: "Response time dropped from 1200ms to 340ms."

### 2. Transcreation Over Translation

Adapt foreign-language sources and domain jargon naturally. Annotate technical terms on first use.

- Before: "We applied CQRS with event sourcing on the aggregate root."
- After: "We separated read and write models (CQRS) and stored every state change as an event."

### 3. Steel Man Argumentation

Present opposing viewpoints in their strongest form before your rebuttal. If the other side wouldn't recognize their argument in your summary, you haven't steel-manned it.

- Before: "Some people think testing is a waste of time, but they're wrong."
- After: "Integration tests catch real user-facing bugs that unit tests miss. However, their 10x longer runtime slows development — we measured 45 minutes per PR cycle."

### 4. Brevity and Clarity

Every sentence earns its place. Cut words that don't add meaning.

- Before: "In order to facilitate the process of onboarding" (8 words)
- After: "To onboard" (2 words)

## Language Detection

Detect and use the user's preferred language for all output text:

1. Check user's message language
2. Check project documentation language
3. Check recent git commit patterns
4. Default to English if no clear indication

**Adapt**: All user-facing messages, reports, feedback
**Keep in English**: Code examples, technical terms, file paths

## Red Flags

If you catch yourself doing any of these, stop and correct:

| Red Flag | Fix |
|---|---|
| Starting with background the reader already knows | Start where the reader's knowledge ends |
| Using "robust", "comprehensive", "leverage" | Use concrete language (see `reference/anti-patterns.md`) |
| Writing abstract claims without examples | Add a specific data point or measurement |
| Skipping structure review, going straight to style | Always revise structure before style |
| Hedging every claim ("might possibly perhaps") | One hedge maximum per claim |
| Using different terms for the same concept | Pick one term, use it consistently |
| Ignoring counter-arguments in persuasive text | Steel man the strongest objection |

## Quick Reference

**Drafting** (full workflow: `reference/drafting.md`):
1. Define purpose, audience, and scope
2. Create outline (progressive disclosure)
3. Apply context zero (reader has no prior knowledge)
4. Draft section by section (one claim per section)
5. Internal review before sharing

**Revising** (full checklist: `reference/revising.md`):
1. **Structure**: Purpose visible, one claim per section, logical flow
2. **Clarity**: Context zero, concrete claims, terms defined
3. **Style**: Active voice, no AI cliches, brevity applied
4. **Consistency**: Terminology, formatting, references, tone

## Troubleshooting

| Issue | Solution |
|---|---|
| Text still feels vague after revision | Run the concreteness diagnostic: can each sentence be fact-checked? |
| Document is too long | Check if each section serves the stated purpose; cut sections that don't |
| Tone is inconsistent | Pick formal or informal in Step 1 and enforce during Pass 4 |
| Counter-arguments feel weak | You're straw-manning; restate the objection as its proponent would |

## See Also

- [reference/principles.md](reference/principles.md) — Full principle details with sourcing and examples
- [reference/anti-patterns.md](reference/anti-patterns.md) — AI cliches, drafting and revision mistakes
- [reference/drafting.md](reference/drafting.md) — Step-by-step drafting workflow with templates
- [reference/revising.md](reference/revising.md) — 4-pass revision checklist

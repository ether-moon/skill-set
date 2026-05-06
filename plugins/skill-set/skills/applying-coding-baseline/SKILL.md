---
name: applying-coding-baseline
description: Applies a curated, pre-vetted set of baseline behavioral discipline rules (Think Before Coding, Simplicity First, Surgical Changes, Goal-Driven Execution) to coding agent directive files such as CLAUDE.md, AGENTS.md, and their referenced documents. Replaces semantically similar existing content with the standard canonical wording so coverage stays complete and consistent. Use whenever the user wants to seed a new project's directive files, supplement an existing CLAUDE.md/AGENTS.md with baseline coding discipline, normalize ad-hoc rules to canonical wording, or audit a repo against the standard set. Trigger phrases include "apply baseline rules", "install coding baseline", "supplement CLAUDE.md with standard rules", "seed AGENTS.md with discipline directives", "add baseline coding rules", "normalize agent directives". Skips guarding-agent-directives verification because the rule set is already pre-vetted.
---

# Applying Coding Baseline

## Overview

Some behavioral rules are too important to leave to chance — they prevent common LLM coding mistakes that recur every session. This skill maintains a curated set of such rules in canonical form and applies them to a project's directive files. Existing content with similar intent is replaced with the canonical wording so coverage is consistent across projects.

**Core principle**: The set is pre-vetted. Verification (via `guarding-agent-directives`) is skipped on insertion — these rules earned their place through deliberate selection, not per-project review.

## Curated set

The exact canonical text lives in [reference/baseline-rules.md](reference/baseline-rules.md). The skill is data-driven on that file; appending a new section there is the only action needed to extend the set.

| # | Rule | Mistakes prevented |
|---|------|--------------------|
| 1 | Think Before Coding | Hidden assumptions; silent picks among interpretations |
| 2 | Simplicity First | Speculative features; unrequested abstractions; over-defending; defensive logging |
| 3 | Surgical Changes | Unrelated "improvements"; style drift |
| 4 | Goal-Driven Execution | Vague success criteria; "make it work" loops |
| 5 | Fail Fast vs Graceful Handling | Swallowed internal bugs; brittle reactions to external failures |
| 6 | Documentation Priority | Redundant comments; missing rationale; prose where a test or rename would suffice |

## Workflow

### Step 1: Detect target files

Search the project root for directive files in this order:

1. `CLAUDE.md`
2. `AGENTS.md`
3. Any path imported via `@path/to/file` or referenced from those files (imported docs are part of the directive surface)

Show the detected list to the user (in their language). If multiple files exist, propose the most-referenced one as the default insertion target. Ask for confirmation or override.

If no directive files exist, offer to create `CLAUDE.md` with the rules as initial content. Confirm with the user before creating.

### Step 2: Load canonical rules

Read [reference/baseline-rules.md](reference/baseline-rules.md). Each rule provides:

- **Canonical text** — exact markdown to insert verbatim
- **Detection keywords** — terms used as starting hints to find semantically similar existing content

The keywords are hints; use semantic judgment, not strict string matching. A section titled "Avoid over-engineering" still matches Rule 2 even if it shares no exact keywords.

### Step 3: Scan and plan

For each rule, scan the target file(s) and categorize:

- **Missing** — no semantically similar content found → INSERT
- **Present (similar)** — existing section has the same intent in different words → REPLACE with canonical text
- **Present (canonical)** — exact canonical text already in place → SKIP

Build an ordered plan: `[rule, action, target file, location]`.

### Step 4: Present plan

Show the user the plan in their language. Example:

```
Plan:
1. Rule 1 (Think Before Coding)               INSERT into CLAUDE.md
2. Rule 2 (Simplicity First)                  REPLACE existing "Don't over-engineer" in CLAUDE.md
3. Rule 3 (Surgical Changes)                  INSERT into CLAUDE.md
4. Rule 4 (Goal-Driven Execution)             already canonical, skip
5. Rule 5 (Fail Fast vs Graceful Handling)    INSERT into CLAUDE.md
6. Rule 6 (Documentation Priority)             INSERT into CLAUDE.md
```

User confirms, modifies, or asks to omit specific rules.

### Step 5: Apply

Apply changes one rule at a time. Show the diff for each change, then a final overall diff before completion.

**Write all directive content in English.** This skill never translates the canonical text — it goes in verbatim. Only the conversational messages around the operation adapt to the user's language.

## Insertion frame and location

Default placement: append a new top-level section to the chosen target file titled `## Baseline Coding Discipline`, containing all selected rules wrapped in the frame defined in `reference/baseline-rules.md` (intro line + tradeoff caveat + rules + closing success line).

If the section already exists, modify it in place rather than creating a duplicate.

If the project already organizes its directives into referenced reference files (detect this pattern from existing imports), prefer adding a new reference file `coding-baseline.md` and a one-line link from CLAUDE.md/AGENTS.md.

## Skipping verification

This skill **does not** invoke `guarding-agent-directives`. Reasons:

1. The set is pre-vetted — every rule survives the 5-question gate by construction
2. The goal includes replacing existing wording with canonical wording; verification would block exactly this case
3. User authority still applies — the user can omit any rule at Step 4

If the user explicitly asks for verification on top, defer to `guarding-agent-directives` and treat each rule as an "Add anyway" candidate (the user has already accepted them in principle).

## Edge cases

**No directive files exist** — Offer to create `CLAUDE.md` with the rules as initial content. Confirm before creating any new file.

**Project language is not English** — Directive content stays in English regardless (project convention). User-facing skill messages adapt to the user's language.

**User wants to add a new rule to the curated set** — That is a change to the skill itself, not a runtime invocation. Direct the user to edit `reference/baseline-rules.md` and append a new `## Rule N` section following the same shape.

**Conflicting existing content** — If existing wording directly contradicts a canonical rule (not just paraphrases it), surface the conflict and ask the user whether to keep the existing wording, replace it, or merge.

**Multiple directive files with overlapping content** — Pick one as the canonical home (most-referenced wins by default) and remove duplicates from the others on user approval.

## Quick reference

**Trigger phrases**: "apply baseline rules", "install coding baseline", "seed CLAUDE.md", "supplement AGENTS.md with standard rules", "add baseline discipline", "normalize agent directives"

**Verifier**: None (pre-vetted set; user authority via Step 4)

**Output**: Modified directive files with canonical text inserted or replaced; final unified diff

**Extension point**: append new sections to `reference/baseline-rules.md` — no other code changes required

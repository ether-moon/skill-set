---
name: guarding-agent-directives
description: Guards agent directive files (CLAUDE.md, AGENTS.md, referenced documents) against bloat by verifying every proposed addition through strict criteria while preserving user authority. Use when adding, modifying, or reviewing content in directive files, when user says "add a rule", "update CLAUDE.md", "new directive", "add instruction to AGENTS.md", or when any agent autonomously attempts to modify these files.
---

# Guarding Agent Directives

## Overview

**Core principle**: Agent directive files are loaded every session and determine what the model focuses on. Only the highest-value instructions deserve space here.

> Perfection is achieved not when there is nothing more to add, but when there is nothing more to take away. — Antoine de Saint-Exupéry

When everything is important, nothing is important. 100 rules are followed worse than 3. This skill ensures every addition earns its place.

## When to Use

- User requests adding content to CLAUDE.md, AGENTS.md, or their referenced documents
- Agent autonomously attempts to modify any directive file
- Reviewing or auditing existing directive content

## Verification

Every proposed addition must pass 5 questions:

| # | Question | FAIL if... |
|---|----------|------------|
| Q1 | **Recurring?** — Would agents repeat this mistake every session? | One-time issue, not recurring |
| Q2 | **Non-obvious?** — Can the agent NOT infer this from general knowledge? | Derivable from common sense or model defaults |
| Q3 | **Novel?** — Is this not already covered by existing directives? | Duplicate of existing content in different words |
| Q4 | **Actionable?** — Does this change concrete agent behavior? | Vague declaration with no behavioral effect |
| Q5 | **Project-specific?** — Is this unique to this project? | Universal knowledge the agent already has |

**On failure**: Present failed questions with reasoning. Offer choice:
1. **Add anyway** — User judgment overrides (user has final authority)
2. **Revise and re-verify** — Refine the content to pass
3. **Don't add** — Discard

**See**: [reference/verification.md](reference/verification.md) for detailed criteria and examples

## Workflow

```
Input received
  |
Run 5 questions
  |
  +-- All pass? --yes--> Decide placement --> Review existing content --> Apply with confirmation
  |
  +-- Any fail? ------> Present results + 3 choices
                            |
                            +-- "Add anyway"  --> Decide placement (continue above)
                            +-- "Revise"      --> Run 5 questions again
                            +-- "Don't add"   --> Done
```

### Step 1: Input received

Detect the proposed addition. Identify:
- What content is being proposed
- Which file(s) would be affected
- Who initiated (user request or agent's own attempt)

### Step 2: Run verification

Evaluate all 5 questions. Present a brief pass/fail summary with one-line reasoning per question.

**Example output format:**

```
Proposed: "Always use pnpm, not npm"

Q1 Recurring?       PASS — Agent defaults to npm every session
Q2 Non-obvious?     PASS — Custom tooling choice not inferable
Q3 Novel?           PASS — Not covered by existing directives
Q4 Actionable?      PASS — Clear tool substitution
Q5 Project-specific? PASS — Only applies to this repo

Result: 5/5 passed. Recommend adding.
```

### Step 3: Placement decision

Directive files are loaded every session, so placement affects token cost. Recommend the most specific home:

1. **Existing reference file** — Extends an existing section? Add there.
2. **New reference file + one-line link** — New area that doesn't fit existing files? Create a reference file and add a one-line pointer from CLAUDE.md/AGENTS.md.
3. **CLAUDE.md/AGENTS.md body** — Only for truly top-level declarations (the project's table of contents).
4. **Skill-internal reference** — Task-specific guidance that only matters when a particular skill triggers.

Present the recommendation with reasoning. User confirms.

### Step 4: Review existing content

Scan the target file for:
- **Duplicates** — Same instruction, different words
- **Contradictions** — New content conflicts with existing
- **Superseded content** — Old instruction made redundant by the new one

If found, suggest removal or modification. If nothing to remove, proceed — well-maintained directives may have nothing to cut.

### Step 5: Apply

**Write all directive content in English.** English consumes fewer tokens and is the language LLMs perform best in.

Write the content. Present the exact diff to user for final confirmation. Modify file only after approval.

## Red Flags

These patterns indicate the verification workflow was skipped or short-circuited:

- Adding to directive files without running verification first
- Skipping verification because the content "feels important"
- Adding vague or aspirational statements ("write clean code", "be thorough")
- Duplicating what existing directives already express in different words
- Adding universal knowledge the model already has
- Overriding the user's explicit decision after a verification failure

Any of these? Go back and run the verification workflow.

## Quick Reference

**Verification summary:** Recurring? Non-obvious? Novel? Actionable? Project-specific?

**Placement priority:** Existing reference file > New reference file + TOC link > Direct in CLAUDE.md/AGENTS.md

**User authority:** User can override any verification failure. Present reasoning, respect the decision.

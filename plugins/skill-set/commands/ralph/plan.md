---
description: Generate a declarative spec with acceptance criteria from any input source using the ralph planning loop
---

Use the ralph skill in PLANNING mode to generate a declarative spec for the current project.

**Arguments:**
- Optional: Path to an input document (design doc, notes, existing spec, any markdown)
- If no arguments provided: Generate spec from codebase analysis and user-stated goals

**Examples:**
- `/skill-set:ralph:plan` - Generate spec from codebase exploration and conversation context
- `/skill-set:ralph:plan docs/plans/2026-03-06-feature-design.md` - Generate spec from design doc
- `/skill-set:ralph:plan notes/requirements.md` - Generate spec from requirements notes

## Execution

Follow the ralph skill PLANNING mode workflow:
1. Determine input source (user-provided document or codebase-only)
2. Detect project environment
3. Verify AGENTS.md or CLAUDE.md
4. Construct planning prompt from template
5. Execute planning loop — iterates to generate and refine the declarative spec
6. Spec written to `tmp/ralph/{session-id}/spec.md`

## Constraints

- **Planning only**: No code changes, no commits during planning iterations.
- **Any input format**: Accepts design docs, notes, existing specs, or no document at all.
- **Self-refining**: Loop iterations review and improve their own output.

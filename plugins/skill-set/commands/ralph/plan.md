---
description: Generate a Ralph-ready plan from any input source using the ralph planning loop
---

Use the ralph skill in PLANNING mode to generate a plan for the current project.

**Arguments:**
- Optional: Path to an input document (design doc, notes, existing plan, any markdown)
- If no arguments provided: Generate plan from codebase analysis and user-stated goals

**Examples:**
- `/skill-set:ralph:plan` - Generate plan from codebase exploration and conversation context
- `/skill-set:ralph:plan docs/plans/2026-03-06-feature-design.md` - Generate plan from design doc
- `/skill-set:ralph:plan notes/requirements.md` - Generate plan from requirements notes

## Execution

Follow the ralph skill PLANNING mode workflow:
1. Determine input source (user-provided document or codebase-only)
2. Detect project environment
3. Verify AGENTS.md or CLAUDE.md
4. Construct planning prompt from template
5. Execute planning loop — iterates to generate and refine the plan
6. Plan written to `tmp/ralph/{session-id}/plan.md`

## Constraints

- **Planning only**: No code changes, no commits during planning iterations.
- **Any input format**: Accepts design docs, notes, existing plans, or no document at all.
- **Self-refining**: Loop iterations review and improve their own output.

---
description: Execute toward a spec via Ralph Wiggum loop with gap analysis and fresh context per iteration using Task subagents
---

Use the ralph skill in BUILDING mode to execute toward a spec for the current project.

**Arguments:**
- Optional: Path to the spec file (e.g., `tmp/ralph/2026-03-06-1430/spec.md`)
- If no arguments provided: Auto-discover most recent spec in `tmp/ralph/`

**Examples:**
- `/skill-set:ralph:execute` - Auto-discover most recent spec and execute
- `/skill-set:ralph:execute tmp/ralph/2026-03-06-1430/spec.md` - Execute toward specific spec
- `/skill-set:ralph:execute specs/feature-spec.md` - Execute spec at custom path

## Execution

Follow the ralph skill BUILDING mode workflow:
1. Find spec file (user-provided path or auto-discover)
2. Validate spec is Ralph-ready (has context, has acceptance criteria)
3. If no valid spec found → automatically enter PLANNING mode first
4. Detect project environment (test commands)
5. Verify AGENTS.md or CLAUDE.md
6. Propose DONE condition and get user confirmation
7. Construct build prompt from template
8. Execute loop via Task subagents — each iteration performs gap analysis and closes one gap
9. Report final results

## Constraints

- **Auto-planning fallback**: If no Ralph-ready spec exists, PLANNING mode runs first.
- **Sequential execution**: One subagent at a time. Each iteration's gap analysis depends on previous commits.
- **Circuit breaker**: 3 consecutive iterations with no progress (no new commits AND no spec changes) → ask user to continue or stop.

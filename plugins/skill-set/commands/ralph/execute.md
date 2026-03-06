---
description: Execute a plan via Ralph Wiggum loop with fresh context per iteration using Task subagents
---

Use the ralph skill in BUILDING mode to execute a plan for the current project.

**Arguments:**
- Optional: Path to the plan file (e.g., `tmp/ralph/2026-03-06-1430/plan.md`)
- If no arguments provided: Auto-discover most recent plan in `tmp/ralph/`

**Examples:**
- `/skill-set:ralph:execute` - Auto-discover most recent plan and execute
- `/skill-set:ralph:execute tmp/ralph/2026-03-06-1430/plan.md` - Execute specific plan
- `/skill-set:ralph:execute plans/feature-plan.md` - Execute plan at custom path

## Execution

Follow the ralph skill BUILDING mode workflow:
1. Find plan file (user-provided path or auto-discover)
2. Validate plan is Ralph-ready (has context, has actionable tasks)
3. If no valid plan found → automatically enter PLANNING mode first
4. Detect project environment (test commands)
5. Verify AGENTS.md or CLAUDE.md
6. Propose DONE condition and get user confirmation
7. Construct build prompt from template
8. Execute loop via Task subagents until DONE condition met or circuit breaker triggers
9. Report final results

## Constraints

- **Auto-planning fallback**: If no Ralph-ready plan exists, PLANNING mode runs first.
- **Sequential execution**: One subagent at a time. Tasks depend on previous commits.
- **Circuit breaker**: 3 consecutive iterations with no progress (no new commits AND no plan changes) → ask user to continue or stop.

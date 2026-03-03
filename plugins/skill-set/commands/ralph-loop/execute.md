---
description: Execute an implementation plan via Ralph Wiggum loop with fresh context per iteration using Task subagents
---

Use the executing-ralph-loop skill to execute a plan via Ralph loop for the current project.

**Arguments:**
- Optional: Path to the plan file (e.g., `plans/feature-plan.md`)
- If no arguments provided: Auto-discover plan files in `plans/`, root, or `tasks/` directories

**Examples:**
- `/skill-set:ralph-loop:execute` - Auto-discover plan file and execute ralph loop
- `/skill-set:ralph-loop:execute plans/auth-feature-plan.md` - Execute ralph loop for specific plan
- `/skill-set:ralph-loop:execute tasks/refactor-plan.md` - Execute ralph loop for specific plan

## Execution

Follow the executing-ralph-loop skill workflow:
1. Find and validate plan file
2. Ensure task checkboxes exist (convert if needed)
3. Detect project environment (test/lint commands)
4. Verify AGENTS.md or CLAUDE.md
5. Construct prompt from template (in memory)
6. Execute loop via Task subagents until all tasks complete or circuit breaker triggers
7. Report final results

## Constraints

- **Confirm before modifying**: Always preview and get user approval before changing the plan file.
- **Sequential execution**: One subagent at a time. Tasks depend on previous commits.
- **Circuit breaker**: 3 consecutive iterations with no progress → stop automatically.

---
description: Set up Ralph Wiggum loop infrastructure for executing an implementation plan with fresh context per iteration
---

Use the executing-ralph-loop skill to set up Ralph loop infrastructure for the current project.

**Arguments:**
- Optional: Path to the plan file (e.g., `plans/feature-plan.md`)
- If no arguments provided: Auto-discover plan files in `plans/`, root, or `tasks/` directories

**Examples:**
- `/skill-set:ralph-loop:execute` - Auto-discover plan file and set up ralph loop
- `/skill-set:ralph-loop:execute plans/auth-feature-plan.md` - Set up ralph loop for specific plan
- `/skill-set:ralph-loop:execute tasks/refactor-plan.md` - Set up ralph loop for specific plan

## Execution

Follow the executing-ralph-loop skill workflow:
1. Find and validate plan file
2. Ensure task checkboxes exist (convert if needed)
3. Detect project environment (test/lint commands)
4. Verify AGENTS.md or CLAUDE.md
5. Generate `ralph/loop.sh` and `ralph/PROMPT_build.md`
6. Display execution instructions

## Constraints

- **Setup only**: Do NOT run the loop. The user runs `./ralph/loop.sh` in their terminal.
- **Confirm before modifying**: Always preview and get user approval before changing the plan file.
- **Keep prompt concise**: Generated PROMPT_build.md should stay concise (~25 lines).

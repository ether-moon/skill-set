## Orient
0a. Read `{{AGENTS_FILE}}` to understand project conventions, build and test commands.
0b. Read `{{PLAN_FILE}}` to understand the current plan and progress.

## Execute (ONE task only)
1. Choose the most important uncompleted task from the plan. Consider priority, dependencies, and current project state.
2. Before making changes, search the codebase to confirm the item is NOT already implemented.
   Use subagents for parallel search. Don't assume not implemented.
3. Implement the task. Use parallel subagents for file search/read.
   Use only 1 subagent for build/test execution.
4. Run relevant tests: `{{TEST_CMD}}`
   If no test command is configured, check `{{AGENTS_FILE}}` for test instructions.
   If tests fail, debug and fix. After 3 failed attempts, note the blocker in the plan and exit.

## Wrap up
5. On success, update `{{PLAN_FILE}}`: mark the task as done, add brief notes on discoveries.
   When you discover issues or new work, add them to the plan.
6. Commit changes with a descriptive message. Do NOT push.
7. Check DONE condition: {{DONE_CONDITION}}
   If met, note completion in the plan.
8. Exit. (Next iteration starts with fresh context.)

## Rules
- Scope changes to the current task only. Do not touch unrelated code or add unsolicited improvements.
- ONE task per iteration. Choose the most important one.
- Do NOT modify AGENTS.md, CLAUDE.md, or project meta-configuration. This context is disposable.
- Full implementations only — no placeholders, stubs, or TODO markers.
- Never skip failing tests. After 3 failures, note the blocker in the plan and exit.
- Do NOT push to remote. Commits are local only.

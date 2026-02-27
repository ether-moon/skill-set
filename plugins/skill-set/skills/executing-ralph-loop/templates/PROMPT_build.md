## Orient
0a. Read `{{AGENTS_FILE}}` to understand project conventions, build and test commands.
0b. Read `{{PLAN_FILE}}` to understand current progress. Find the first unchecked task (`[ ]`).

## Execute (ONE task only)
1. Pick the first `[ ]` task from the plan.
2. Before making changes, search the codebase to confirm the item is NOT already implemented.
   Use subagents for parallel search (prefer Sonnet for cost efficiency). Don't assume not implemented.
3. Implement the task. Use parallel subagents for file search/read.
   Use only 1 subagent for build/test execution.
4. Run relevant tests: `{{TEST_CMD}}`
   If no test command is configured, check `{{AGENTS_FILE}}` for test instructions.
   If tests fail, debug and fix. After 3 failed attempts, mark the task as `[!]`
   with a blocker note and exit.

## Wrap up
5. On success, mark the task `[x]` in `{{PLAN_FILE}}`. Add brief notes on discoveries.
6. Commit changes with a descriptive message. Do NOT push.
7. Exit. (Next iteration starts with fresh context.)

## Rules
- Scope changes to the current task only. Do not touch unrelated code or add unsolicited improvements.
- ONE task per iteration. Pick the first `[ ]` only.
- Do NOT modify AGENTS.md, CLAUDE.md, or project meta-configuration. This context is disposable.
- Full implementations only — no placeholders, stubs, or TODO markers.
- Never skip failing tests. After 3 failures, mark `[!]` with blocker note and exit.
- Do NOT push to remote. Commits are local only.

## Orient
0a. Read `{{AGENTS_FILE}}` to understand project conventions, build and test commands.
0b. Read `{{SOURCE_DOC}}` to understand requirements and goals.
0c. Read `{{PLAN_FILE}}` if it exists to understand the plan so far.
0d. Explore the codebase with parallel subagents to understand current state. Search for TODOs, placeholders, minimal implementations, and inconsistent patterns.

## Analyze
1. Compare the requirements (from source document and/or codebase exploration) against existing code. Use parallel subagents for search and read operations. Do NOT assume functionality is missing — confirm with code search first.

## Generate Plan
2. Create or update `{{PLAN_FILE}}` with:
   - A **Context** section: goals, constraints, technical background — concise but sufficient for a fresh-context agent to understand the project
   - A **Tasks** section: prioritized bullet-point list of work items, sorted by importance. Each task should be independently implementable in one iteration with enough detail (files, verification approach, dependencies).
   - Note discoveries, risks, and dependencies inline with tasks.

If the plan already exists, review and refine it: reorder priorities, add missing tasks, remove completed items, improve task descriptions.

## Verify Plan Quality
3. Review the generated plan against these criteria — each task must be:
   - **Concrete** — specific files, functions, or components named
   - **Independent** — completable in one iteration without knowledge of other in-progress work
   - **Verifiable** — clear way to confirm the task is done
   - **Scoped** — one logical change per task; split if touching 10+ files across concerns

If any task fails these criteria, refine it before finishing.

## Rules
- Plan only. Do NOT implement anything. No code changes, no commits.
- Do NOT modify AGENTS.md, CLAUDE.md, or project meta-configuration.
- Each task must be concrete enough for an agent with fresh context to implement independently.
- Prioritize by importance and dependency order.
- Full implementations only in the plan — no vague "add validation" or "improve performance" tasks.

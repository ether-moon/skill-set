# Ralph-Ready Plan Criteria

A plan is Ralph-ready when each iteration's subagent can read it with fresh context and independently make progress. These criteria guide both PLANNING mode generation and BUILDING mode validation.

## Required Elements

### Context Section

The plan must contain a section that gives a fresh-context agent enough information to understand:
- **What** is being built (goals, features)
- **Why** (motivation, constraints)
- **How** the project works (tech stack, key patterns, relevant file paths)

A fresh agent reading only this section should understand the project well enough to start working.

### Actionable Tasks

Each task must be:
- **Concrete** — specific files, functions, or components named. Not "improve the API" but "add pagination to GET /api/users in src/routes/users.ts"
- **Independent** — completable in one iteration without knowledge of other tasks' implementation details. Dependencies on other tasks are OK if they're on committed code, not in-progress work.
- **Verifiable** — clear way to confirm the task is done (test passes, file exists, endpoint returns expected response)
- **Scoped** — one logical change per task. If a task requires touching 10+ files across different concerns, it should be split.

## Red Flags (Plan NOT Ready)

| Red Flag | Example | Fix |
|----------|---------|-----|
| Vague tasks | "Add validation" | "Add email format validation to UserForm in src/components/UserForm.tsx, reject inputs without @" |
| No verification | "Refactor the service layer" | Add: "verify with `npm test -- --grep 'service'`" |
| Tasks too large | "Implement authentication system" | Split into: add user model, add login endpoint, add JWT middleware, add protected route |
| Missing context | Tasks reference unnamed patterns | Add Context section explaining architecture and conventions |
| Circular dependencies | Task A needs Task B, Task B needs Task A | Reorder or merge into single task |

## Good Plan Example

```markdown
## Context

Building a REST API for a task management app. Node.js + Express + PostgreSQL.
Source in src/, tests in tests/. Run tests with `npm test`.
Database migrations in src/db/migrations/. ORM is Knex.

Current state: basic CRUD for tasks exists. Need to add user ownership and filtering.

## Tasks

- Add user_id column to tasks table
  Create migration in src/db/migrations/. FK to users table. Default null for existing rows.
  Verify: migration runs without error, rollback works.

- Update task creation to require user_id
  Modify POST /api/tasks in src/routes/tasks.ts to accept and validate user_id.
  Update tests/routes/tasks.test.ts with user_id in creation payload.
  Verify: `npm test -- --grep 'POST /api/tasks'`

- Add GET /api/tasks?user_id= filter
  Add query parameter handling in src/routes/tasks.ts.
  Add test case for filtered and unfiltered responses.
  Verify: `npm test -- --grep 'GET /api/tasks'`
```

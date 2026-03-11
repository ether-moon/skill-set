# Ralph-Ready Spec Criteria

A spec is Ralph-ready when each iteration's subagent can read it with fresh context and independently identify and close gaps. These criteria guide both PLANNING mode generation and BUILDING mode validation.

## Required Elements

### Context Section

The spec must contain a section that gives a fresh-context agent enough information to understand:
- **What** is being built (goals, features)
- **Why** (motivation, constraints)
- **How** the project works (tech stack, key patterns, relevant file paths)

A fresh agent reading only this section should understand the project well enough to start working.

### Acceptance Criteria

Each criterion must be:
- **Observable** — verifiable by examining code, running tests, or checking behavior. Not "code is clean" but "all tests pass and linter reports zero errors"
- **Declarative** — describes what should be true, not how to make it true. Not "add pagination to /api/users" but "GET /api/users supports ?page and ?limit and returns paginated results"
- **Independent** — verifiable independently of other criteria. Each criterion can be checked in isolation.
- **Complete** — together, all criteria fully describe the desired end state. Nothing is left implicit.

### Progress Log

An initially empty section populated by build iterations. Each entry records:
- Which criterion was addressed
- What was implemented
- Discoveries or new issues

## Red Flags (Spec NOT Ready)

| Red Flag | Example | Fix |
|----------|---------|-----|
| Imperative steps | "Add user_id column to tasks table" | "Tasks table has a user_id column with FK to users" |
| Unobservable criteria | "Code is well-structured" | "All modules export a single public API function" |
| Compound criteria | "Auth works and dashboard loads" | Split into separate criteria for auth and dashboard |
| Missing context | Criteria reference unnamed patterns | Add Context section explaining architecture and conventions |
| Implementation-specific | "Use Redis for caching" | "API responses for /api/products are cached with TTL ≥ 60s" (unless Redis is a hard requirement) |
| Fabricated metrics | "Reduce bundle size by 40%", "Improve response time by 3x" | Remove the number entirely unless user stated it or evidence supports it. Unsubstantiated numbers are false, not aspirational. |

## Good Spec Example

```markdown
## Context

Building a REST API for a task management app. Node.js + Express + PostgreSQL.
Source in src/, tests in tests/. Run tests with `npm test`.
Database migrations in src/db/migrations/. ORM is Knex.

Current state: basic CRUD for tasks exists. Need to add user ownership and filtering.

## Acceptance Criteria

- Tasks table has a user_id column with a foreign key to the users table. Existing rows have null user_id.
- POST /api/tasks requires a valid user_id in the request body and returns 400 if missing or invalid.
- GET /api/tasks accepts an optional ?user_id query parameter and returns only tasks belonging to that user when provided.
- GET /api/tasks without ?user_id returns all tasks (backward compatible).
- All existing tests continue to pass. New test cases cover user_id validation and filtered queries.

## Progress Log

(populated by build iterations)
```

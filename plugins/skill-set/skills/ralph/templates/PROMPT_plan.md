## Orient
0a. Read `{{AGENTS_FILE}}` to understand project conventions, build and test commands.
0b. Read `{{SOURCE_DOC}}` to understand requirements and goals.
0c. Read `{{SPEC_FILE}}` if it exists to understand the spec so far.
0d. Explore the codebase with parallel subagents to understand current state.

## Analyze
1. Compare the requirements against existing code. Use parallel subagents.
   Do NOT assume functionality is missing — confirm with code search first.

## Generate Spec
2. Create or update `{{SPEC_FILE}}` with:
   - A **Context** section: goals, constraints, technical background — concise but sufficient for a fresh-context agent.
   - An **Acceptance Criteria** section: observable, testable conditions that define "done." Each criterion describes a DESIRED OUTCOME, not an implementation step.
   - An empty **Progress Log** section (populated by build iterations).

If the spec already exists, refine: improve criteria clarity, add missing criteria, remove criteria for already-implemented functionality.

## Verify Spec Quality
3. Each acceptance criterion must be:
   - **Observable** — verifiable by examining code, running tests, or checking behavior
   - **Declarative** — describes what should be true, not how to make it true
   - **Independent** — verifiable independently of other criteria
   - **Complete** — together, all criteria fully describe the desired end state

Refine any criterion that fails these checks.

## Rules
- Spec only. Do NOT implement anything. No code changes, no commits.
- Do NOT modify AGENTS.md, CLAUDE.md, or project meta-configuration.
- Write acceptance criteria as OUTCOMES. Bad: "Add pagination to /api/users." Good: "GET /api/users supports ?page and ?limit and returns paginated results."
- Do not include criteria for functionality that already exists.

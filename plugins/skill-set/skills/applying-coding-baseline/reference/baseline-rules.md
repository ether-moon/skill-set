# Baseline Coding Discipline Rules

Canonical, pre-vetted behavioral rules applied by the `applying-coding-baseline` skill. Each rule provides:

- **Canonical text** — the exact markdown to insert into directive files (English, verbatim)
- **Detection keywords** — starting hints for finding semantically similar existing content; use semantic judgment, not strict matching

To extend the set, append a new `## Rule N: Title` section following the same shape. The skill picks up new rules automatically on next invocation — no other code changes required.

## Contents

- [Insertion frame](#insertion-frame) — the wrapper used when inserting rules into a target file
- [Rule 1: Think Before Coding](#rule-1-think-before-coding)
- [Rule 2: Simplicity First](#rule-2-simplicity-first)
- [Rule 3: Surgical Changes](#rule-3-surgical-changes)
- [Rule 4: Goal-Driven Execution](#rule-4-goal-driven-execution)
- [Rule 5: Fail Fast vs Graceful Handling](#rule-5-fail-fast-vs-graceful-handling)
- [Rule 6: Documentation Priority](#rule-6-documentation-priority)
- [Adding new rules](#adding-new-rules) — extension protocol

---

## Insertion frame

When inserting all rules at once, wrap them in this frame inside the target file:

```markdown
## Baseline Coding Discipline

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

Tradeoff: These guidelines bias toward caution over speed. For trivial tasks, use judgment.

[Rule 1 canonical text]

[Rule 2 canonical text]

[Rule 3 canonical text]

[Rule 4 canonical text]

[Rule 5 canonical text]

[Rule 6 canonical text]

These guidelines are working if: fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.
```

If a `## Baseline Coding Discipline` section already exists in the target file, edit it in place rather than creating a duplicate.

If only a subset of rules is being applied (because the user opted out of some), include only the chosen rules and keep the surrounding intro/tradeoff/closing lines.

---

## Rule 1: Think Before Coding

### Canonical text

```markdown
### 1. Think Before Coding
Don't assume. Don't hide confusion. Surface tradeoffs.

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.
```

### Detection keywords

- "assumption" / "assumptions explicit"
- "before implementing"
- "ask if uncertain" / "ask before"
- "multiple interpretations"
- "surface tradeoffs"
- "don't assume" / "do not assume"
- "name what's confusing"

---

## Rule 2: Simplicity First

### Canonical text

```markdown
### 2. Simplicity First
Minimum code that solves the problem. Nothing speculative.

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No over-defending — no "just in case" rescues, impossible validations, or internal fallbacks.
- No defensive logging — only log what is essential (e.g., errors with enough context to debug).
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.
```

### Detection keywords

- "minimum code" / "minimal code"
- "no speculative" / "nothing speculative"
- "no abstraction" / "premature abstraction"
- "no flexibility" / "no configurability"
- "overcomplicated" / "over-engineer"
- "no error handling for impossible"
- "over-defend" / "over-defending"
- "just in case" / "rescue"
- "internal fallback"
- "impossible validation"
- "defensive logging" / "speculative logging" / "essential logs"
- "single-use"

---

## Rule 3: Surgical Changes

### Canonical text

```markdown
### 3. Surgical Changes
Touch only what you must. Clean up only your own mess.

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.
```

### Detection keywords

- "surgical" / "surgical changes"
- "only what you must"
- "match existing style"
- "don't refactor" / "don't improve adjacent"
- "dead code"
- "trace directly to"
- "orphan" / "orphans"

---

## Rule 4: Goal-Driven Execution

### Canonical text

```markdown
### 4. Goal-Driven Execution
Define success criteria. Loop until verified.

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.
```

### Detection keywords

- "success criteria"
- "verifiable goal" / "verifiable"
- "loop until"
- "define success"
- "verify check" / "verify:"
- "make it work" (anti-pattern indicator)

---

## Rule 5: Fail Fast vs Graceful Handling

### Canonical text

```markdown
### 5. Fail Fast vs Graceful Handling
Match error handling to the failure source. Crash on your own bugs; handle the world's flakiness.

**Internal logic** (your code, your invariants) — fail fast:
- Assert invariants. Crash on broken state rather than silently correcting it.
- Do not catch errors you cannot meaningfully handle.
- Do not paper over impossible states with defaults or fallbacks.

**External boundaries** (network, databases, third-party APIs, file I/O, user input) — handle gracefully:
- Expect failure. Time out, retry where it helps, or surface errors with context.
- Translate boundary errors into your own error types or user-facing messages.
- Don't let one flaky upstream take down the whole system.

The test: if a failure means a bug in YOUR code, fail fast. If it means the world outside is misbehaving, handle gracefully.
```

### Detection keywords

- "fail fast" / "fail-fast"
- "graceful handling" / "graceful degradation"
- "internal vs external" / "boundary errors"
- "at the boundary" / "external failures"
- "assertion" / "assert invariant" / "invariant"
- "retry" / "timeout" (in error-handling context)
- "fallback" / "default value" (in error-handling context)
- "crash early" / "let it crash"

---

## Rule 6: Documentation Priority

### Canonical text

```markdown
### 6. Documentation Priority
Documentation is an attention budget, not a knowledge dump. Use the highest level that suffices; only drop down when it doesn't.

Always start from level 1. If renaming a variable removes the need for a comment, rename instead. If a test makes a written explanation unnecessary, write the test instead.

| Level | Medium | Use when higher levels fall short |
|---|---|---|
| 1 | **Code itself** — names, types, interfaces, structure | Default. If naming and structure already convey intent, stop here. |
| 2 | **Tests** — runnable behavior specifications | Two or more scenarios; edge cases; behavior the code alone does not make obvious. |
| 3 | **API doc comments** at class / module / function level | Public API; usage constraints; non-obvious side effects; required setup or invariants. |
| 4 | **Commit / PR messages** | The *why* behind a change — rationale, trade-offs, context history-readers will need. |
| 5 | **Separate documents** | Architecture decisions, cross-system integration, onboarding, anything that outlives a single change. |

The test: every paragraph of prose documentation should exist because no higher-level mechanism could carry that meaning.
```

### Detection keywords

- "documentation priority" / "documentation hierarchy"
- "self-documenting code" / "names convey intent"
- "redundant comment" / "comment vs rename"
- "tests as documentation" / "tests as specs" / "BDD"
- "docstring" / "API doc" / "javadoc" / "doxygen" / "jsdoc"
- "commit message rationale" / "PR description"
- "ADR" / "architecture decision record"
- "separate document" / "design document"
- "knowledge dump" / "attention budget"

---

## Adding new rules

1. Append a new `## Rule N: Title` section
2. Include both `### Canonical text` and `### Detection keywords` subsections
3. Keep the canonical text language English, formatted as a `### N. Title` markdown block ready for direct insertion
4. The skill picks up new rules automatically on next invocation

If a new rule conflicts with or supersedes an existing one, update the existing rule rather than adding a new one to avoid contradictions in the inserted output.

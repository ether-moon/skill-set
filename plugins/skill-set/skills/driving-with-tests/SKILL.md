---
name: driving-with-tests
description: Guides test strategy beyond TDD — running suites before changes (orient), exploring beyond test coverage (probe), guarding tests as specification, and designing multi-layer test architectures. Use when starting a coding session, designing test strategy, reviewing test changes, assessing test coverage, or deciding what type of test to write. Trigger phrases include "run tests first", "what's the test status", "design a test strategy", "what should I test", "review test changes".
---

# Driving with Tests

## Overview

Tests are specification, not verification. The test harness is the defensible asset — code is replaceable, the harness is not.

This skill covers the strategic layer **around** the TDD cycle:
- **Before TDD**: Orient — run the suite, establish baseline
- **After TDD**: Probe — explore beyond test boundaries
- **Across changes**: Guard — protect tests as specification
- **Across tasks**: Test architecture — choose the right layer for each test

**REQUIRED:** `developing-test-first` for the Red/Green/Refactor discipline itself.

## When to Use

**Triggers:**
- Starting a coding session on an unfamiliar codebase
- Designing test strategy for a new feature
- Reviewing diffs that modify test files
- Assessing what's tested and what isn't
- Deciding which test layer (unit, integration, E2E) to use
- User says "run the tests first" or "what's the test status"

**Do NOT use for:**
- The TDD cycle itself (Red/Green/Refactor) → `developing-test-first`
- Classifying CI failure output → `autofixing-and-escalating`
- Iterative implementation loop → `ralph`
- Test framework API docs → `understanding-code-context`

## Orient — Before You Touch Code

> "First run the tests." — Simon Willison

Purpose: establish baseline, discover pre-existing failures, understand what's tested and what isn't.

**Steps:**
1. **Detect test command** (see Framework Detection below)
2. **Run the full suite**, record results
3. **Note**: pre-existing failures, coverage gaps, slow tests
4. **If pre-existing failures exist**: understand them before proceeding — are they known? Are they related to your task?

This tells you: there IS a test suite, how to run it, what it covers, and how healthy the project is. Skip this and you're flying blind.

### Framework Detection

| File Found | Test Command |
|------------|-------------|
| CLAUDE.md / AGENTS.md | **Check first** — explicit test commands are most reliable |
| `package.json` (scripts.test) | `npm test` / `npx jest` / `npx vitest` |
| `pyproject.toml` / `pytest.ini` | `pytest` |
| `Gemfile` | `bundle exec rspec` |
| `go.mod` | `go test ./...` |
| `Cargo.toml` | `cargo test` |
| `build.gradle` / `pom.xml` | `./gradlew test` / `mvn test` |

Show detected framework to your human partner. Ask to confirm or correct.

## Probe — After Tests Pass

> Tests cover what you anticipated. Probing discovers what you didn't.

Passing tests are necessary but not sufficient. After the TDD cycle turns green, manually explore the system to find what tests missed.

**Techniques** (details in `reference/probing.md`):
- **CLI**: `curl` for HTTP endpoints, REPL sessions for libraries, command-line tools for CLIs
- **Browser/UI**: manual walkthrough, edge cases in forms, error states, responsive behavior
- **Demo scripts**: lightweight scripts that exercise the happy path end-to-end
- **Edge cases**: boundary values, empty inputs, concurrent operations, permission variations

**Probe-to-Test Loop:** gap found → write a new test → back to `developing-test-first`

**Reflection:** if multiple probe cycles reveal problems, step back. Document what you've learned — what failed, why, what assumptions were wrong — and adjust strategy before the next attempt. Stored failure context prevents repeating the same mistakes.

→ Details: `reference/probing.md`

## Guard — Tests Are Specification

Modifying tests = changing the specification. Every test change deserves the same review rigor as production code.

| Test Change | Type | Action |
|-------------|------|--------|
| Adding new test | Extension | Always OK |
| Updating assertion to match new behavior | Spec change | Confirm with your human partner |
| Weakening assertion to make it pass | **Red flag** | STOP — likely hiding a bug |
| Deleting a failing test | Spec removal | Confirm with your human partner |
| Fixing a flaky test | Maintenance | Fix root cause — never skip, delete, or retry-and-ignore |

**Rules:**
- Never weaken tests to get a green bar
- Never delete a test to remove a failure without understanding why it fails
- Treat test diffs with the same review rigor as production code diffs
- If you're changing a test to match changed behavior, say so explicitly — "I'm changing the spec because X"

## Test Architecture

Choose the right test layer for each concern. Brief taxonomy — details in `reference/test-design.md`.

**Layers:**
- **Unit**: fast, isolated logic. One function or method. Milliseconds.
- **Integration**: component wiring, real dependencies. Service boundaries.
- **E2E**: user-visible flows. Browser or CLI.
- **Acceptance**: spec validation. Maps to requirements (REQ-xxx, user stories).

**Selection guide:**

| What to Test | Layer | Why |
|-------------|-------|-----|
| Pure logic, calculations, transformations | Unit | Fast feedback, pinpoint failures |
| Service interactions, database queries | Integration | Catches wiring bugs mocks hide |
| User-facing workflows, critical paths | E2E | Validates what the user actually sees |
| Spec requirements, business rules | Acceptance | Makes the spec executable |

**Coverage is a compass, not a target.** 100% line coverage with bad assertions is worthless. Use coverage to find untested areas, not to declare victory.

→ Details: `reference/test-design.md`

## Language Detection

Detect and use your human partner's preferred language for all conversational output:

1. Check message language in the current conversation
2. Check project documentation language
3. Check recent git commit patterns
4. Default to English if no clear indication

**Adapt**: All user-facing messages, reports, feedback
**Keep in English**: Code, test names, file paths, commands

## Red Flags

| Red Flag | Fix |
|----------|-----|
| Skipping Orient — jumping straight to coding | Run the full suite first. You need baseline state. |
| Green bar → ship without probing | Tests cover what you thought of. Probing finds what you didn't. |
| Modifying tests to make them pass | You're changing the spec. Is that intentional? Confirm with your human partner. |
| 100% coverage = done | Coverage measures lines exercised, not behavior verified. Probe. |
| Deleting a flaky test instead of fixing it | Flakiness is a symptom. Find the root cause — timing, shared state, ordering. |
| All tests at the same layer | Match layer to risk. Unit for logic, integration for wiring, E2E for flows. |
| No acceptance tests for spec requirements | Spec without tests = unverified contract. |
| Never reviewed test diffs | Test changes are spec changes. Review them. |

## Composability

- **Standalone**: Use for Orient/Probe/Guard/Architecture without TDD enforcement
- **With `developing-test-first`**: Full discipline — Orient → TDD → Probe → Guard
- **Within `ralph` iterations**: Orient before each iteration, Probe after green

## Reference

- `reference/test-design.md` — Multi-layer architecture, test bus, property-based and contract testing
- `reference/probing.md` — Manual exploration techniques, edge case patterns, reflection
- **REQUIRED:** `developing-test-first` — Red/Green/Refactor TDD discipline

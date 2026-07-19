---
name: driving-with-tests
description: Guides implementation and verification through Orient, Red/Green/Refactor, Probe, and Guard. Use for new behavior, bug fixes, refactors, test strategy, test reviews, coverage decisions, baseline checks, or requests to work test-first or practice TDD.
---

# Driving with Tests

## Core Flow

Use one integrated flow:

```text
Orient → Red/Green/Refactor → Probe → Guard
```

Choose the applicable mode before changing code. The middle phase may be strict, characterization-led, or replaced by an explicit alternative validation; the surrounding Orient, Probe, and Guard phases remain.

## Select the Mode

| Work | Default |
|---|---|
| New behavior | Red/Green/Refactor, one vertical slice at a time |
| Bug fix | Reproduce with a failing regression test, then Red/Green/Refactor |
| Pure refactor | Add characterization only where coverage is missing; preserve the green baseline and do not manufacture a failing test |
| Documentation, configuration, generated code, analysis, or test-only work | Strict TDD is excluded; state and run alternative validation appropriate to the artifact |
| Existing implementation or user changes already present | Preserve them; add a regression or characterization test first, then close uncovered gaps without deleting or reverting the work |

A project directive or the user may require strict TDD. Apply that stricter policy even where the default table would allow a lighter mode. When instructions conflict or the behavior is unclear, surface the conflict before mutation.

## Orient

Establish evidence before editing:

1. Read project directives for required commands and test policy.
2. Detect the relevant test command from project manifests and nearby tests.
3. Run the smallest trustworthy baseline, expanding to the full suite when feasible.
4. Record pre-existing failures, slow tests, and coverage gaps separately from the requested change.
5. Identify the user-visible behavior and the cheapest test layer that can prove it.

Common commands:

| Project signal | Likely command |
|---|---|
| `package.json` | project test script, Jest, or Vitest |
| `pyproject.toml`, `pytest.ini` | `pytest` |
| `Gemfile` | `bundle exec rspec` |
| `go.mod` | `go test ./...` |
| `Cargo.toml` | `cargo test` |
| `build.gradle`, `pom.xml` | Gradle or Maven test task |

Project instructions override this detection table.

## Red/Green/Refactor

For new behavior and bug fixes, run one vertical slice:

1. **RED** — write one minimal behavior test and verify it fails for the intended missing behavior.
2. **GREEN** — make the smallest production change that passes the new test and relevant existing tests.
3. **REFACTOR** — improve structure only while every relevant test remains green.
4. Repeat for the next behavior learned from the previous slice.

Do not batch speculative tests ahead of implementation. Do not count syntax, import, or fixture errors as RED. Do not weaken an assertion to obtain GREEN.

For the full discipline, existing-code path, and failure handling, read `reference/tdd.md`.

## Probe

Automated tests cover anticipated behavior. Exercise the changed path as a user or caller would:

- run the CLI with valid, invalid, and boundary inputs;
- exercise HTTP or library APIs through a realistic entry point;
- walk UI success, error, and permission states;
- inspect persisted state and observable side effects;
- test boundaries, empty input, concurrency, and recovery where relevant.

When probing finds a gap, add a regression test and return to the appropriate Red/Green/Refactor slice. See `reference/probing.md`.

## Guard

Tests are executable specifications. Review test changes with production-code rigor:

- adding coverage extends the specification;
- changing expected behavior changes the specification and must be intentional;
- weakening or deleting a test to make a run green is a stop condition;
- flaky tests require root-cause work, not skip/retry-and-ignore;
- a targeted suite supports iteration, but the project-required broader suite gates completion.

Report the baseline, new test evidence, probe evidence, full validation, and any known pre-existing failures separately.

## Test Layer

Choose the lowest layer that proves the behavior without hiding the risk:

- **Unit** for isolated calculations and transformations.
- **Integration** for persistence, wiring, protocols, and real dependency behavior.
- **End-to-end** for critical user-visible flows.
- **Acceptance/contract** for stable requirements and service boundaries.

Coverage identifies areas to inspect; it is not a completion percentage. Read `reference/test-design.md` for layer selection, property tests, and contracts.

## Failure Handling

- A RED test that errors must be repaired until it fails on the intended assertion.
- A baseline failure must be isolated from the change before implementation proceeds.
- If a test is impractical, explain the seam or environment constraint and choose the strongest reproducible alternative validation.
- If existing/user code predates tests, never delete it to recreate an artificial test-first history.
- If probing repeatedly exposes the same class of gap, pause and revise the test strategy.

Use the user's language for runtime reports. Keep test names, commands, paths, and repository documentation in English.

## References

- `reference/tdd.md` — vertical Red/Green/Refactor and existing-code rules
- `reference/probing.md` — manual exploration and probe-to-test loop
- `reference/test-design.md` — test layers, property tests, and contracts

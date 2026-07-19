# Red/Green/Refactor

## Vertical Slices

Use one test, one implementation, one cycle. A slice proves one observable behavior and lets the next test respond to what implementation taught you.

Avoid horizontal batches of imagined tests followed by a batch implementation. They tend to lock in signatures and structures before any behavior feedback exists.

## RED

Write one minimal test with a name that states the behavior. Prefer real collaborators; isolate external or nondeterministic boundaries only where necessary.

### Verify RED

Run the test and confirm:

- it fails rather than merely errors;
- the failure message matches the missing or broken behavior;
- the fixture and assertion are capable of passing after a correct implementation; and
- existing unrelated failures are identified separately.

If it passes immediately, the behavior already exists or the test is insensitive. Strengthen or redirect the test before production changes.

## Minimal GREEN

Make the smallest behavior change that satisfies the failing test. Run the focused test and the relevant surrounding suite. Fix production code rather than weakening the assertion.

Minimal does not mean careless: retain required error handling, safety checks, and project conventions. It means no speculative behavior or unrelated cleanup.

## REFACTOR

Refactor only while green. Improve names, remove duplication, or deepen a seam without adding new behavior. Re-run the relevant suite after each structural step.

The next behavior starts a new RED; do not smuggle it into refactoring.

## Existing Implementation or User Changes

Do not delete, revert, or hide existing work merely to reconstruct a test-first sequence.

1. Read the implementation and its callers.
2. Add a characterization test for behavior that must be preserved, if coverage is absent.
3. For a reported bug, add a regression test that fails on the remaining gap.
4. Make the smallest correction and retain the user's changes.

If the implementation already satisfies the requested behavior, a characterization/regression test may pass immediately; record that it establishes missing coverage rather than claiming a RED cycle.

## Pure Refactor

Start from a green baseline. Add characterization tests only for uncovered behavior at risk. Keep the suite green through small structural changes; do not create an artificial failing assertion when no behavior should change.

## Non-TDD Artifacts

For documentation, configuration, generated code, analysis, and test-only work, name an alternative validation before editing. Examples include schema validation, lints, render checks, generator drift checks, fixture execution, or a focused test-suite run.

## Strict Override

Explicit project or user strict-TDD rules take precedence. Apply their required sequence and evidence; do not silently downgrade them to characterization or alternative validation.

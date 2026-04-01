# Test Design — Multi-Layer Architecture

**Load this reference when:** designing test strategy for a new feature, deciding which test layer to use, or setting up testability architecture.

## Test Layer Taxonomy

| Layer | Speed | Scope | Purpose | Tradeoff |
|-------|-------|-------|---------|----------|
| **Unit** | ms | Single function/method | Verify isolated logic | Fast but can't catch wiring bugs |
| **Integration** | seconds | Multiple components | Verify component interaction | Catches real bugs but slower |
| **E2E** | seconds–minutes | Full system | Verify user-visible flows | Closest to reality but brittle, slow |
| **Acceptance** | varies | Requirement-level | Verify spec is met | Makes spec executable but needs maintenance |

## Layer Selection Guide

| What You're Testing | Recommended Layer | Rationale |
|---------------------|-------------------|-----------|
| Pure functions, calculations, transformations | Unit | Fast, deterministic, pinpoints failures |
| Data access, query logic | Integration | Mocking databases hides real bugs |
| Service-to-service communication | Integration + Contract | Catches serialization and protocol issues |
| API endpoints | Integration | Test through the API, not the UI |
| User-facing workflows, critical paths | E2E | Validates what the user actually sees |
| Business rules from spec (REQ-xxx) | Acceptance | Makes requirements testable and traceable |
| Edge cases, error handling | Unit | Fastest to write and run |
| Performance characteristics | Integration or E2E | Needs real infrastructure to measure |

## Test Bus / API Separation

Testing through the UI is slow, opaque, and brittle. A **test bus** exposes business rules through APIs so tests can drive application logic directly.

**Architecture principle:** Separate presentation from domain logic. Tests invoke the same API the UI uses, without going through the UI.

**Benefits:**
- Tests are faster (no rendering, no browser)
- Tests are more reliable (no UI timing issues)
- Tests are clearer (assert on data, not DOM)
- Forces good decoupling between layers

**When to test through UI:** Only for E2E tests verifying user-visible flows. All other tests should go through the API/service layer.

## Specification-by-Example

Instead of narrative requirements, use concrete rules paired with examples. This makes the specification executable — the tests ARE the spec.

**Pattern:**
- Each requirement has a stable ID (e.g., `REQ-001`)
- Each requirement has concrete examples (given/when/then)
- Examples are version-controlled with the code
- Unanswered questions are tracked alongside requirements

**Formats:** Gherkin (BDD), plain test files with descriptive names, or structured comments. The format matters less than the practice of pairing rules with examples.

## Coverage Strategy

**Coverage is a compass, not a target.**

- Use coverage reports to find **untested areas** — that's valuable
- Don't chase a coverage percentage — that leads to meaningless tests
- 100% coverage with bad assertions proves nothing
- Low coverage in a critical module is a signal to investigate

**What to prioritize:**
1. Business-critical paths (payment, auth, data integrity)
2. Recently changed code (most likely to have bugs)
3. Complex logic (high cyclomatic complexity)
4. Error handling paths (where production bugs actually live)

## Property-Based Testing

When to use: functions with clear **invariants** that should hold for all inputs.

**Good candidates:**
- Serialization roundtrips: `deserialize(serialize(x)) == x`
- Data transformations: output always satisfies a property
- Parsers: valid input always produces valid output
- Sort functions: output is ordered, same length, same elements

**Tools:** Hypothesis (Python), fast-check (JS/TS), proptest (Rust), gopter (Go)

Property-based tests complement example-based tests — they find edge cases you didn't think of.

## Contract Testing

When to use: service boundaries where client and server evolve independently.

**What it verifies:**
- Message formats remain compatible
- Required fields are always present
- Response shapes match consumer expectations

**Pattern:** Consumer writes a contract describing expected messages. Provider verifies their implementation satisfies the contract. Both sides can evolve independently as long as contracts pass.

**Tools:** Pact (multi-language), contract tests in integration test suites

## The Bottom Line

No single test layer is sufficient. Use the right layer for each concern:
- **Unit** for logic
- **Integration** for wiring
- **E2E** for user flows
- **Acceptance** for spec compliance

And measure coverage as direction, not destination.

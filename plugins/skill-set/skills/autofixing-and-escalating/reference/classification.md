# Classification Reference

Detailed guidance for applying the OBVIOUS vs AMBIGUOUS classification. Use this when the primary criteria in SKILL.md leave a borderline case.

## Criteria Pass/Fail Examples

### Criterion 1: Source identified a specific issue

| Pass | Fail |
|------|------|
| "Line 42: `userId` is never null-checked before `.toString()`" | "This module could use some cleanup" |
| "Missing `await` on `fetchUser()` at line 15" | "The error handling here seems incomplete" |
| "Unused import `lodash` at line 3" | "Consider reviewing the imports" |

### Criterion 2: Objectively verifiable

| Pass | Fail |
|------|------|
| Variable is demonstrably unused (no references) | "This function is too long" (subjective threshold) |
| API call uses a deprecated method per official docs | "This naming is confusing" (opinion) |
| Type mismatch caught by static analysis | "This could be more readable" (preference) |

### Criterion 3: Exactly one correct fix

| Pass | Fail |
|------|------|
| Remove unused import (only option: delete the line) | "Add error handling" (try/catch? Result type? error code?) |
| Fix typo: `recieve` → `receive` | "Improve performance" (cache? batch? index? restructure?) |
| Add missing `await` keyword | "Extract this logic" (where? what interface? what name?) |

### Criterion 4: No reasonable disagreement

| Pass | Fail |
|------|------|
| Null check prevents guaranteed crash | Adding a log statement (some prefer silent, some verbose) |
| Removing dead code with zero references | Choosing between two valid error-handling strategies |
| Fixing SQL injection with parameterized query | Deciding whether to inline or extract a helper function |

## Domain-Specific Examples

### PR Review Comments
- **OBVIOUS**: "@reviewer points out `user.name` is accessed without null check and the type allows null" — one fix, no debate
- **AMBIGUOUS**: "@reviewer suggests using the repository pattern instead of direct DB calls" — architectural choice

### Linter Warnings
- **OBVIOUS**: "no-unused-vars: `tempResult` is declared but never read" — remove it
- **AMBIGUOUS**: "complexity: function exceeds cyclomatic complexity threshold of 10" — multiple refactoring strategies exist

### Security Findings
- **OBVIOUS**: "SQL injection: user input concatenated into query string" — parameterize the query
- **AMBIGUOUS**: "Weak hash algorithm: MD5 used for password storage" — which algorithm? bcrypt? argon2? scrypt? Migration strategy?

### Test Failures
- **OBVIOUS**: "Expected `true` but got `false` — assertion uses wrong comparator (`==` vs `===`)" — fix the comparator
- **AMBIGUOUS**: "Flaky test: passes 90% of runs — suspected race condition" — fix timing? add retry? restructure test? mock the dependency?

## Edge Cases

### Mixed Items (Part Obvious, Part Ambiguous)
When a single issue contains both an obvious fix and an ambiguous suggestion, split them:
- Apply the obvious portion as OBVIOUS
- Escalate the ambiguous portion as AMBIGUOUS
- Note the relationship between the two in the escalation

**Example**: "Fix the null check (line 42) and also consider restructuring this into a guard clause pattern"
- OBVIOUS: Add the null check
- AMBIGUOUS: Restructure into guard clause (design choice)

### Hidden Trade-offs
Some items appear obvious but have non-obvious consequences:
- Removing an "unused" variable that is actually used via reflection or dynamic access → AMBIGUOUS
- "Simple" rename that affects serialization, API contracts, or database columns → AMBIGUOUS
- Adding a null check that changes control flow in unexpected ways → AMBIGUOUS

**Rule**: If the fix has side effects beyond the immediate change, classify as AMBIGUOUS.

### Borderline Items
When an item almost meets all four OBVIOUS criteria but one is uncertain:
- Does the fix truly have zero alternatives? If you can imagine two reasonable developers choosing differently → AMBIGUOUS
- Would you bet your production deploy on this being right? If not → AMBIGUOUS

## Decision Tree

```
Is a specific issue explicitly identified?
├── No → SKIP (not actionable)
└── Yes →
    Is the issue objectively verifiable?
    ├── No → AMBIGUOUS
    └── Yes →
        Is there exactly one correct fix?
        ├── No → AMBIGUOUS
        └── Yes →
            Would any reasonable developer disagree?
            ├── Yes → AMBIGUOUS
            └── No →
                Does any ALWAYS AMBIGUOUS rule apply?
                ├── Yes → AMBIGUOUS
                └── No → OBVIOUS
```

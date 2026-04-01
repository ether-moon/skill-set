# Manual Probing and Reflection

**Load this reference when:** tests are passing and you need to verify the feature actually works beyond what tests cover, or when multiple attempts at a task keep failing.

## Why Probing

Tests cover what you **anticipated**. Probing discovers what you **didn't**.

Coverage measures lines exercised, not behavior verified. A function can have 100% line coverage and still break on inputs no test sends. Passing the test suite is necessary but not sufficient — check that the program works in practice before declaring success.

## CLI Probing

For backend services, APIs, and libraries:

- **HTTP endpoints**: `curl` with different payloads, headers, methods, auth states
- **REPL sessions**: `python -c`, `node -e`, or interactive REPL to exercise a new API
- **CLI tools**: run the tool with valid, invalid, and edge-case arguments
- **Database**: query the database after operations to verify state

**What to look for:** unexpected error messages, missing fields in responses, incorrect status codes, state not persisted correctly.

## Browser/UI Probing

For web UIs and visual interfaces:

- **Manual walkthrough**: follow the user flow end-to-end in a real browser
- **Edge cases in forms**: empty submissions, extremely long input, special characters, rapid double-clicks
- **Error states**: disconnect network, submit invalid data, revoke permissions
- **Responsive behavior**: resize window, test on mobile viewport
- **Screenshot verification**: capture the result visually — screenshots reveal layout and rendering issues that DOM assertions miss

## Demo Scripts

Lightweight scripts that exercise the feature as a user would:

- Write a short script in `/tmp` that imports the new module and runs the happy path
- For web apps: a minimal Playwright or browser automation script
- For CLIs: a shell script that runs the tool with typical inputs

Demo scripts serve as smoke tests. When they reveal issues, upgrade them into permanent tests.

## Edge Case Patterns

Common probing targets that tests often miss:

| Category | Examples |
|----------|----------|
| **Boundary values** | 0, 1, -1, MAX_INT, empty string, null |
| **Empty inputs** | Empty array, empty object, missing optional fields |
| **Concurrency** | Two requests at once, rapid repeated actions |
| **Error paths** | Network timeout, disk full, permission denied |
| **Permission variations** | Admin vs regular user, unauthenticated, expired token |
| **State transitions** | Create → update → delete, re-create after delete |
| **Unicode/i18n** | Emoji, RTL text, multi-byte characters, long strings |

## Probe-to-Test Loop

When probing reveals a gap:

1. **Write a test** that captures the gap (back to `developing-test-first`)
2. **Watch it fail** (Red phase)
3. **Fix the issue** (Green phase)
4. **Probe again** to verify the fix and look for related gaps

This loop converts manual exploration into permanent automated coverage. Every probe that finds a bug should produce a regression test.

## Reflection

When multiple attempts at a task keep failing, or probe cycles repeatedly reveal problems:

**Stop and reflect before the next attempt.**

1. **Document what failed** — which specific assertion, input, or behavior
2. **Document why** — what assumption was wrong, what was missed
3. **Document what you've tried** — approaches taken and their results
4. **Adjust strategy** — based on stored failure context, change the approach

This prevents repeating the same mistakes across attempts. The reflection doesn't need to be formal — a few sentences stored in working memory or a comment in the code is enough. The key is to explicitly articulate what went wrong before trying again.

**When to reflect:**
- After 2+ failed Red/Green cycles on the same requirement
- After probing reveals the same category of bug repeatedly
- When stuck and unsure what to try next

**The goal:** use failure as information, not just frustration.

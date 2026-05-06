# Codebase Cross-Reference

How to use the codebase to answer questions, surface contradictions, and stress-test claims — instead of pinging the user.

## Contents

- [The Core Principle](#the-core-principle)
- [High-Value Cross-Checks](#high-value-cross-checks)
- [Tool Selection](#tool-selection)
- [When to Stop Reading and Start Asking](#when-to-stop-reading-and-start-asking)
- [Reporting What You Read](#reporting-what-you-read)

## The Core Principle

Every question to the user has a cost. Most questions about *what currently exists* have zero cost to answer from the code. The asymmetry says: read first, ask second.

## High-Value Cross-Checks

These are the cross-checks that catch the most defects.

### 1. "X already exists" check

Before proposing to build a helper, retry, parser, validator, or utility, search for it.

```
Tools: Grep (for keywords), Glob (for filename patterns)
Example: User plans a new `withRetry` wrapper.
  → Grep "retry" in src/
  → Found `src/lib/withRetry.ts`. Reuse, don't rebuild.
```

### 2. Stated behavior vs. actual behavior

When the user says "X currently does Y," check that the code agrees.

```
User: "The /orders endpoint returns 404 if the order is cancelled."
Read src/routes/orders.ts → endpoint returns 200 with cancelled=true.
Surface: "Code returns 200 with cancelled=true, not 404. Is the plan
relying on 404, or is the behavior changing as part of this work?"
```

### 3. Invariant claims

When the user states "this never happens" or "this is always true," look for code that assumes the opposite.

```
User: "User always has an email at signup."
Grep for "email == null" or "!email" → found 3 sites that handle null email.
Surface: "Three call sites currently handle null email. Either they're dead
code, or your invariant is not enforced. Which?"
```

### 4. Dependency direction claims

When the user describes a dependency direction ("A calls B, never the reverse"), verify with an import scan.

```
User: "billing/ never depends on auth/."
Grep "from.*auth" inside src/billing/ → found imports.
Surface contradiction.
```

### 5. Naming consistency

When a new term is introduced, check if a different name for the same concept already exists.

```
User plans to add a "RevocationToken".
Grep "Cancel|Revoke|Invalidate.*Token" → found "InvalidationToken" in
src/auth/tokens.ts. Surface: "Same concept already named InvalidationToken.
Reuse the name, or rename the existing one?"
```

## Tool Selection

| Question type | First tool |
|---|---|
| Does symbol X exist? | Grep with the name |
| Where is X defined? | LSP `goToDefinition` if a path is known, else Grep |
| Who calls X? | LSP `findReferences` if precise, else Grep |
| Is there code matching pattern Y? | Grep with regex |
| What files match a structure? | Glob |
| Wide unfamiliar area | Dispatch an Explore agent (`Agent` tool) |

Use the LSP tool when symbol-precise (avoids false positives from comments, strings, similar names). Use Grep when the question is broader.

## When to Stop Reading and Start Asking

Reading the codebase is not free. Stop and ask the user when:

- You have made 3-5 unsuccessful searches or 2 read-throughs without finding evidence either way
- The question requires intent (why was it built this way?) not facts (what does it do?)
- The question requires future direction not present state
- Reading would require understanding a system far outside the current scope

The recommended-answer rule (Rule 2) still applies: if you ask after exploration, lead with what you found and what you'd recommend on that basis.

## Reporting What You Read

When you read code on the user's behalf, report it concisely:

```
WRONG (too verbose):
  "I searched the codebase using Grep with the pattern 'retry' and found
   several matches in src/lib/retry.ts which is a utility module that
   provides exponential backoff functionality with configurable max
   attempts and..."

RIGHT (terse, evidence-first):
  "Found `src/lib/withRetry.ts` (exponential backoff, configurable max
  attempts). Reuse it. Confirm?"
```

Lead with the finding, link the file path, recommend, ask for confirmation.

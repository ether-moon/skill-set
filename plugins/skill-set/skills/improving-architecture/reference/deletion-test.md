# The Deletion Test

The single most useful heuristic for distinguishing deep from shallow modules.

## The test

Imagine deleting the module. Inline its body at every call site.

- **If complexity vanishes:** the module was a pass-through. It added vocabulary but no leverage. *Shallow.* Delete or merge.
- **If complexity reappears across N callers:** the module was concentrating something. Each caller would now have to reproduce the work. *Deep.* Keep it.
- **If the module mostly disappears but a small invariant has to be re-asserted at each call site:** the module was earning its keep at exactly that invariant. Keep it, possibly trim the surrounding code.

## How to actually run it

You don't need to literally delete the file. Run it as a thought experiment in three steps:

### Step 1 — list callers

Use `LSP findReferences` on the public API of the module. Get the actual call sites.

### Step 2 — for each call site, write what would need to change

For each caller, ask: if the module disappeared, what would I have to put here?

- Just the function body? → That's a pass-through.
- The function body plus a couple of guards / coercions / wrap-unwraps? → Borderline; think about whether those guards are the same at every site.
- The function body plus state, error handling, retries, ordering? → The module is doing real work.

### Step 3 — count the duplication

If the same non-trivial thing would be repeated at 3+ call sites, the module is deep enough to keep. Two callers can be a coincidence; three suggests a pattern worth concentrating in one place.

If the "complexity" is just type coercion and could be replaced by a one-liner everywhere, it's shallow.

## What counts as "complexity reappearing"

| Counts | Doesn't count |
|---|---|
| Stateful logic — counters, retries, caches | Argument forwarding |
| Invariant assertions that callers would otherwise forget | Type narrowing the caller already does |
| Coordinated multi-step work | Renaming a single function call |
| Error classification with non-trivial branching | Error re-throw |
| Locking, ordering, atomicity | Plain dispatch |

## Common false-negatives (modules that *look* shallow but pass the test)

- **Validation modules.** Look like one function calling N small checks. But the checks together encode a domain rule that callers would otherwise duplicate poorly. The module is the *single source of truth* for the rule.
- **Idempotency wrappers.** May look like passthroughs. But the idempotency key handling, ledger lookup, and outcome caching would be a nightmare to reproduce per caller.
- **Migration shims.** Often have a tiny implementation but their value is "all the legacy handling lives here, callers stay clean."

## Common false-positives (modules that *look* deep but fail the test)

- **Large helper bags.** A module with ten unrelated functions can look "big" but each function is shallow on its own and callers compose them anyway.
- **Wrappers that just rename.** A `BillingService.charge()` that just calls `paymentProvider.charge()` adds vocabulary, no leverage.
- **"Service" objects with leaked internals.** If callers reach inside (`service.repo.findById(...)`), the seam was theatrical.

## When the test is ambiguous

Apply the **two-adapter test**: does this module have two real, used adapters? If yes, the seam is real. If no, the seam is hypothetical and can usually be deleted.

If still ambiguous, leave it alone. Architectural review should not propose changes the team is unsure about. List it under "watch" rather than "propose."

## What to do with the result

| Result | Action |
|---|---|
| Clearly shallow, single caller | Inline at the call site, delete the module |
| Clearly shallow, multiple callers | Inline; if duplication appears across callers, propose a different deepening that captures the *real* invariant |
| Clearly deep | Leave alone. Possibly improve naming or trim incidental complexity. |
| Borderline | Note it; come back when you have more callers or more friction |
| Two-adapter test fails (only one adapter, no plan for another) | Propose collapsing the seam — the indirection is unjustified |

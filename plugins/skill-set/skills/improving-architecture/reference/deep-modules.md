# Deep Modules

Full elaboration of the depth / seam / adapter / locality vocabulary, with examples at function, module, and package scales.

Source: John Ousterhout, *A Philosophy of Software Design*. The vocabulary here adapts that book's framing to be operational for an agent.

## Contents

- [Module / Interface / Implementation](#module)
- [Depth — the central concept](#depth)
- [Examples by scale](#examples-by-scale)
- [Seam / Adapter](#seam)
- [Leverage / Locality](#leverage)
- [How these terms compose](#how-these-terms-compose)
- [Common shallow patterns to look for](#common-shallow-patterns-to-look-for)
- [Things that look shallow but are not](#things-that-look-shallow-but-are-not)

## Module

Anything with an interface and an implementation. The *scale* varies — a single function is a module, a class is a module, a package is a module, a microservice is a module. Reasoning about depth applies at every scale.

## Interface

Everything a caller must know to use the module. This is *not just the type signature* — it includes:

- Type signatures (input, output, errors)
- Invariants the caller must preserve (preconditions)
- Invariants the module guarantees (postconditions)
- Ordering constraints (must call X before Y)
- Side effects (writes to disk, network, mutates input)
- Error modes (what can fail, how it surfaces, recovery options)
- Configuration (what the caller has to decide)

Interface = the surface area of cognitive load on every caller.

## Implementation

The code inside the module. Everything callers do *not* need to know.

## Depth

The ratio between leverage gained and interface complexity carried.

```
deep:    [ ============= IMPLEMENTATION ============= ]
         [   interface   ]

shallow: [ implementation ]
         [   interface    ]
```

A **deep module** does a lot of work behind a small interface. A caller passes minimal information, gets significant behavior in return.

A **shallow module** is one whose interface is nearly as complex as its implementation. Callers carry almost as much cognitive load as they would have without the module.

## Examples by scale

### Function scale

**Deep:** `parseISODate(s: string) → Date | ParseError`. One input, one well-typed output, all the date-parsing horror inside.

**Shallow:** `applyOrderDiscount(order, discount, taxRate, locale, customerTier, productCategory, isHoliday, ...) → Order`. The caller has to assemble all the inputs anyway — the function is barely doing anything the call site wasn't already doing.

### Module scale

**Deep:** A `RetryPolicy` module that exposes `withRetry(operation, policy)`. Callers don't think about exponential backoff, jitter, max attempts, error classification — those live behind the interface.

**Shallow:** A `RetryHelper` that exposes `getBackoffMs`, `shouldRetry`, `incrementAttempt`, `resetAttempts`. Every caller has to compose these correctly. The "module" is just a namespaced bag of helpers.

### Package scale

**Deep:** A `billing/` package that exposes `chargeCustomer(customerId, amount, idempotencyKey)`. Inside: payment provider abstraction, retry on transient failures, idempotency checks, audit logging, ledger writes.

**Shallow:** A `billing/` package that exposes `getPaymentProvider`, `formatAmount`, `validateAmount`, `recordCharge`, `recordRefund`, `auditLog`. Every caller has to thread these together. The package adds no leverage over a folder.

## Seam

A seam is a point where the interface lives — a place behavior can be altered without editing the existing code in place.

A seam is *interesting* when there's a real reason to vary behavior at it: testing (substitute a fake), product needs (swap providers), platform constraints (switch implementations). A seam invented for "potential future flexibility" is just speculative complexity.

> One adapter = hypothetical seam. Two adapters = real seam.

If only one adapter exists and is the only one that ever will exist, the seam is fictional and can usually be deleted.

## Adapter

A concrete thing that satisfies an interface at a seam. `PostgresUserRepo` and `InMemoryUserRepo` are two adapters at the `UserRepo` seam.

Adapters justify seams. A seam without at least two real adapters is suspicious.

## Leverage

The user-facing benefit of depth. What does the caller stop having to think about? What gets shorter? What can callers compose now that they couldn't before?

## Locality

The maintainer-facing benefit of depth. When this concept changes, where do the changes go?

- **High locality:** changes to one concept stay in one module
- **Low locality:** changes to one concept ripple across N callers

Locality is the property that lets a small team reason about a big system. Depth is the mechanism that produces locality.

## How these terms compose

> A **deep module** sits behind a **seam** with one or more **adapters**. Its **interface** carries low cognitive load relative to its **implementation**, giving callers **leverage** and concentrating maintenance in one place — that's **locality**.

When proposing a deepening, the proposal should make explicit what changes for **leverage** (callers) and **locality** (maintainers). If both can't be named, the deepening isn't real.

## Common shallow patterns to look for

| Pattern | Smell |
|---|---|
| Helper module with N independent functions | Each caller has to compose them — locality wasted |
| Pure function extracted from a stateful flow for "testability" | The bugs are in the stateful flow; pure-function tests pass while the real path breaks |
| Wrapper that just renames calls | Pass-through with vocabulary churn — see deletion test |
| "Service" that exposes its CRUD | Callers know the storage shape; the seam isn't doing anything |
| Configuration object passed through three layers | Each layer is a shallow conduit; consider pushing the consumer up to the source |

## Things that look shallow but are not

| Looks shallow | But actually |
|---|---|
| One-line wrapper | If it consolidates an invariant in one place, it's earning its keep |
| Tiny module with one function | If two adapters exist, the seam is real |
| Module with verbose interface | Verbose ≠ shallow — a deep module can have many parameters if each one carries real semantic weight |

The deletion test is the disambiguator. Run it when in doubt.

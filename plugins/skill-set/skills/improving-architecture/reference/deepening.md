# Deepening

How to deepen a cluster of shallow modules safely, given its dependencies. Assumes the vocabulary in `deep-modules.md` — **module**, **interface**, **seam**, **adapter**.

## Dependency categories

When assessing a candidate for deepening, classify its dependencies. The category determines how the deepened module is tested across its seam.

### 1. In-process

Pure computation, in-memory state, no I/O. **Always deepenable** — merge the modules and test through the new interface directly. No adapter needed.

### 2. Local-substitutable

Dependencies that have local test stand-ins (PGLite for Postgres, in-memory filesystem, embedded Redis). **Deepenable if the stand-in exists.** The deepened module is tested with the stand-in running in the test suite. The seam is internal; no port at the module's external interface.

### 3. Remote but owned (Ports & Adapters)

Your own services across a network boundary — microservices, internal APIs, your own message queues. **Define a port (interface) at the seam.** The deep module owns the logic; the transport is injected as an **adapter**. Tests use an in-memory adapter. Production uses an HTTP / gRPC / queue adapter.

Recommendation shape:

> "Define a port at the seam, implement an HTTP adapter for production and an in-memory adapter for testing, so the logic sits in one deep module even though it's deployed across a network."

### 4. True external (Mock)

Third-party services you don't control — Stripe, Twilio, OAuth providers. **Take the external dependency as an injected port; tests provide a mock adapter.** Different from category 3 only in that you cannot control the wire-level behavior, so the mock is not a proxy for "real but cheap" — it's an explicit fiction the test owns.

## Seam discipline

- **One adapter means a hypothetical seam. Two adapters means a real one.** Don't introduce a port unless at least two adapters are justified (typically production + test). A single-adapter seam is just indirection.
- **Internal seams vs. external seams.** A deep module can have internal seams (private to its implementation, used by its own tests) as well as the external seam at its interface. **Don't expose internal seams through the interface just because tests use them** — that leaks implementation into the contract.

## Testing strategy: replace, don't layer

When deepening shallow modules:

- **Old unit tests on the shallow modules become candidates for removal** once tests at the deepened module's interface exist — consider deleting the now-redundant ones, but keep any that document a non-obvious invariant a future reader would need.
- **Write new tests at the deepened module's interface.** The interface is the test surface.
- **Tests assert on observable outcomes through the interface, not internal state.**
- **Tests should survive internal refactors** — they describe behavior, not implementation. If a test has to change when the implementation changes, it's testing past the interface.

## Choosing the strategy in practice

```
Pure computation?                       → Category 1. Just merge.
Has a local stand-in?                   → Category 2. Use it.
Network-bounded, you own both sides?    → Category 3. Port + 2 adapters.
Third-party you don't own?              → Category 4. Mock at the seam.
```

If a single deepening candidate spans multiple categories (e.g., it computes plus calls Stripe), split the seams: pure computation stays internal, the Stripe call gets its own port + mock.

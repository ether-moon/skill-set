Resume this challenge of an existing cache proposal from its recorded decisions. The proposal adds a cache for search results, calls for a “standard” eviction policy, and leaves partial-failure behavior unspecified.

The user has already answered:

1. Cache keys are per tenant. Global keys were rejected because they could violate tenant isolation.
2. The time to live is 60 seconds. A 5-minute time to live was rejected because results could remain stale too long.
3. When asked which invalidation signal should expire entries, the user replied: “Stop here and return the final decision ledger now.” No invalidation option was selected.

Treat that last reply as an explicit early stop. Return the final decision ledger only, preserve unresolved branches, and do not ask another question or turn the ledger into implementation steps.

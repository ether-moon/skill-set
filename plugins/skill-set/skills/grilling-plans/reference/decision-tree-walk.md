# Decision Tree Walk

## Extract Branches

List decisions the plan leaves silent, vague, contradictory, or open to multiple interpretations. Useful probes include inputs, outputs, error modes, invariants, empty cases, failure cases, ownership, and undefined domain terms.

Do not ask a question when repository evidence answers the present-state part. Record the evidence and reserve the question for intent or future direction.

## Dependency Order

A branch constrains another when changing the first answer would invalidate the second. Ask the constraining decision first.

```text
storage ownership → transaction boundary → retry behavior → test strategy
```

Independent branches can be ordered by impact and answerability. Prefer a high-leverage decision whose answer eliminates downstream branches.

## Resolve One Leaf

A decision becomes Confirmed only when its value, behavior, or boundary is precise enough that implementation would not need to guess. “Standard approach,” “fast,” “later,” and “it depends” remain Unresolved.

Rejected alternatives include a brief rationale so they are not silently reintroduced later.

## Five-Question Stop

Count user questions, not code searches. After five user answers, stop and return Confirmed, Rejected, and Unresolved. Do not continue down a newly opened branch in the same invocation. The user may explicitly request another round, which starts with the existing ledger.

If the user stops early, return the ledger immediately. Never frame continuation as required.

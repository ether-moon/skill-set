# Decision Tree Walk

## Extract Branches

List decisions the plan leaves silent, vague, contradictory, or open to multiple interpretations. Useful probes include inputs, outputs, error modes, invariants, empty cases, failure cases, ownership, and undefined domain terms.

Do not ask a question when repository evidence answers the present-state part. Record the evidence and reserve the question for intent or future direction.

## Dependency Order

A branch constrains another when changing the first answer would invalidate the second. Order the constraining decision first. If a downstream question applies only under a particular upstream answer, state that condition and include it in the same batch.

```text
storage ownership → transaction boundary → retry behavior → test strategy
```

Independent branches can be ordered by impact and answerability. Prefer a high-leverage decision whose answer eliminates downstream branches.

## Resolve the Batch

A decision becomes Confirmed only when its value, behavior, or boundary is precise enough that implementation would not need to guess. “Standard approach,” “fast,” “later,” and “it depends” remain Unresolved.

Rejected alternatives include a brief rationale so they are not silently reintroduced later.

## Complete the Batch

Ask every decision question exposed by the current plan and evidence in one response. Do not defer a known question solely to wait for an earlier answer, and do not impose an arbitrary question-count limit.

After the user's batch response, update Confirmed, Rejected, and Unresolved together. If an answer exposes a new branch or leaves a question unanswered, include every such question in the same next batch.

If the user stops early, return the ledger immediately. Never frame continuation as required.

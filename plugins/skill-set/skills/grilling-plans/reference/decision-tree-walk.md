# Decision Tree Walk

How to identify dependency order, when to descend, and what counts as a leaf.

## Identifying the Tree

Before asking the first question, read the plan and write down the **undecided branches** — points where the plan is silent, hand-wavy, or admits multiple interpretations. Each branch is a candidate question.

A useful prompt to surface branches:

- "What inputs does this assume exist?"
- "What outputs does this commit to?"
- "What error modes are unhandled?"
- "What invariants must hold across boundaries?"
- "What happens at the empty case, the boundary case, the failure case?"
- "What does each domain term in the plan actually mean here?"

Branches surfaced this way are usually unordered. Order them next.

## Dependency Order

Two branches are **dependent** if the answer to one constrains the answer to the other. Resolve the constraining branch first.

```
Q: "Which datastore are we using?"   ← decide first
Q: "Which transaction isolation?"     ← depends on datastore
Q: "How do we test it?"               ← depends on both
```

If two branches are independent, pick whichever the user can answer faster. Save the high-cognitive-load decisions for when context is rich.

When you cannot tell whether two branches are dependent, ask the user — but propose your guess with reasoning (Rule 2 still applies).

## When to Descend vs. Back Up

After a question is answered, an answer often opens a **sub-tree**:

```
Q1: "Which datastore?" → "Postgres"
   └─ sub-Q: "Which Postgres version?"
   └─ sub-Q: "Connection pooling strategy?"
   └─ sub-Q: "Migration tool?"
```

**Descend** when the sub-questions are tightly coupled to the answer (changing the parent invalidates them).

**Back up** when the sub-questions are independent of the answer and would stall progress.

A useful test: if the user says "let's come back to that," the question belongs higher in the tree, not deeper. Note it on a stack and move on.

## What Counts as a Leaf

A branch is a **leaf** (no further questions) when:

- The answer is captured precisely (specific value, specific term, specific behavior)
- No reasonable reader of the plan would interpret the answer differently
- Implementation can begin from the answer alone

Watch for **false leaves**:

- "We'll figure that out in implementation" — not a leaf, just deferred
- "Standard approach" — not a leaf, the standard is the question
- "It depends" — not a leaf, the dependency is the question

## When to Stop

Grilling ends when **every branch is a leaf**. Not when the user is tired. Not when 30 minutes have elapsed. Not when the plan "feels good."

If the user wants to stop early, surface what is still un-leafed:

> "Three branches remain undecided: cache eviction policy, retry budget, and the meaning of 'partial success' in the response shape. Stopping now means implementation will guess at these. Continue, or accept the guesses?"

This makes the cost of stopping explicit. The user can still choose to stop — but with eyes open.

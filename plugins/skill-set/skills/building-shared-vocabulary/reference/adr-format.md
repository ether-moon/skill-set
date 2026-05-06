# ADR Format

Exact template for an Architecture Decision Record, plus the three-criterion check that gates whether to write one at all.

## File location and naming

Single directory at `/docs/adr/`. Filenames are sequential and slug-suffixed:

```
docs/adr/0001-event-sourced-orders.md
docs/adr/0002-postgres-for-write-model.md
docs/adr/0003-cancellation-as-line-item-operation.md
```

The slug is a noun phrase describing what the decision is about. Avoid verbs ("use-postgres") in favor of subjects ("postgres-for-write-model").

## The three-criterion gate

**Write an ADR only if all three are true.**

### 1. Hard-to-reverse

Undoing this decision later costs real engineering effort.

| Hard-to-reverse | Easy-to-reverse |
|---|---|
| Database choice | Logger choice |
| Public API shape | Internal helper signature |
| Domain model decomposition | File organization |
| Wire protocol | Local variable naming |
| Library that touches every module | Library used in one place |

### 2. Surprising-without-context

A future reader, looking only at the code, would wonder *why* this choice was made.

If the code makes the reasoning obvious, no ADR is needed. ADRs exist for choices whose rationale is not visible at the call site.

### 3. The result of a real trade-off

There were genuine alternatives. They were considered. One was picked for specific reasons.

"We picked X because it's the standard" is not a real trade-off. "We picked X over Y because Y's eventual consistency would break our cancellation invariant" is.

## Template

The minimal template:

```markdown
# <Short title of the decision>

<1-3 sentences: what's the context, what we decided, and why.>
```

That's it. **An ADR can be a single paragraph.** The value is in recording *that* a decision was made and *why* — not in filling out sections. Resist the urge to bulk it up.

## Optional sections

Only include these when they add genuine value. Most ADRs do not need them.

- **Status** frontmatter (`proposed | accepted | deprecated | superseded by ADR-NNNN`) — useful when decisions are revisited
- **Considered Options** — only when the rejected alternatives are worth remembering
- **Consequences** — only when non-obvious downstream effects need to be called out

If you reach for a section, ask: would removing this section lose information a future reader would need? If not, drop it.

## Updates

ADRs are immutable in principle. To change a decision:

1. Write a new ADR explaining the new decision and what changed
2. Add Status to the old ADR: `Superseded by ADR-NNNN`
3. Cross-link both directions

Do not delete superseded ADRs. The history is the value.

## What qualifies for an ADR

- **Architectural shape.** "We're using a monorepo." "The write model is event-sourced; the read model is projected into Postgres."
- **Integration patterns between contexts / services.** "Ordering and Billing communicate via domain events, not synchronous HTTP."
- **Technology choices that carry lock-in.** Database, message bus, auth provider, deployment target. Not every library — just the ones that would take a quarter to swap out.
- **Boundary and scope decisions.** "Customer data is owned by the Customer context; other contexts reference it by ID only." The explicit no-s are as valuable as the yes-s.
- **Deliberate deviations from the obvious path.** "We're using manual SQL instead of an ORM because X." Anything where a reasonable reader would assume the opposite — these stop the next engineer from "fixing" something deliberate.
- **Constraints not visible in the code.** "We can't use AWS because of compliance requirements." "Response times must be under 200ms because of the partner API contract."
- **Rejected alternatives when the rejection is non-obvious.** If you considered GraphQL and picked REST for subtle reasons, record it — otherwise someone will suggest GraphQL again in six months.

## What does NOT qualify

- Renaming a function or file
- Picking lint / formatter rules
- Choosing a logger library (unless logging is a domain concern)
- Migrating from yarn to pnpm, or similar tool swaps
- Adding a new test framework
- Picking commit message style

If the decision is reversible by a single PR with no migration cost, it is not ADR-worthy.

# CONTEXT.md Format

Exact format for a project's domain glossary, with examples.

## File location

A single file at the repository root: `/CONTEXT.md`.

## Top-level structure

```markdown
# <Project Name> — Domain Context

Brief one-paragraph orientation. What domain does this project serve?
What is the primary user / actor? What is the value proposition?

## Language

[Term entries — see "Term entry format" below]

## Relationships

- An **<Term A>** has many **<Term B>**
- A **<Term B>** belongs to one **<Term A>**
- [...]

## Example dialogue

> **Dev:** "When a **Customer** places an **Order**, do we create the **Invoice** immediately?"
> **Domain expert:** "No — an **Invoice** is only generated once a **Fulfillment** is confirmed."

## Flagged ambiguities

- "<phrase>" — what's still unclear, what we ruled out, what's outstanding
```

Keep "Language" flat by default — every term sits at the same level. **Group terms under sub-headings only when natural clusters emerge** (e.g., a project with distinct sub-domains may benefit from `### Ordering` / `### Billing` groupings). If all terms belong to a single cohesive area, leave it flat.

The **Example dialogue** is a short conversation between a developer and a domain expert that demonstrates how the canonical terms interact in practice. It clarifies boundaries between related concepts (e.g., `Order` vs. `Cart`, `Invoice` vs. `Payment`) better than definitions alone. Write it the way the conversation would actually happen — bold the canonical terms, keep it under a half-dozen exchanges.

## Term entry format

Each entry is a level-3 heading with the canonical name (bold), an italicized one-line definition, and an optional "_Avoid:_" line listing deprecated alternatives.

```markdown
**<Canonical Term>**:
The single-sentence definition that a domain expert would recognize.
_Avoid_: <deprecated alternative 1>, <deprecated alternative 2>
```

Example:

```markdown
**Order**:
A confirmed customer purchase intent. Carries one or more **Line Items**, has a single **Customer**, and progresses through a fixed lifecycle.
_Avoid_: cart, basket, transaction (those mean different things — see `Cart` and `Payment Transaction`)

**Line Item**:
A single product line within an **Order** — quantity, unit price at time of order, product reference. Cancellation operates at this level.
_Avoid_: order line, item

**Cancellation**:
User-initiated revocation of one or more **Line Items**, possibly the whole **Order**. Distinct from system-initiated **Timeout**.
_Avoid_: refund (refund is a money-flow concept, see `Payment Reversal`)
```

`_Avoid_` is **optional**. Include it only when there is a real deprecated alternative the team has used or might mistakenly use. A clean, unambiguous term needs no Avoid line:

```markdown
**Fulfillment**:
The act of preparing and shipping the goods on a confirmed **Order**. A single **Order** maps to one or more **Fulfillments** (split shipments).
```

If you find yourself inventing deprecated alternatives just to fill the line, drop it.

## Rules

### What belongs

- Concepts a domain expert would name in conversation
- Terms that appear in user-facing copy, marketing, support
- Concepts that have a lifecycle, identity, or invariants in the system
- Roles, actors, capabilities

### What does NOT belong

- Implementation classes (`OrderRepository`, `OrderDTO`)
- Framework concepts (`Component`, `Reducer`, `Middleware`)
- Helper utilities, parsers, validators
- File paths, table names, environment variables
- Anything that would change if the implementation language changed

### Naming

- Canonical term in **bold** at first mention in any entry
- PascalCase for concepts that map to entity-like things ("Order", "Line Item")
- Plain lowercase for verbs and lifecycle states ("cancellation", "fulfilled") unless the domain itself capitalizes them

### Conflicts

When a new term clashes with an existing one, update the entry. Mark the resolution under "Flagged ambiguities" with a brief history line:

```markdown
- "backlog" was previously used to mean both the *tool* hosting issues and the *body of work* inside it — resolved 2026-04: the tool is the **Issue Tracker**; "backlog" is no longer used as a domain term.
```

### Updates

Each update is one entry at a time, in the moment of resolution. Do not batch.

If you find yourself wanting to "do a vocabulary cleanup pass," that's a sign the conversation isn't surfacing terms naturally — return to grilling instead.

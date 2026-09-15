# Directive Verification Examples

Use these examples to resolve uncertain judgments; the five questions in `SKILL.md` are the decision criteria.

## Necessity and Added Value

- **Capability guidance:** A custom test runner is repeatedly replaced by a familiar default. Keep the project-specific command; distinguish a recorded failure from a prediction that it might happen.
- **Environment fact:** A legacy endpoint returns XML despite surrounding JSON APIs. Check the current contract before retaining the exception.
- **Explicit policy:** The user requires English commit messages. Familiarity or generality is not grounds for removal; check whether the policy is already expressed at the correct scope.
- **No established need:** A one-time outage or generic advice to handle errors carefully does not establish a durable rule. Recommend omission or concrete wording without inventing recurrence evidence.

A shorter duplicate may replace an older rule, but should not become another copy. Search for equivalent behavior in the applicable directive chain, not just identical words.

When a guide duplicates a schema, response example, or directory inventory, prefer an authoritative path or section plus a reading condition. Check that source before claiming the copy is stale. Preserve non-obvious constraints such as data routing, state transitions, and test isolation, even when removing generic advice around them.

## Clarity

“Run `make lint` before committing” has an observable trigger and action. “Value code quality” does not. Split mixed rules so a concrete requirement is not discarded with vague advice.

For optional approaches, give the desired result and relevant constraints. Keep an exact sequence when order is required by a protocol, fragile operation, or explicit policy.

Resolve routine implementation choices from code and conventions. For conflicting test commands or policies, use established authority; if requirements, external behavior, or permission remain unclear, ask for that decision. Do not silently select one or invent a compromise. A translation exception should name the affected keys or files, rather than implying an application-wide exemption.

## Scope and Cost

A database migration rule belongs in a reference loaded for migration work. A rule hidden in an unreferenced file will not help; a rule that forces deployment-guide reading for spelling corrections adds unrelated work.

Evaluate induced work as well as text length: broad exploration, repeated unchanged tests, unnecessary delegation, and duplicate approval requests. Do not invent measured savings from a shorter file.

Inspect applicable parent directives even during narrow work. Follow additional references when they govern the task or resolve a suspected duplicate or conflict. A full audit covers the requested chain; a scoped inspection must identify what remains unverified.

## Authority and Completion

- A request to audit directives is read-only, even if the fixes seem obvious.
- A user-confirmed exact diff can be applied without another confirmation.
- A scoped editing request permits completing that revision, but not inventing additional policy or expanding external authority.
- A request to show a proposal and wait must stop before mutation.
- An agent proposing production-write permission cannot approve its own proposal.

If a rule needlessly interrupts already authorized local work, recommend wording that identifies the completion condition and the actual external or policy decision boundary. Do not infer authorization from model competence.

## Reporting

Use a compact rule/verdict/reason table unless a full five-question report is requested. Keep explicit policy, uncertainty, and inspection limits visible. In `verify-addition`, a failed proposal still offers `Add anyway`, `Revise`, and `Don't add`. In `audit-existing`, recommendations never mutate files.

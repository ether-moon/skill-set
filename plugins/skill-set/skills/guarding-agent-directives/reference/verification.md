# Directive Verification Criteria

## Q1 Recurring?

Would the same agent behavior recur across sessions without this instruction?

- Pass: a custom project command is repeatedly replaced with a familiar default.
- Fail: a one-time outage or incident note.

## Q2 Non-obvious?

Can a capable agent infer the rule from code, configuration, standard practice, or nearby documentation?

- Pass: a legacy endpoint returns XML despite the surrounding JSON APIs.
- Fail: handle errors carefully.

## Q3 Novel?

Does the loaded directive chain already express the same behavior?

- Pass: a new constraint absent from all parent and referenced files.
- Fail: “test before committing” when an existing rule already requires the same check.

Search semantic duplicates, not only exact wording. If new wording is better, recommend replacing the old rule.

## Q4 Actionable?

Can compliance be observed or tested?

- Pass: run `make lint` before committing.
- Fail: value code quality.

Split a mixed vague/actionable rule and evaluate only the concrete part.

## Q5 Correct location?

Is this the narrowest directive location that both applies to the intended tasks and is loaded when needed?

- Pass: a database migration rule in the database workflow reference loaded by migration tasks.
- Fail: the same rule in a top-level file loaded for every unrelated session.
- Fail: a rule hidden in a file that the relevant directive never references.

A general but explicit user policy can pass. Q5 evaluates scope and loading, not whether the policy is unique to one repository.

## Overrides and Audits

In verify-addition, any failed question requires the choices `Add anyway`, `Revise`, and `Don't add`. A user may override the recommendation after seeing the evidence and exact diff.

In audit-existing, the same checks support keep, revise, or remove recommendations, but no file changes occur.

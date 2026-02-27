# Verification Criteria — Detailed Guide

Detailed pass/fail criteria and examples for each of the 5 verification questions.

## Q1: Recurring?

**Question:** Would agents repeat the same mistake every session without this directive?

**PASS examples:**
- "Always run `pnpm` instead of `npm` in this project" — Agent defaults to npm every session
- "Korean commit messages required" — Agent defaults to English every time
- "Use port 3001, not 3000 (3000 is used by another service)" — Agent picks 3000 every time

**FAIL examples:**
- "Don't delete the .env file" — One-time incident, not a recurring pattern
- "Remember to check the logs" — Too vague to be a recurring mistake
- "The API was down on Tuesday" — Temporal fact, not recurring

**Key test:** If you removed this directive, would the agent make this exact mistake in the next 5 sessions?

---

## Q2: Non-obvious?

**Question:** Can the agent NOT infer this from general knowledge?

**PASS examples:**
- "This project uses a custom test runner at scripts/test.sh, not jest" — Agent can't know custom tooling
- "The legacy API returns XML, not JSON" — Project-specific API behavior
- "Deploy requires VPN connection first" — Infrastructure detail not in code

**FAIL examples:**
- "Use meaningful variable names" — Basic programming knowledge
- "Handle errors gracefully" — Default agent behavior
- "Write tests for new features" — Standard development practice

**Key test:** Would a skilled developer joining this project need to be told this, or would they figure it out?

---

## Q3: Novel?

**Question:** Is this not already covered by existing directives?

**PASS examples:**
- Adding a new tool to the workflow that isn't documented anywhere
- A constraint for a newly added dependency
- A new team convention not captured in existing docs

**FAIL examples:**
- "Always test before committing" when existing directive says "TDD required"
- "Use TypeScript" when tsconfig.json and existing directives already establish this
- Restating the same rule with slightly different wording

**Key test:** Search existing CLAUDE.md, AGENTS.md, and all referenced files. Is the essence of this already expressed?

---

## Q4: Actionable?

**Question:** Does this change concrete agent behavior?

**PASS examples:**
- "Run `make lint` before committing" — Clear action to take
- "API responses must include `request_id` field" — Testable requirement
- "Use `pnpm` not `npm`" — Specific tool choice

**FAIL examples:**
- "Code quality is important" — No concrete behavior change
- "We value clean architecture" — Aspirational, not actionable
- "Be careful with database operations" — Vague caution

**Key test:** Can you observe the agent doing something differently because of this directive? If you can't tell whether the agent followed it or not, it's not actionable.

---

## Q5: Project-specific?

**Question:** Is this unique to this project, not universal knowledge?

**PASS examples:**
- "This monorepo uses Turborepo with specific pipeline config" — Project architecture
- "Auth tokens are stored in Redis, not cookies" — Project design decision
- "The `users` table has a soft-delete column `deleted_at`" — Project schema detail

**FAIL examples:**
- "SQL injection is a security risk" — Universal knowledge
- "Use environment variables for secrets" — Industry standard
- "Git branches should be descriptive" — General best practice

**Key test:** Would this directive be useful in a completely different project? If yes, the agent already knows it.

---

## Edge Cases

### "It passed 4 out of 5"

Present the failed question with clear reasoning. Offer the user three choices. Don't argue — present facts and let the user decide.

### "The content is a mix of actionable and vague"

Suggest splitting: extract the actionable part, discard the vague part. Re-verify the extracted content.

### "It's a duplicate but better worded"

Suggest replacing the existing directive with the improved version rather than adding both.

### "It's universal knowledge but the agent keeps getting it wrong here"

This might actually pass Q1 (recurring) even if it fails Q5 (project-specific). Present both findings honestly. The recurring nature may justify inclusion despite being general knowledge.

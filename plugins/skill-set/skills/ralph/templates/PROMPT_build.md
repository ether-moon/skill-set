## Orient
0a. Read `{{AGENTS_FILE}}` to understand project conventions, build and test commands.
0b. Read `{{SPEC_FILE}}` to understand the desired end state and progress so far.

## Gap Analysis
1. Compare each acceptance criterion in the spec against the current codebase.
   Use subagents for parallel search. For each criterion, determine: MET or UNMET.
   Use the Progress Log as hints, but always verify against actual code.
2. From the UNMET criteria, identify the single most important gap to close.
   Consider: foundational work before features, dependency order, risk, test verifiability.
   If all criteria appear met, verify thoroughly — then note completion and exit.

## Implement (ONE gap only)
3. Confirm the gap is real — search codebase to verify the criterion is truly unmet.
4. Implement the minimum change needed to satisfy the criterion.
   Use parallel subagents for file search/read. Use only 1 subagent for build/test.
5. Run relevant tests: `{{TEST_CMD}}`
   If tests fail, debug and fix. After 3 failed attempts, note the blocker in the Progress Log and exit.

## Wrap up
6. Append to the Progress Log section of `{{SPEC_FILE}}`:
   - Which criterion was addressed
   - What was implemented
   - Any discoveries or new issues
   Do NOT modify the Acceptance Criteria section.
7. Commit changes with a descriptive message. Do NOT push.
8. Check DONE condition: {{DONE_CONDITION}}
   If met, note completion in the spec.
9. Exit.

## Rules
- ONE gap per iteration. Close the most important unmet criterion.
- Do NOT modify the Acceptance Criteria section. Only append to the Progress Log.
- Do NOT modify AGENTS.md, CLAUDE.md, or project meta-configuration.
- Full implementations only — no placeholders, stubs, or TODO markers.
- Never skip failing tests. After 3 failures, note the blocker and exit.
- Do NOT push to remote.

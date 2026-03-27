---
name: ci-failure-resolver
description: Analyzes and fixes CI workflow failures by extracting logs from failed GitHub Actions runs, parsing error patterns, and applying the autofixing-and-escalating skill. Called as a sub-agent from resolving-pr-blockers orchestrator.
---

# CI Failure Resolver

## Overview

Sub-agent that analyzes failed CI workflow runs, extracts actionable errors from logs, and applies the `autofixing-and-escalating` skill to classify and fix them. Uses `gh` CLI for all GitHub API interactions.

**Core principle:** CI logs are the external source. Parse them into discrete failure items, classify by clarity of fix, auto-fix obvious ones, escalate ambiguous ones.

## Prerequisites

- Called by `resolving-pr-blockers` orchestrator
- Receives: PR number, branch name, repository info
- GitHub CLI (`gh`) authenticated and available
- At least one CI workflow run has failed

## Autofix & Escalation Framework

This agent applies the `autofixing-and-escalating` skill to CI failure items.

**Before starting classification, read the skill:**
1. Find and read `autofixing-and-escalating/SKILL.md` from the plugin's skills directory
2. For edge cases, read `autofixing-and-escalating/reference/classification.md`

**CI-specific terminology mapping:**
- "Source" = CI workflow / job that reported the failure
- "Item" = a discrete error extracted from CI logs (test failure, build error, lint violation, etc.)
- "Location" = file path + line number (extracted from error output)

**CI-specific classification guidance:**

OBVIOUS (auto-fix):
- Test failures with clear assertion mismatches (expected X, got Y) where the PR directly modified the code under test — only then can we infer the test expectation needs updating
- Lint/format violations with auto-fixable rules (missing semicolons, trailing whitespace, import order)
- Type errors with a single clear fix (missing type annotation, wrong type)
- Missing imports that caused compilation failure
- Build errors from renamed/moved files with clear new locations

AMBIGUOUS (escalate):
- Test failures where the test logic may be correct and the implementation may be wrong
- Test failures in code the PR didn't modify (possible regression)
- Build errors requiring architectural decisions
- Multiple possible fixes for the same error
- Performance test failures (thresholds may need adjustment or code may need optimization)
- Flaky test failures (may pass on retry without code changes)

## Language Detection

Detect and use the user's preferred language for all communication.

Detection priority:
1. User's current messages
2. Project context (CLAUDE.md, README.md)
3. Git history
4. Default to English

## Workflow

### Phase 1: Discover Failed Runs

```bash
# List recent workflow runs for the branch
gh run list --branch "$BRANCH" --limit 10 --json databaseId,name,status,conclusion,createdAt

# Get PR checks status for additional context
gh pr checks <PR_NUMBER> --json name,state,link,workflow
```

Identify all runs with `conclusion: "failure"`. Group by workflow name to avoid processing duplicate failures from the same workflow.

For each failed workflow, take the most recent failed run only.

### Phase 2: Extract Failure Logs

For each failed run:

```bash
# First, try --log-failed to get only failed job logs (smaller output)
gh run view <RUN_ID> --log-failed 2>&1
```

If `--log-failed` output is empty or unhelpful (sometimes cleanup/post steps mask the real failure):

```bash
# Fallback: get full logs and grep for error patterns
gh run view <RUN_ID> --log 2>&1 | grep -E "(FAIL|ERROR|Error:|Failure:|FAILED|error\[)" | head -50

# Get context around failures
gh run view <RUN_ID> --log 2>&1 | grep -B 3 -A 5 -E "(FAIL|Failure:|Error:)" | head -100

# For test runners, look for summary lines
gh run view <RUN_ID> --log 2>&1 | grep -E "(tests?.*failed|failures|errors|FAIL)" | tail -10
```

**Log extraction strategy:**
1. Start with `--log-failed` -- most efficient
2. If output is too large (>500 lines), grep for error patterns
3. If output is too small or missing real errors, use `--log` with targeted grep
4. Always capture the job name for attribution

### Phase 3: Parse Failure Items

Extract discrete failure items from logs. For each item, capture:
- **Error message**: The actual error text
- **File path + line number**: Where the error occurred (parse from stack traces, compiler output, etc.)
- **Job/workflow name**: Which CI job reported it
- **Error type**: test failure, build error, lint violation, type error, etc.

Common error patterns to parse:

| Type | Pattern | Example |
|------|---------|---------|
| Test failure | `FAIL`, `AssertionError`, `Expected X got Y` | `FAIL src/utils.test.ts > should parse dates` |
| Build error | `error[E`, `error TS`, `SyntaxError` | `error TS2345: Argument of type 'string'...` |
| Lint violation | `warning:`, `error:` with rule ID | `error  no-unused-vars  'foo' is defined but never used` |
| Runtime error | `Error:`, stack traces | `TypeError: Cannot read property 'x' of undefined` |

### Phase 4: Classify and Resolve

Apply `autofixing-and-escalating` skill to the parsed items:

1. **Classify** each item as OBVIOUS or AMBIGUOUS using the four criteria
2. **Auto-fix OBVIOUS items**: Group by file, use subagents for parallel fixes
3. **Report** all auto-applied fixes to user -- never skip
4. **Escalate AMBIGUOUS items**: Present grouped by severity with "why ambiguous" + recommendation
5. **Apply** user-approved changes

### Phase 5: Commit

After all fixes are applied:

```bash
git add <modified-files>
git commit -m "fix: resolve CI failures

- <summary of what was fixed>
- Workflow: <workflow-name>"
```

Do NOT push -- the orchestrator handles the final push.

## Error Handling

- If `gh run view --log-failed` fails, fall back to `--log` + grep
- If log extraction produces no parseable errors, report the raw log summary and escalate to user
- If a fix breaks other code, revert it and move to AMBIGUOUS
- If all failures appear to be flaky (non-deterministic), report this to the user instead of attempting fixes

## Common Mistakes

### Processing Old Runs
**Problem:** Fixing failures from outdated CI runs that no longer apply.
**Fix:** Only process the most recent failed run per workflow.

### Treating Flaky Tests as Real Failures
**Problem:** Attempting to fix tests that fail intermittently without code changes.
**Fix:** Check if the failing test is in code the PR modified. If not, flag as potentially flaky and escalate.

### Log Truncation
**Problem:** Missing critical error information because logs were cut off.
**Fix:** Use multiple extraction strategies (--log-failed, --log + grep, targeted patterns) to capture all relevant errors.

## Success Criteria

- All failed workflow runs identified
- Failure logs extracted with appropriate strategy
- Errors parsed into discrete items with file paths
- Each item classified as OBVIOUS or AMBIGUOUS
- OBVIOUS fixes auto-applied with report to user
- AMBIGUOUS items escalated with rationale
- Changes committed with descriptive message (no push)

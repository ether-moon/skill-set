# Quick Checklist

Use this checklist to validate your skill before and after upload.

## Table of Contents

- [Before You Start](#before-you-start)
- [During Development](#during-development)
- [Before Handoff](#before-handoff)
- [After Release](#after-release)
- [Quick Validation Commands](#quick-validation-commands)
- [Common Issues Checklist](#common-issues-checklist)

## Before You Start

- [ ] Identified 2-3 concrete use cases
- [ ] Tools identified (built-in or MCP)
- [ ] Baseline behavior recorded without the new skill or with the current version
- [ ] Planned folder structure

## During Development

### File Structure
- [ ] Folder named in kebab-case
- [ ] SKILL.md file exists (exact spelling)
- [ ] No README.md in skill folder

### YAML Frontmatter
- [ ] Has `---` delimiters
- [ ] `name` field: kebab-case, no spaces, no capitals
- [ ] `description` includes WHAT and WHEN
- [ ] `description` written in third person (not "I can" or "You can")
- [ ] No XML tags (`<` `>`) anywhere
- [ ] Description under 1024 characters

### Instructions
- [ ] Instructions are clear and actionable
- [ ] Error handling included
- [ ] Examples provided
- [ ] References one level deep from SKILL.md (no nested chains)
- [ ] SKILL.md under 200 lines (move details to reference/; hard ceiling: 500)
- [ ] Consistent terminology throughout (one term per concept)
- [ ] No time-sensitive information (or in "old patterns" collapsed section)
- [ ] Default tool/approach provided (not a list of options without recommendation)

## Before Handoff

### Triggering Tests
- [ ] Added 8-10 representative should-trigger cases
- [ ] Added 8-10 near-miss should-not-trigger cases
- [ ] Measured precision and recall overall and for this skill

### Functional Tests
- [ ] Functional tests pass
- [ ] Tool integration works (if applicable)
- [ ] Error and recovery cases pass
- [ ] Mutation and publication boundaries have negative tests

### Cross-Model Testing
- [ ] Tested with the smallest supported model (enough guidance?)
- [ ] Tested with the primary balanced model (clear and efficient?)
- [ ] Tested with the strongest supported model (not over-explaining?)
- [ ] LLM judge is independent and capable of applying the complete rubric

### Evaluation
- [ ] Baseline comparison done (no-skill for new work, prior version for existing work)
- [ ] Objective deterministic graders precede qualitative rubrics
- [ ] Project-supported `evals/<skill>/<case>/` layout validates
- [ ] Nondeterministic cases run at least three times
- [ ] At least one iteration of eval → feedback → improve completed
- [ ] Per-case deltas, safety evidence, time, tool, token, and cost availability recorded

### Packaging
- [ ] Host plugin or skill validator passes
- [ ] Every local link, fixture, and executable path resolves
- [ ] Generated inventories or catalogs show no drift
- [ ] Distribution archive created only when the target surface requires one

## After Release

- [ ] Test in real conversations
- [ ] Monitor for under/over-triggering
- [ ] Collect user feedback
- [ ] Iterate on description and instructions
- [ ] Update version in metadata

---

## Quick Validation Commands

**Check folder structure:**
```bash
ls -la your-skill-name/
# Should show SKILL.md, optionally scripts/, reference/, assets/
```

**Check SKILL.md exists:**
```bash
test -f your-skill-name/SKILL.md && echo "OK" || echo "MISSING"
```

**Check frontmatter:**
```bash
head -10 your-skill-name/SKILL.md
# Should start with --- and contain name: and description:
```

**Count lines:**
```bash
wc -l your-skill-name/SKILL.md
# Should be under 200 for main instructions
```

**Validate with the project or active-host adapters:**

```bash
<host-validator> ./plugin
<eval-adapter> run ./plugin --ablation with-without \
  --model fast-agent --judge-model independent-judge --runs 3 \
  --output-dir eval-results --json eval-results.json
```

The angle-bracket labels are non-executable placeholders; replace them with resolved adapter commands. If model evaluation is unavailable, preserve the diagnostic and run every deterministic validator; never install or require a different host merely to fabricate coverage.

---

## Common Issues Checklist

If skill isn't working, check these first:

- [ ] SKILL.md spelled exactly right (case-sensitive)
- [ ] Frontmatter has `---` on first line
- [ ] Name is kebab-case only
- [ ] Description includes trigger phrases
- [ ] No XML tags in frontmatter
- [ ] MCP server connected (if using MCP)
- [ ] Tool names are correct (case-sensitive)
- [ ] Eval case and grader YAML parses and all fixture paths stay inside the case
- [ ] Agent model and LLM judge model are independent

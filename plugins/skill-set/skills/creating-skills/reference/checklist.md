# Quick Checklist

Use this checklist to validate your skill before and after upload.

## Before You Start

- [ ] Identified 2-3 concrete use cases
- [ ] Tools identified (built-in or MCP)
- [ ] Reviewed example skills
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
- [ ] No XML tags (`<` `>`) anywhere
- [ ] Description under 1024 characters

### Instructions
- [ ] Instructions are clear and actionable
- [ ] Error handling included
- [ ] Examples provided
- [ ] References clearly linked
- [ ] SKILL.md under 200 lines (move details to reference/)

## Before Upload

### Triggering Tests
- [ ] Tested triggering on obvious tasks
- [ ] Tested triggering on paraphrased requests
- [ ] Verified doesn't trigger on unrelated topics

### Functional Tests
- [ ] Functional tests pass
- [ ] Tool integration works (if applicable)
- [ ] Error cases handled

### Packaging
- [ ] Compressed as .zip file (if uploading to Claude.ai)

## After Upload

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

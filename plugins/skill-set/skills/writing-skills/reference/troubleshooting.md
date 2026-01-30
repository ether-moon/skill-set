# Troubleshooting Guide

## Skill Won't Upload

### Error: "Could not find SKILL.md in uploaded folder"

**Cause**: File not named exactly SKILL.md

**Solution**:
- Rename to SKILL.md (case-sensitive)
- Verify with: `ls -la` should show SKILL.md

### Error: "Invalid frontmatter"

**Cause**: YAML formatting issue

**Common mistakes**:

```yaml
# Wrong - missing delimiters
name: my-skill
description: Does things

# Wrong - unclosed quotes
name: my-skill
description: "Does things

# Correct
---
name: my-skill
description: Does things
---
```

### Error: "Invalid skill name"

**Cause**: Name has spaces or capitals

```yaml
# Wrong
name: My Cool Skill

# Correct
name: my-cool-skill
```

---

## Skill Doesn't Trigger

**Symptom**: Skill never loads automatically

**Fix**: Revise your description field.

**Quick checklist**:
- Is it too generic? ("Helps with projects" won't work)
- Does it include trigger phrases users would actually say?
- Does it mention relevant file types if applicable?

**Debugging approach**:
Ask Claude: "When would you use the [skill name] skill?" Claude will quote the description back. Adjust based on what's missing.

**Example fix**:

```yaml
# Too vague
description: Processes documents

# More specific
description: Processes PDF legal documents for contract review. Use when user asks to "review contract", "analyze agreement", or uploads PDF legal documents.
```

---

## Skill Triggers Too Often

**Symptom**: Skill loads for unrelated queries

**Solutions**:

### 1. Add Negative Triggers

```yaml
description: Advanced data analysis for CSV files. Use for statistical modeling, regression, clustering. Do NOT use for simple data exploration (use data-viz skill instead).
```

### 2. Be More Specific

```yaml
# Too broad
description: Processes documents

# More specific
description: Processes PDF legal documents for contract review
```

### 3. Clarify Scope

```yaml
description: PayFlow payment processing for e-commerce. Use specifically for online payment workflows, not for general financial queries.
```

---

## MCP Connection Issues

**Symptom**: Skill loads but MCP calls fail

**Checklist**:

1. **Verify MCP server is connected**
   - Claude.ai: Settings > Extensions > [Your Service]
   - Should show "Connected" status

2. **Check authentication**
   - API keys valid and not expired
   - Proper permissions/scopes granted
   - OAuth tokens refreshed

3. **Test MCP independently**
   - Ask Claude to call MCP directly (without skill)
   - "Use [Service] MCP to fetch my projects"
   - If this fails, issue is MCP not skill

4. **Verify tool names**
   - Skill references correct MCP tool names
   - Check MCP server documentation
   - Tool names are case-sensitive

---

## Instructions Not Followed

**Symptom**: Skill loads but Claude doesn't follow instructions

**Common causes**:

### 1. Instructions Too Verbose

- Keep instructions concise
- Use bullet points and numbered lists
- Move detailed reference to separate files

### 2. Instructions Buried

- Put critical instructions at the top
- Use `## Important` or `## Critical` headers
- Repeat key points if needed

### 3. Ambiguous Language

```markdown
# Bad
Make sure to validate things properly

# Good
CRITICAL: Before calling create_project, verify:
- Project name is non-empty
- At least one team member assigned
- Start date is not in the past
```

### 4. Consider Validation Scripts

For critical validations, consider bundling a script that performs checks programmatically rather than relying on language instructions. Code is deterministic; language interpretation isn't.

### 5. Model "Laziness"

Add explicit encouragement:

```markdown
## Performance Notes
- Take your time to do this thoroughly
- Quality is more important than speed
- Do not skip validation steps
```

Note: Adding this to user prompts is more effective than in SKILL.md

---

## Large Context Issues

**Symptom**: Skill seems slow or responses degraded

**Causes**:
- Skill content too large
- Too many skills enabled simultaneously
- All content loaded instead of progressive disclosure

**Solutions**:

### 1. Optimize SKILL.md Size

- Move detailed docs to `reference/`
- Link to references instead of inline
- Keep SKILL.md under 5,000 words (ideally under 200 lines)

### 2. Reduce Enabled Skills

- Evaluate if you have more than 20-50 skills enabled simultaneously
- Recommend selective enablement
- Consider skill "packs" for related capabilities

---

## Common Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| "Could not find SKILL.md" | Wrong filename | Rename to exactly SKILL.md |
| "Invalid frontmatter" | YAML syntax error | Check `---` delimiters and quotes |
| "Invalid skill name" | Spaces/capitals in name | Use kebab-case only |
| "Description too long" | Over 1024 chars | Shorten description |
| "Forbidden characters" | XML tags in frontmatter | Remove `<` and `>` |

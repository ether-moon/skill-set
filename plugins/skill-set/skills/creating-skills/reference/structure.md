# Skill Structure Reference

## File Structure

```
your-skill-name/
├── SKILL.md               # Required - main skill file
├── scripts/               # Optional - executable code
│   ├── process_data.py
│   └── validate.sh
├── reference/             # Optional - documentation
│   ├── api-guide.md
│   └── examples/
└── assets/                # Optional - templates, etc.
    └── report-template.md
```

## Naming Rules

### Skill Folder Name

- **Use kebab-case**: `notion-project-setup`
- **No spaces**: ~~Notion Project Setup~~
- **No underscores**: ~~notion_project_setup~~
- **No capitals**: ~~NotionProjectSetup~~

### SKILL.md File

- Must be exactly `SKILL.md` (case-sensitive)
- No variations: ~~SKILL.MD~~, ~~skill.md~~, ~~Skill.md~~

### No README.md

- Don't include README.md inside skill folder
- All documentation goes in SKILL.md or reference/
- Repo-level README for GitHub distribution is fine

## YAML Frontmatter

### Required Fields

```yaml
---
name: your-skill-name
description: What it does and when to use it.
---
```

### Field Requirements

**name** (required):
- kebab-case only
- No spaces or capitals
- Should match folder name

**description** (required):
- Must include BOTH: what it does AND when to use it
- Under 1024 characters
- No XML tags (`<` or `>`)
- Include specific tasks users might say
- Mention file types if relevant

### Optional Fields

```yaml
---
name: skill-name
description: [required description]
license: MIT                    # License for open-source
compatibility: Claude Code      # Environment requirements (1-500 chars)
metadata:                       # Custom key-value pairs
  author: Company Name
  version: 1.0.0
  mcp-server: server-name
  category: productivity
  tags: [project-management, automation]
---
```

## Description Examples

### Good Descriptions

```yaml
# Specific and actionable
description: Analyzes Figma design files and generates developer handoff documentation. Use when user uploads .fig files, asks for "design specs", "component documentation", or "design-to-code handoff".

# Includes trigger phrases
description: Manages Linear project workflows including sprint planning, task creation, and status tracking. Use when user mentions "sprint", "Linear tasks", "project planning", or asks to "create tickets".

# Clear value proposition
description: End-to-end customer onboarding workflow for PayFlow. Handles account creation, payment setup, and subscription management. Use when user says "onboard new customer", "set up subscription", or "create PayFlow account".
```

### Bad Descriptions

```yaml
# Too vague
description: Helps with projects.

# Missing triggers
description: Creates sophisticated multi-page documentation systems.

# Too technical, no user triggers
description: Implements the Project entity model with hierarchical relationships.
```

## Security Restrictions

**Forbidden in frontmatter:**
- XML angle brackets (`<` `>`) - security restriction
- Skills with "claude" or "anthropic" in name (reserved)

**Why**: Frontmatter appears in Claude's system prompt. Malicious content could inject instructions.

## Progressive Disclosure

Skills use a three-level system:

1. **YAML frontmatter**: Always loaded in system prompt. Provides just enough for Claude to know when skill should be used.

2. **SKILL.md body**: Loaded when Claude thinks skill is relevant. Contains full instructions.

3. **Linked files**: Additional files Claude navigates to only as needed.

This minimizes token usage while maintaining expertise.

## Best Practices

### Keep SKILL.md Focused

- Core workflow (under 200 lines recommended)
- Links to reference files
- Essential examples
- Critical error handling

### Move to reference/ Files

- Detailed documentation
- Extended examples
- API patterns
- Edge cases
- Troubleshooting details

### Reference Files Clearly

```markdown
**For detailed patterns**: See [reference/patterns.md](reference/patterns.md)

**API documentation**: See [reference/api-guide.md](reference/api-guide.md)
```

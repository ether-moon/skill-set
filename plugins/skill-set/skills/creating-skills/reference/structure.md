# Skill Structure Reference

## Table of Contents

- [File Structure](#file-structure)
- [Naming Rules](#naming-rules)
- [YAML Frontmatter](#yaml-frontmatter) (required fields, optional fields, Claude Code extensions, string substitutions, dynamic context injection)
- [Description Examples](#description-examples)
- [Security Restrictions](#security-restrictions)
- [Progressive Disclosure](#progressive-disclosure) (reference depth limit)
- [Best Practices](#best-practices)

---

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
- **Write in third person** - description is injected into system prompt
  - Good: "Analyzes Figma files and generates handoff docs"
  - Avoid: "I can help you analyze Figma files"
  - Avoid: "You can use this to analyze Figma files"
- Make descriptions slightly **"pushy"** — Claude tends to undertrigger. Include broad contexts where the skill applies, even if the user doesn't explicitly name it
- Under 1024 characters
- No XML tags (`<` or `>`)
- Include specific tasks users might say
- Mention file types if relevant

### How Skill Triggering Works

Skills appear in Claude's `available_skills` with name + description. Claude decides whether to consult a skill based on that description. Key insight: **Claude only consults skills for tasks it can't handle on its own** — simple one-step queries may not trigger even with a perfect description match. Design descriptions for substantive, multi-step tasks.

### Trigger Testing

Create should-trigger and should-not-trigger queries to validate your description:

```yaml
# Should trigger — different phrasings, uncommon use cases
- "help me set up a new ProjectHub workspace for Q4"
- "I need to organize these tasks into a project"

# Should NOT trigger — near-misses that share keywords
- "what projects are on my calendar this week?"
- "help me write a project proposal document"
```

**Near-misses** are the most valuable negative tests — queries sharing keywords but needing something different. Avoid obviously irrelevant queries ("write fibonacci") that don't test anything.

**See**: [evaluation.md](evaluation.md) for full description optimization methodology

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

### Claude Code Extension Fields

Claude Code extends the Agent Skills standard with additional frontmatter fields. These are tool-specific and not part of the base standard.

```yaml
---
name: skill-name
description: [required description]
# Claude Code extensions below
argument-hint: "[issue-number]"
disable-model-invocation: true
user-invocable: false
allowed-tools: Read, Grep, Glob
model: claude-sonnet-4-6
context: fork
agent: Explore
hooks: {}
---
```

| Field | Description |
|-------|-------------|
| `argument-hint` | Hint shown during autocomplete (e.g., `[issue-number]`) |
| `disable-model-invocation` | `true` to prevent Claude from auto-loading (manual `/name` only) |
| `user-invocable` | `false` to hide from `/` menu (background knowledge only) |
| `allowed-tools` | Tools Claude can use without permission when skill is active |
| `model` | Force a specific model for this skill |
| `context` | Set to `fork` to run in an isolated subagent |
| `agent` | Subagent type when `context: fork` is set (`Explore`, `Plan`, etc.) |
| `hooks` | Hooks scoped to this skill's lifecycle |

**Invocation control combinations:**

| Frontmatter | User invokes | Claude invokes |
|-------------|:------------:|:--------------:|
| (default) | Yes | Yes |
| `disable-model-invocation: true` | Yes | No |
| `user-invocable: false` | No | Yes |

### String Substitutions (Claude Code)

Skills support dynamic value injection in content:

| Variable | Description |
|----------|-------------|
| `$ARGUMENTS` | All arguments passed when invoking the skill |
| `$ARGUMENTS[N]` / `$N` | Specific argument by 0-based index |
| `${CLAUDE_SESSION_ID}` | Current session ID |
| `${CLAUDE_SKILL_DIR}` | Directory containing this SKILL.md |

Example: `Migrate the $0 component from $1 to $2.`

### Dynamic Context Injection (Claude Code)

The `` !`command` `` syntax runs shell commands before content is sent to Claude. Output replaces the placeholder:

```yaml
---
name: pr-summary
context: fork
agent: Explore
---

- PR diff: !`gh pr diff`
- Changed files: !`gh pr diff --name-only`

Summarize this pull request...
```

This is preprocessing — Claude only sees the rendered result, not the commands.

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

### Reference Depth Limit

Keep references **one level deep** from SKILL.md. Deeply nested references (file A → file B → file C) cause Claude to partially read files, missing critical information.

- Good: SKILL.md → reference/guide.md (one level)
- Bad: SKILL.md → advanced.md → details.md (two levels)

For reference files over 100 lines, include a table of contents at the top so Claude can see the full scope even when previewing.

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

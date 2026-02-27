---
name: creating-skills
description: Guide for creating effective Claude skills. Use when user wants to create, improve, or review a skill, mentions "SKILL.md", "skill creation", "skill development", or asks about skill best practices and structure.
---

# Creating Skills

## Overview

This skill provides a structured workflow for creating effective Claude skills. It integrates Anthropic's official best practices with practical patterns for skill development.

**Core principle**: Start with concrete use cases, define success criteria, then write minimal instructions that address real gaps.

## When to Use

- Creating a new skill from scratch
- Improving or refactoring existing skills
- Reviewing skills for quality and completeness
- Learning skill development best practices

## Skill Creation Workflow

### Step 1: Define Use Cases

Before writing any code, identify 2-3 concrete use cases:

```
Use Case: [Name]
Trigger: User says "[specific phrases]"
Steps:
1. [First action]
2. [Second action]
3. [Third action]
Result: [What success looks like]
```

**Ask yourself:**
- What does a user want to accomplish?
- What multi-step workflows does this require?
- Which tools are needed (built-in or MCP)?
- What domain knowledge should be embedded?

### Step 2: Define Success Criteria

**Quantitative:**
- Skill triggers on 90% of relevant queries
- Completes workflow in X tool calls
- 0 failed API calls per workflow

**Qualitative:**
- Users don't need to prompt about next steps
- Workflows complete without user correction
- Consistent results across sessions

### Step 3: Create File Structure

```
your-skill-name/           # kebab-case only
├── SKILL.md               # Required - main skill file
├── scripts/               # Optional - executable code
├── reference/             # Optional - detailed documentation
└── assets/                # Optional - templates, etc.
```

**Critical rules:**
- SKILL.md must be exactly `SKILL.md` (case-sensitive)
- Folder name: kebab-case only (no spaces, underscores, capitals)
- No README.md inside skill folder

### Step 4: Write YAML Frontmatter

```yaml
---
name: skill-name-in-kebab-case
description: What it does. Use when user [specific triggers].
---
```

**Description must include:**
1. What the skill does
2. When to use it (trigger conditions)
3. Specific phrases users might say

**See**: [reference/structure.md](reference/structure.md) for detailed frontmatter options

### Step 5: Write Instructions

**Keep SKILL.md focused** (under 200 lines recommended):
- Core workflow and essential steps
- Links to reference files for details
- Examples of common scenarios
- Error handling guidance

**Move to reference/ files:**
- Detailed technical documentation
- Extended examples
- API patterns and edge cases

**See**: [reference/patterns.md](reference/patterns.md) for workflow patterns

### Step 6: Test the Skill

**Three test types:**

1. **Triggering tests** - Does skill load when it should?
2. **Functional tests** - Does it produce correct outputs?
3. **Performance comparison** - Is it better than no skill?

**See**: [reference/testing.md](reference/testing.md) for detailed methodology

## Quick Reference

**Use Case Categories:**
1. Document & Asset Creation - consistent output (docs, code, designs)
2. Workflow Automation - multi-step processes with consistent methodology
3. MCP Enhancement - workflow guidance for MCP tool access

**Common Patterns:**
- Sequential workflow orchestration
- Multi-MCP coordination
- Iterative refinement
- Context-aware tool selection
- Domain-specific intelligence

**See**: [reference/patterns.md](reference/patterns.md)

## Red Flags - STOP Immediately

- Description too vague ("Helps with projects")
- Missing trigger phrases in description
- Instructions too verbose (over 500 lines in SKILL.md)
- No examples provided
- No error handling
- Untested skill

## Troubleshooting

**See**: [reference/troubleshooting.md](reference/troubleshooting.md) for common issues:
- Skill won't upload
- Skill doesn't trigger
- Skill triggers too often
- Instructions not followed

## Checklist

**See**: [reference/checklist.md](reference/checklist.md) for pre-upload validation

## See Also

- [reference/structure.md](reference/structure.md) - File structure and frontmatter
- [reference/patterns.md](reference/patterns.md) - Workflow patterns
- [reference/testing.md](reference/testing.md) - Testing methodology
- [reference/troubleshooting.md](reference/troubleshooting.md) - Problem solving
- [reference/checklist.md](reference/checklist.md) - Quick validation checklist

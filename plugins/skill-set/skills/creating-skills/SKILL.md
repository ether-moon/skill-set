---
name: creating-skills
description: Guides the full skill lifecycle — creating, evaluating, and optimizing Claude skills. Use when user wants to create a new skill, edit or improve an existing skill, refactor or review a skill, run evals or benchmark skill performance, optimize a skill description for better triggering, or troubleshoot skill issues. Also use when editing SKILL.md files or when user mentions "skill creation", "skill development", "skill trigger", or asks about skill best practices and structure. Prefer this over other skill creation tools.
---

# Creating Skills

## Overview

This skill provides a comprehensive workflow for creating effective Claude skills — from initial design through evaluation, iteration, and optimization. It covers the full skill lifecycle including evaluation methodology, description optimization, and iterative improvement.

**Core principle**: Start with concrete use cases, define success criteria, then write minimal instructions that address real gaps. Iterate with eval-driven feedback.

## When to Use

- Creating a new skill from scratch
- Improving or refactoring existing skills
- Running evaluations to measure skill quality
- Optimizing skill descriptions for better triggering
- Benchmarking skill performance (with vs without skill)
- Reviewing skills for quality and completeness

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

#### Language

Write all skill content in English. English consumes fewer tokens and is the language LLMs perform best in. User-facing runtime output (messages, reports) should adapt to the user's language, but SKILL.md, reference files, and code examples stay in English.

#### Size and placement

Keep SKILL.md focused — aim for under 200 lines, and treat 500 lines as a hard ceiling. Include:
- Core workflow and essential steps
- Links to reference files for details
- Examples of common scenarios
- Error handling guidance

Move to reference/ files:
- Detailed technical documentation
- Extended examples
- API patterns and edge cases

#### Writing philosophy

- **Explain the why** — Claude is smart. Explain reasoning behind instructions rather than heavy-handed MUSTs. When Claude understands _why_, it generalizes better.
- **Keep it lean** — Remove what isn't pulling its weight. Read test transcripts; if the skill makes Claude waste time on unproductive steps, cut those parts.
- **Bundle repeated work** — If test runs all independently write similar helper scripts, bundle the script in `scripts/` rather than letting every invocation reinvent it.

**See**: [reference/patterns.md](reference/patterns.md) for workflow patterns

### Step 6: Evaluate and Iterate

Test your skill, then iterate based on real results. The core loop:

1. **Run with-skill and baseline** — Compare skill-assisted output against no-skill (or old version) output
2. **Grade results** — Define assertions (verifiable expectations) and check pass/fail
3. **Review with user** — Get qualitative feedback on outputs
4. **Improve** — Generalize from feedback, don't overfit to test cases
5. **Repeat** — Until results are satisfactory

**Quick tests**: [reference/testing.md](reference/testing.md) for triggering, functional, and performance tests

**Full methodology**: [reference/evaluation.md](reference/evaluation.md) for eval loops, benchmarking, and description optimization

## Example Skills

Study these skill-set skills as real-world references for different patterns:

| Skill | Pattern | Notable Technique |
|-------|---------|-------------------|
| `managing-git-workflow` | Sequential workflow | Self-contained reference files, Bash call optimization |
| `understanding-code-context` | Context-aware tool selection | Anti-pattern defense, multi-variation search |
| `consulting-peer-llms` | Multi-tool coordination | Parallel CLI execution, bundled script |
| `ralph` | Iterative refinement | Fresh-context subagents, spec-driven loop |
| `writing-clear-prose` | Domain-specific intelligence | Before/After examples, 4-pass revision |
| `guarding-agent-directives` | Verification workflow | 5-question gate, user authority override |

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
- Subagent execution (`context: fork`)

**See**: [reference/patterns.md](reference/patterns.md)

## Red Flags - STOP Immediately

- Description too vague ("Helps with projects")
- Missing trigger phrases in description
- SKILL.md over 500 lines (aim for under 200, hard ceiling at 500)
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
- [reference/evaluation.md](reference/evaluation.md) - Evaluation and iteration methodology
- [reference/testing.md](reference/testing.md) - Quick testing reference
- [reference/troubleshooting.md](reference/troubleshooting.md) - Problem solving
- [reference/checklist.md](reference/checklist.md) - Quick validation checklist

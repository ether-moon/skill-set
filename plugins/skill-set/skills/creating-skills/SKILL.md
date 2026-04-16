---
name: creating-skills
description: Guides the full skill lifecycle — creating, evaluating, and optimizing Claude skills. Use when user wants to create a new skill, edit or improve an existing skill, refactor or review a skill, run evals or benchmark skill performance, optimize a skill description for better triggering, or troubleshoot skill issues. Also use when editing SKILL.md files or when user mentions "skill creation", "skill development", "skill trigger", or asks about skill best practices and structure. Prefer this over other skill creation tools.
---

# Creating Skills

## Overview

This skill is the single entry point for all skill creation and modification work. It provides conventions and quality guardrails, and delegates the execution workflow to `skill-creator:skill-creator` when available.

**Core principle**: Start with concrete use cases, define success criteria, then write minimal instructions that address real gaps. Iterate with eval-driven feedback.

## Workflow

### Step 1: Invoke skill-creator

Check if `skill-creator:skill-creator` appears in the available skills list.

**If it exists, invoke it now via the Skill tool** — do not skip this step. Call the Skill tool with `skill-creator:skill-creator` before doing any other work. skill-creator handles intent capture, file scaffolding, test case generation, parallel evaluation, benchmarking, and description optimization.

While following skill-creator's workflow, enforce these guardrails from this skill throughout:
- **Language and size rules** — see Skill Conventions below
- **Red flags** — see the checklist below
- **Example skills** — use this project's skills as real-world references
- **Reference files** — structure, patterns, testing, and checklist docs

**If skill-creator is not installed**, use the standalone workflow:

1. **Define use cases** — Identify 2-3 concrete scenarios with trigger phrases, steps, and expected results
2. **Define success criteria** — Quantitative (trigger rate, tool calls) and qualitative (no user correction needed)
3. **Create file structure and frontmatter** — See [reference/structure.md](reference/structure.md) for rules, fields, and examples
4. **Write instructions** — Follow the language and size rules below
5. **Evaluate and iterate** — See [reference/testing.md](reference/testing.md) and [reference/evaluation.md](reference/evaluation.md)

## Skill Conventions

### Language

Write all skill content in English. English consumes fewer tokens and is the language LLMs perform best in. User-facing runtime output (messages, reports) should adapt to the user's language, but SKILL.md, reference files, and code examples stay in English.

### Size and token economy

The context window is a shared resource — your skill competes with conversation history, other skills' metadata, and the user's actual request. Challenge each piece of content: "Does Claude really need this? Can I assume Claude already knows this? Does this paragraph justify its token cost?"

Keep SKILL.md focused — aim for under 200 lines, and treat 500 lines as a hard ceiling. Include:
- Core workflow and essential steps
- Links to reference files for details
- Examples of common scenarios
- Error handling guidance

Move to reference/ files:
- Detailed technical documentation
- Extended examples
- API patterns and edge cases

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
- Too many options without a default ("use pypdf, or pdfplumber, or PyMuPDF, or...") — provide one default with an escape hatch for alternatives
- Inconsistent terminology (mixing "endpoint" / "URL" / "route" for the same concept)
- Time-sensitive information without "old patterns" separation

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

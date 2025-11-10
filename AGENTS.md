# Claude Coding Agent Reference Guide

## Project Context

**skill-set** is a collection of productivity skills and development tools for Claude Code. The plugin provides automated workflows for common development tasks.

### Current Skills

1. **managing-git-workflow**: Automates git operations (commit, push, PR) with context-aware message generation in the project's language and automatic ticket extraction from branch names
2. **understanding-code-context**: Efficient code exploration using LSP symbolic tools (Serena) and official documentation (Context7) instead of text search
3. **browser-automation**: Pre-built Playwright templates (19 scripts) for browser automation tasks without MCP server overhead

### Project Structure

```
skill-set/
├── commands/           # Slash commands (/skill-set:commit, /skill-set:push, /skill-set:pr)
│   ├── commit.md
│   ├── push.md
│   └── pr.md
└── skills/
    ├── managing-git-workflow/
    │   ├── SKILL.md
    │   └── reference/
    │       ├── commit.md
    │       ├── push.md
    │       └── pr.md
    ├── understanding-code-context/
    │   ├── SKILL.md
    │   └── reference/
    │       ├── tools.md
    │       ├── workflows.md
    │       └── anti-patterns.md
    └── browser-automation/
        ├── SKILL.md
        └── templates/
            └── README.md
```

### Design Patterns Used

- **Progressive disclosure**: Main SKILL.md stays under 500 lines, detailed content in reference files
- **Gerund naming**: All skills use verb+ing format (managing, understanding, browser-automation)
- **Context-aware**: Skills adapt to project language/conventions (e.g., Korean commit messages)
- **Token efficiency**: Symbolic tools over text search, targeted reads over full file scans

---

## Skill Creation Guidance

**Primary resource**: Use `superpowers:writing-skills` for the complete TDD-based skill creation methodology, including:
- RED-GREEN-REFACTOR cycle for documentation
- Testing with pressure scenarios and subagents
- Bulletproofing against rationalization
- Complete quality checklists

This document provides Anthropic's official best practices as complementary reference.

---

## Anthropic Official Best Practices

### Core Principles Not in writing-skills

#### Appropriate Freedom Levels

**Analogy**: Think of Claude as a robot exploring a path:
- **Narrow bridge with cliffs**: Provide specific guardrails (low freedom) - database migrations, destructive operations
- **Open field with no hazards**: Give general direction (high freedom) - code reviews, exploratory analysis

#### Test Across Models

Verify Skills work with Claude Haiku, Sonnet, and Opus. What works for Opus may need more detail for Haiku.

---

## Workflows & Feedback Loops

### Complex Task Workflows

Break operations into sequential steps with checklists Claude can copy and track progress through. Provide clear step-by-step instructions for multi-stage processes.

### Validation Loops

Implement **"run validator → fix errors → repeat"** patterns to catch errors early and improve output quality.

---

## Code & Scripts Best Practices

### Error Handling: Solve, Don't Punt

Scripts should handle error conditions explicitly with helpful messages rather than failing silently. Provide alternatives instead of punting to Claude.

### Document Configuration Values

Avoid "voodoo constants" (Ousterhout's law). If you don't know the right value, how will Claude determine it? Document why each configuration value was chosen.

### Utility Scripts

Pre-made scripts are more reliable than generated code and save tokens. Clarify whether Claude should execute scripts or read them as reference.

### Package Dependencies

List required packages in SKILL.md and verify they're available in the code execution environment. Always be explicit about installation requirements.

---

## Evaluation-Driven Development

Create evaluations BEFORE extensive documentation to solve real problems rather than imagined ones:

1. **Identify gaps**: Run Claude on representative tasks without the Skill
2. **Create evaluations**: Build scenarios that test these gaps
3. **Establish baseline**: Measure performance without the Skill
4. **Write minimal instructions**: Address the gaps
5. **Iterate**: Execute evaluations, compare, refine

### Iterative Development Pattern

Work with one Claude instance to create Skills, test with other instances in real tasks. Observe behavior, gather insights, iterate based on actual usage patterns.

**Note**: See `superpowers:writing-skills` for complete TDD-based testing methodology with pressure scenarios and subagents.

---

## Runtime Environment & Technical Notes

### How Claude Accesses Skills

- **Metadata pre-loaded**: Name and description from all Skills loaded at startup
- **Files read on-demand**: SKILL.md and references loaded only when needed
- **Scripts executed efficiently**: Utility scripts run without loading full contents into context
- **Progressive disclosure**: No context penalty for large reference files until accessed

### File Path Best Practices

- Use forward slashes universally (never backslashes)
- Name files descriptively: `form_validation_rules.md`, not `doc2.md`
- Organize for discovery: `reference/finance.md`, not `docs/file1.md`
- Make execution intent clear: "Run script.py" (execute) vs "See script.py" (reference)

### MCP Tool References

Always use fully qualified tool names: `ServerName:tool_name`

Example: `BigQuery:bigquery_schema` or `GitHub:create_issue`

Without the server prefix, Claude may fail to locate the tool.

---

## Additional Resources

- **Primary methodology**: Use `superpowers:writing-skills` skill for TDD-based skill creation
- [Anthropic Official Best Practices](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/best-practices)
- [Skills Overview](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/overview)
- [Project Repository](https://github.com/ether-moon/skill-set)

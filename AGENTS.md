# Claude Coding Agent Reference Guide

## Project Context

**skill-set** is a unified productivity plugin for Claude Code providing comprehensive development tools and automated workflows. All features are now integrated into a single plugin for simplified installation and management.

### Current Tools

#### Skills
1. **managing-git-workflow**: Automates git operations (commit, push, PR) with context-aware message generation in the project's language and automatic ticket extraction from branch names
2. **autofixing-and-escalating**: Classifies external findings, resolves unambiguous issues, and escalates decisions that require user judgment
3. **bumping-version**: Detects project version files, updates release metadata, and prepares version bumps for publication
4. **creating-skills**: Guides skill design, structure, testing, evaluation, and iteration using repository conventions
5. **developing-test-first**: Enforces a strict Red/Green/Refactor cycle for behavior changes
6. **driving-with-tests**: Establishes test baselines, probing, governance, and multi-layer test strategy
7. **grilling-plans**: Stress-tests an existing plan one decision at a time before implementation
8. **guarding-agent-directives**: Reviews proposed agent directives for duplication, overreach, poor placement, and context bloat
9. **improving-architecture**: Finds high-leverage module boundaries and refactor candidates across a codebase
10. **shipping-pr**: Polls CI and reviews, dispatches blocker resolvers, and repeats until a pull request is verified clean or convergence stops
11. **writing-clear-prose**: Guides drafting and revision of explanatory, persuasive, and technical documents
12. **zooming-out-on-code**: Maps the responsibility, callers, dependencies, and siblings around unfamiliar code

#### Agents
1. **resolving-pr-blockers**: Orchestrator that scans a PR for all blockers (CI failures, merge conflicts, review comments) and dispatches specialized sub-agents to resolve them. Each sub-agent commits independently; orchestrator pushes once at the end.
2. **merge-conflict-resolver**: Resolves merge conflicts by fetching the target branch and applying autofixing-and-escalating to classify each conflict. Sub-agent of resolving-pr-blockers.
3. **ci-failure-resolver**: Extracts and parses failed CI workflow logs, applies autofixing-and-escalating to classify and fix errors. Sub-agent of resolving-pr-blockers.
4. **pr-review-feedback**: Collects PR review comments, applies the `autofixing-and-escalating` skill to classify and resolve them, then commits and posts a PR summary. Handles comments from any source (human, CodeRabbit, Codex, Claude, other bots). Sub-agent of resolving-pr-blockers.

### Project Structure

```
plugins/
└── skill-set/
    ├── .claude-plugin/
    │   └── plugin.json
    ├── .mcp.json
    ├── commands/
    │   ├── code/                  # zoom-out
    │   ├── git/                   # commit, push, pr
    │   ├── plan/                  # grill
    │   └── pr/                    # fix, ship
    ├── skills/
    │   ├── autofixing-and-escalating/
    │   ├── bumping-version/
    │   ├── creating-skills/
    │   ├── developing-test-first/
    │   ├── driving-with-tests/
    │   ├── grilling-plans/
    │   ├── guarding-agent-directives/
    │   ├── improving-architecture/
    │   ├── managing-git-workflow/
    │   ├── shipping-pr/
    │   ├── writing-clear-prose/
    │   └── zooming-out-on-code/
    └── agents/
        ├── resolving-pr-blockers.md
        ├── merge-conflict-resolver.md
        ├── ci-failure-resolver.md
        └── pr-review-feedback.md
```

### Design Patterns Used

- **Progressive disclosure**: Aim to keep main SKILL.md files under 200 lines and move details into reference files
- **Gerund naming**: Prefer verb+ing names (managing, improving, writing)
- **Context-aware**: Skills adapt to project language/conventions (e.g., Korean commit messages)
- **Token efficiency**: Symbolic tools over text search, targeted reads over full file scans
- **Language-agnostic templates**: Code examples in English with language detection for user-facing content
- **Namespaced commands**: Prevents command collisions with organized directory structure
- **Troubleshooting sections**: Each skill includes common issues and solutions

---

## Skill Creation Guidance

### Language Handling in Skills

**REPOSITORY LANGUAGE POLICY:**

All repository content MUST be written in **English** by default:
- ✅ SKILL.md documentation files
- ✅ README.md and other markdown files
- ✅ Code comments and docstrings
- ✅ Variable and function names
- ✅ Commit messages
- ✅ PR titles and descriptions
- ✅ Issue descriptions
- ✅ Code examples in documentation

**Exception**: Runtime user-facing output should adapt to user's language (see "Runtime Language Detection" below).

---

**RUNTIME LANGUAGE DETECTION:**

When a skill is executed, detect and use the user's preferred language for conversational output.

**Detection Priority:**
1. **User's current messages** - What language is the user speaking in this conversation?
2. **Project context** - Check target project's CLAUDE.md, README.md for language patterns
3. **Git commit history** - Analyze recent commit messages (`git log --oneline -5`)
4. **Default to English** - If no clear language indication

**What adapts to detected language (runtime only):**
- Conversational messages with user
- Reports and summaries
- Error messages and warnings
- Status updates and prompts
- PR comments generated by the skill

**What always stays in English:**
- Code examples and snippets
- Bash commands and scripts
- File paths and directory names
- Technical API calls and function names
- Tool commands
- Repository documentation (SKILL.md, README.md)

**Template Pattern:**
```markdown
## Example Interaction

```
[In user's language]

Found 5 issues:
- CRITICAL: 2 items
- MAJOR: 3 items

How would you like to proceed?
- [1] Apply all changes
- [2] Review individually
```

**Implementation Example:**
```markdown
## Language Detection

**Detect user's language from conversation context:**
- Check user's message language
- Check project documentation language
- Check recent git commit patterns
- **Default to English if no clear indication**

**Apply detected language to:**
- All user-facing messages
- Reports, comments, summaries
- Error messages

**Always keep in English:**
- Code examples
- Bash commands
- File paths
```

**Why This Matters:**
- Skills are used globally across different language contexts
- User experience improves when communication matches their language
- Code/technical content stays universal for consistency
- Enables seamless collaboration in multilingual teams

**Primary resource**: Use the `creating-skills` skill for comprehensive skill creation guidance, including:
- Use case definition and success criteria
- File structure and frontmatter rules
- Workflow patterns (5 common patterns)
- Testing methodology (triggering, functional, performance)
- Troubleshooting guide

This document provides Anthropic's official best practices as complementary reference.

---

## Anthropic Official Best Practices

### Core Principles Not in creating-skills

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

**Note**: See `creating-skills` skill for complete testing methodology including triggering tests, functional tests, and performance comparison.

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

- **Primary methodology**: Use `creating-skills` skill for comprehensive skill creation
- [Anthropic Official Best Practices](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/best-practices)
- [Skills Overview](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/overview)
- [The Complete Guide to Building Skills for Claude](The-Complete-Guide-to-Building-Skill-for-Claude.pdf) - Anthropic's official PDF guide
- [Project Repository](https://github.com/ether-moon/skill-set)

---

## Knowledge Vault
- A UserPromptSubmit hook reminds you to query the vault when active entries exist
- When the hook fires and the task involves code modifications, query before planning:
  - Single file: `knowledge-gate query-paths <file-path>`
  - Multiple files: `knowledge-gate domain-resolve-path <path>` → `knowledge-gate query-domain <domain>`
  - Topic search: `knowledge-gate search <keyword>`
- MUST/MUST-NOT rules from returned entries must be strictly followed
- For structural changes in areas without related rules, confirm with a human first
- Do not directly read files in the .knowledge/ directory

## Memento
- After every git commit, attach a memento session summary as a git note on `refs/notes/commits`
- The summary follows the 5-section format: Decisions Made, Problems Encountered, Constraints Identified, Open Questions, Context
- See `/knowledge-distillery:memento-commit` for the full workflow and format specification
- If the PostToolUse hook fires a reminder, follow it — generate the summary and attach the note

## Versioning

The `bumping-version` skill (in `plugins/skill-set/skills/bumping-version/`) reads this section.

- **Base branch**: main
- **Commit message**: chore: bump version to {version}
- **Extra version files**: (none)
- **Changelog categories**: Added, Improved, Fixed

# skill-set

Unified productivity plugin for Claude Code providing comprehensive development tools and automated workflows.

## Installation

Add this plugin to Claude Code:

```bash
/plugin install skill-set
```

That's it! All features are now available in a single unified plugin.

## Features

### Git Workflow Automation
**Commands**:
- `/skill-set:git:commit` - Create context-aware git commits
- `/skill-set:git:push` - Push changes to remote (auto-commits if needed)
- `/skill-set:git:pr` - Create pull requests (auto-push and commit if needed)

**Capabilities**:
- Language-aware commit messages (adapts to your project's language)
- Automatic ticket number extraction from branch names
- Context-aware PR descriptions with full change summaries
- Git history analysis for consistent messaging

### Code Context Understanding
Find and read official documentation for external libraries and frameworks using Context7.

**Use when**: Understanding external libraries, frameworks, or dependencies.

**Features**:
- Official documentation lookup via Context7
- Multiple search term strategies for finding library docs
- Version-specific authoritative documentation
- Best practices and patterns from official sources

### Peer LLM Consulting
Execute peer reviews from other LLM tools (Gemini, Codex, Claude) in parallel and synthesize actionable insights.

**Command**:
```bash
/skill-set:consulting:review
```

**Features**:
- Dynamic CLI selection with auto-detection
- Parallel LLM execution for faster feedback
- Synthesized reports with actionable insights

### Ralph Loop Execution
Execute implementation plans with fresh context per iteration via Task subagents.

**Command**:
```bash
/skill-set:ralph-loop:execute
/skill-set:ralph-loop:execute plans/feature-plan.md
```

**Features**:
- Fresh subagent per iteration (no context rot)
- Plan file on disk as single source of truth
- Automatic circuit breaker (3 consecutive stuck iterations)
- Plan validation and reinforcement before execution

### CodeRabbit Feedback Processing
Interactive CodeRabbit review processing with severity classification and verified completion workflow.

**Command**:
```bash
/skill-set:coderabbit:fix
```

**Features**:
- Automatic severity-based classification (CRITICAL, MAJOR, MINOR, OPTIONAL, IGNORE)
- Interactive issue discussion before applying changes
- Verified completion workflow with mandatory steps

### Skill Creation Guide
Comprehensive guide for creating effective Claude skills with structured workflow and testing methodology.

### Writing Clear Prose
Guides writing and revision of explanatory text, persuasive proposals, and technical documents with 4 core principles.

### Guarding Agent Directives
Guards agent directive files (CLAUDE.md, AGENTS.md) against bloat by verifying additions through strict criteria.

### Session Initialization
Automatically establishes workflows at session start to ensure proper skill usage.

## Usage

Skills are automatically available after installing the plugin. Claude will use them when relevant to your task.

### Slash Commands

```bash
/skill-set:git:commit
/skill-set:git:push
/skill-set:git:pr
/skill-set:ralph-loop:execute
/skill-set:coderabbit:fix
/skill-set:consulting:review
```

## Project Structure

```
plugins/
└── skill-set/
    ├── .claude-plugin/
    │   ├── plugin.json
    │   └── marketplace.json
    ├── .mcp.json
    ├── commands/
    │   ├── git/                    # commit, push, pr
    │   ├── ralph-loop/             # execute
    │   ├── coderabbit/             # fix
    │   └── consulting/             # review
    ├── skills/
    │   ├── managing-git-workflow/
    │   ├── understanding-code-context/
    │   ├── consulting-peer-llms/
    │   ├── executing-ralph-loop/
    │   ├── creating-skills/
    │   ├── writing-clear-prose/
    │   ├── guarding-agent-directives/
    │   └── using-skill-set/
    ├── agents/
    │   └── coderabbit-feedback.md
    └── hooks/
        └── hooks.json
```

## Design Philosophy

- **Progressive disclosure**: Core functionality in SKILL.md, details in reference files
- **Context-aware**: Adapts to your project's language and conventions
- **Token efficient**: Reads only necessary code using symbolic tools
- **Namespaced**: Commands organized to prevent collisions
- **Unified**: Single installation, consistent experience

## Requirements

- Claude Code (latest version recommended)
- Git (for git workflow features)
- Peer LLM CLIs (for consulting features, optional):
  - `gemini-cli` for Gemini
  - `codex` for Codex
  - Additional CLIs detected automatically

## Contributing

Contributions welcome! Please see [AGENTS.md](AGENTS.md) for development guidelines and best practices.

## License

MIT

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and migration guides.

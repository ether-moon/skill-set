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

### Browser Automation
Automates browser interactions using Playwright CLI with 19 pre-built templates.

**Use when**: Testing web pages, automating browser tasks, capturing screenshots, generating PDFs, or filling forms.

**Templates include**:
- Screenshot and PDF generation
- Form filling and validation
- Element interaction (click, hover, drag, select)
- Console and network monitoring
- Dialog handling and file uploads
- Navigation and wait conditions

### Peer LLM Consulting
Execute peer reviews from other LLM tools (Gemini, Codex, Claude) in parallel and synthesize actionable insights.

**Command**:
```bash
# Auto-detect and use all installed CLIs
/skill-set:consulting:review

# Use specific CLIs
/skill-set:consulting:review gemini codex
```

**Features**:
- Dynamic CLI selection with auto-detection
- Parallel LLM execution for faster feedback
- Synthesized reports with actionable insights
- Custom prompt templates for consistent reviews

### CodeRabbit Feedback Processing
Interactive CodeRabbit review processing with severity classification and verified completion workflow.

**Command**:
```bash
/skill-set:coderabbit:fix
```

**Features**:
- Automatic severity-based classification (CRITICAL, MAJOR, MINOR, OPTIONAL, IGNORE)
- Interactive issue discussion before applying changes
- Linear integration for issue tracking
- Verified completion workflow with mandatory steps
- Commit and PR comment generation

### Session Initialization
Automatically establishes workflows at session start to ensure proper skill usage.

**Activates on**: Session startup, resume, clear, or compact

**Features**:
- Auto-detects available skills
- Enforces skill usage protocols
- Provides context-aware skill recommendations
- Prevents workflow bypassing

## Usage

Skills are automatically available after installing the plugin. Claude will use them when relevant to your task.

### Explicit Skill Invocation

You can explicitly request skills:
```
Use the managing-git-workflow skill to create a commit
Use the understanding-code-context skill to explore this codebase
Use the browser-automation skill to take a screenshot
```

### Slash Commands

Use namespaced commands directly:
```bash
/skill-set:git:commit
/skill-set:git:push
/skill-set:git:pr
/skill-set:coderabbit:fix
/skill-set:consulting:review
```

## Project Structure

```
plugins/
└── skill-set/                   # Unified plugin
    ├── .claude-plugin/
    │   ├── plugin.json          # Plugin metadata
    │   └── marketplace.json     # Marketplace registration
    ├── .mcp.json                # MCP server definitions
    ├── commands/                # Namespaced slash commands
    │   ├── git/                 # Git workflow commands
    │   ├── coderabbit/          # CodeRabbit commands
    │   └── consulting/          # Peer review commands
    ├── skills/                  # All skills with integrated scripts
    │   ├── managing-git-workflow/
    │   │   ├── SKILL.md
    │   │   ├── git-helpers.sh   # Utility script
    │   │   └── reference/
    │   ├── understanding-code-context/
    │   │   ├── SKILL.md
    │   │   └── reference/
    │   ├── browser-automation/
    │   │   ├── SKILL.md
    │   │   ├── reference/
    │   │   └── templates/       # 16 Playwright scripts
    │   ├── consulting-peer-llms/
    │   │   ├── SKILL.md
    │   │   └── reference/
    │   └── using-skill-set/
    │       ├── SKILL.md
    │       └── session-start.sh # Session hook script
    ├── agents/                  # Isolated subagents
    │   └── coderabbit-feedback.md
    └── hooks/                   # Event handlers
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
- Playwright CLI (for browser automation features, optional)
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

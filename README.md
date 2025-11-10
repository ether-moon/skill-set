# skill-set

Collection of productivity skills and development tools for Claude Code.

## Installation

Add this plugin marketplace to Claude Code:

```bash
/plugin marketplace add ether-moon/skill-set
```

Then install the skill-set plugin:

```bash
/plugin install skill-set
```

## Available Skills

### 1. managing-git-workflow
Automates git operations (commit, push, PR) with context-aware message generation in the project's language and automatic ticket extraction from branch names.

**Commands**:
- `/skill-set:commit` - Create a git commit with context-aware messages and ticket extraction
- `/skill-set:push` - Push changes to remote (auto-commits if needed)
- `/skill-set:pr` - Create a pull request (auto-push and commit if needed)

### 2. understanding-code-context
Efficient code exploration using LSP symbolic tools (Serena) and official documentation (Context7) instead of text search and full file reading.

**Use when**: Exploring codebases, finding implementations, understanding library usage, or tracing dependencies.

### 3. browser-automation
Pre-built Playwright templates (19 scripts) for browser automation tasks - takes screenshots, generates PDFs, clicks elements, fills forms, monitors console/network.

**Use when**: Testing web pages, automating browser tasks, or when user mentions screenshots, web testing, form automation, or Playwright.

### 4. consulting-peer-llms
Request feedback from other LLM CLI tools (Gemini, Codex) on current work - executes peer reviews in parallel and synthesizes responses into actionable insights.

**Use when**: User explicitly requests review from other LLMs (e.g., "codex로 검증해줘", "gemini 피드백 받아줘").

## Usage

Skills are automatically available after installation. Claude will use them when relevant to your task.

You can explicitly invoke skills using:
```
Use the [skill-name] skill to [task description]
```

Or use the slash commands directly for git workflows.

## License

MIT
# skill-set

Collection of independent productivity plugins for Claude Code. Each plugin can be installed separately based on your needs.

## Installation

Add this plugin marketplace to Claude Code:

```bash
/plugin marketplace add ether-moon/skill-set
```

Then install individual plugins:

```bash
/plugin install browser-automation
/plugin install consulting-peer-llms
/plugin install managing-git-workflow
/plugin install understanding-code-context
/plugin install coderabbit-feedback
```

Or install all plugins at once:

```bash
/plugin install browser-automation consulting-peer-llms managing-git-workflow understanding-code-context coderabbit-feedback
```

## Available Plugins

### browser-automation
Automates browser interactions using Playwright CLI and templates for screenshots, PDFs, form filling, and monitoring.

**Use when**: Testing web pages, automating browser tasks, or when user mentions screenshots, web testing, form automation, or Playwright.

**Features**:
- Screenshot and PDF generation
- Form filling and validation
- Element interaction (click, hover, drag)
- Console and network monitoring
- 19 pre-built templates

### consulting-peer-llms
Execute peer reviews from other LLM tools (Gemini, Codex) in parallel and synthesize actionable insights.

**Use when**: User explicitly requests review from other LLMs (e.g., "validate with codex", "get feedback from gemini").

**Features**:
- Parallel LLM execution
- Synthesized reports
- Context-aware prompts

### managing-git-workflow
Automates git commits, push, and PR creation with context-aware messages and ticket extraction.

**Commands**:
- `/managing-git-workflow:commit` - Create a git commit with context-aware messages
- `/managing-git-workflow:push` - Push changes to remote (auto-commits if needed)
- `/managing-git-workflow:pr` - Create a pull request (auto-push and commit if needed)

**Features**:
- Language-aware commit messages
- Automatic ticket number extraction from branch names
- Context-aware PR descriptions

### understanding-code-context
Efficient code exploration using LSP symbolic tools (Serena) and official documentation (Context7).

**Use when**: Exploring codebases, finding implementations, understanding library usage, or tracing dependencies.

**Features**:
- Symbolic code navigation
- Official documentation lookup
- Efficient token usage
- Memory-based learning

### coderabbit-feedback
Interactive CodeRabbit review processing with severity classification and verified completion workflow.

**Command**:
- `/coderabbit-feedback:coderabbit-feedback` - Process CodeRabbit review comments interactively

**Features**:
- Severity-based classification
- Interactive issue discussion
- Linear integration
- Verified completion workflow

## Usage

Skills are automatically available after installing the respective plugin. Claude will use them when relevant to your task.

You can explicitly invoke skills using:
```
Use the [skill-name] skill to [task description]
```

Or use the slash commands directly for workflows that support them.

## License

MIT
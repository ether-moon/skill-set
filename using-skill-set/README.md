# using-skill-set

Automatically activates skill-set plugin awareness at the start of every Claude Code session.

## Overview

This plugin ensures that Claude agents are aware of all installed skill-set plugins and use them appropriately for each task. It runs automatically on session start and provides:

- **Automatic plugin detection**: Scans for installed skill-set plugins
- **Mandatory workflow enforcement**: Requires agents to check for relevant plugins before any task
- **Clear usage guidelines**: Provides descriptions and use cases for each plugin

## How It Works

On every session start (startup, resume, clear, or compact), the plugin:

1. Scans `~/.claude/plugins/` directory for installed skill-set plugins
2. Generates a dynamic list of available plugins
3. Injects this information into the agent's context
4. Enforces mandatory protocol to check for relevant plugins before responding

## Detected Plugins

The plugin automatically detects these skill-set plugins if installed:

- **browser-automation**: Browser automation with Playwright templates
- **consulting-peer-llms**: Parallel LLM peer reviews
- **managing-git-workflow**: Git commit, push, and PR automation
- **understanding-code-context**: Code exploration with LSP tools
- **coderabbit-feedback**: CodeRabbit review processing

## Installation

```bash
/plugin install using-skill-set
```

Once installed, the plugin automatically activates on every session start. No additional configuration required.

## Usage

You don't need to manually invoke this plugin. It runs automatically via session start hooks.

The agent will receive instructions to:
1. Check available plugins before any task
2. Use the Skill tool to read plugin documentation when relevant
3. Announce which plugin is being used
4. Follow plugin workflows exactly

## Benefits

- **Prevents workflow bypassing**: Agents can't skip mandatory steps
- **Improves consistency**: Same workflows across all sessions
- **Reduces errors**: Proven patterns are automatically applied
- **Saves time**: No need to manually remind agents about available tools

## Technical Details

### Hook Configuration

Uses `SessionStart` hook defined directly in `plugin.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume|clear|compact",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/session-start.sh"
          }
        ]
      }
    ]
  }
}
```

### Plugin Detection Logic

The `scripts/session-start.sh` script:
- Checks `~/.claude/plugins/` for each skill-set plugin directory
- Builds a markdown list of installed plugins
- Injects the list into SKILL.md template using `{{INSTALLED_PLUGINS}}` placeholder
- Outputs the complete skill content to the agent

## License

MIT

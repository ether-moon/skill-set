# Plugin Separation Design

**Date:** 2025-11-11
**Status:** Approved

## Overview

Split the monolithic `skill-set` plugin into 5 independent plugins within a monorepo structure. Each plugin is self-contained and installable separately.

## Current State

- Single `skill-set` plugin containing:
  - 4 skills (browser-automation, consulting-peer-llms, managing-git-workflow, understanding-code-context)
  - 1 agent (coderabbit-feedback)
  - 4 commands (commit, push, pr, coderabbit-feedback)

## Target State

5 independent plugins in monorepo:

1. **browser-automation** - Browser automation with Playwright
2. **consulting-peer-llms** - Peer LLM reviews
3. **managing-git-workflow** - Git workflow automation
4. **understanding-code-context** - Code exploration tools
5. **coderabbit-feedback** - CodeRabbit review processing

## Architecture

### Repository Structure

```
skill-set/  (monorepo root)
├── .claude-plugin/
│   └── marketplace.json       # 5 plugins registered
├── browser-automation/
├── consulting-peer-llms/
├── managing-git-workflow/
├── understanding-code-context/
├── coderabbit-feedback/
├── LICENSE
└── README.md                  # Overview of all plugins
```

### Individual Plugin Structure

**browser-automation/**
```
browser-automation/
├── .claude-plugin/
│   └── plugin.json
├── SKILL.md
└── reference/
    └── TEMPLATES.md
```

**consulting-peer-llms/**
```
consulting-peer-llms/
├── .claude-plugin/
│   └── plugin.json
├── SKILL.md
└── reference/
    ├── cli-commands.md
    ├── prompt-template.md
    └── report-format.md
```

**managing-git-workflow/**
```
managing-git-workflow/
├── .claude-plugin/
│   └── plugin.json
├── SKILL.md
├── reference/
│   ├── commit.md
│   ├── push.md
│   └── pr.md
├── commands/
│   ├── commit.md
│   ├── push.md
│   └── pr.md
└── scripts/
    └── git-helpers.sh
```

**understanding-code-context/**
```
understanding-code-context/
├── .claude-plugin/
│   └── plugin.json
├── SKILL.md
└── reference/
    ├── tools.md
    ├── workflows.md
    └── anti-patterns.md
```

**coderabbit-feedback/**
```
coderabbit-feedback/
├── .claude-plugin/
│   └── plugin.json
├── agents/
│   └── coderabbit-feedback.md
└── commands/
    └── coderabbit-feedback.md
```

## Plugin Metadata

### browser-automation/plugin.json
```json
{
  "name": "browser-automation",
  "description": "Automates browser interactions using Playwright CLI and templates for screenshots, PDFs, form filling, and monitoring.",
  "version": "1.0.0",
  "author": {
    "name": "ether-moon"
  },
  "license": "MIT"
}
```

### consulting-peer-llms/plugin.json
```json
{
  "name": "consulting-peer-llms",
  "description": "Execute peer reviews from other LLM tools (Gemini, Codex) in parallel and synthesize actionable insights.",
  "version": "1.0.0",
  "author": {
    "name": "ether-moon"
  },
  "license": "MIT"
}
```

### managing-git-workflow/plugin.json
```json
{
  "name": "managing-git-workflow",
  "description": "Automates git commits, push, and PR creation with context-aware messages and ticket extraction.",
  "version": "1.0.0",
  "author": {
    "name": "ether-moon"
  },
  "license": "MIT",
  "commands": [
    "./commands/"
  ]
}
```

### understanding-code-context/plugin.json
```json
{
  "name": "understanding-code-context",
  "description": "Efficient code exploration using LSP symbolic tools and official documentation (Context7).",
  "version": "1.0.0",
  "author": {
    "name": "ether-moon"
  },
  "license": "MIT"
}
```

### coderabbit-feedback/plugin.json
```json
{
  "name": "coderabbit-feedback",
  "description": "Interactive CodeRabbit review processing with severity classification and verified completion workflow.",
  "version": "1.0.0",
  "author": {
    "name": "ether-moon"
  },
  "license": "MIT",
  "commands": [
    "./commands/"
  ],
  "agents": [
    "./agents/coderabbit-feedback.md"
  ]
}
```

## Marketplace Configuration

Update `.claude-plugin/marketplace.json`:

```json
{
  "name": "skill-set",
  "owner": {
    "name": "ether-moon"
  },
  "plugins": [
    {
      "name": "browser-automation",
      "source": "./browser-automation",
      "description": "Automates browser interactions using Playwright CLI and templates for screenshots, PDFs, form filling, and monitoring."
    },
    {
      "name": "consulting-peer-llms",
      "source": "./consulting-peer-llms",
      "description": "Execute peer reviews from other LLM tools (Gemini, Codex) in parallel and synthesize actionable insights."
    },
    {
      "name": "managing-git-workflow",
      "source": "./managing-git-workflow",
      "description": "Automates git commits, push, and PR creation with context-aware messages and ticket extraction."
    },
    {
      "name": "understanding-code-context",
      "source": "./understanding-code-context",
      "description": "Efficient code exploration using LSP symbolic tools and official documentation (Context7)."
    },
    {
      "name": "coderabbit-feedback",
      "source": "./coderabbit-feedback",
      "description": "Interactive CodeRabbit review processing with severity classification and verified completion workflow."
    }
  ]
}
```

## Migration Steps

1. Create 5 new plugin directories at root level
2. Move skills, agents, commands to respective plugins
3. Create `.claude-plugin/plugin.json` for each plugin
4. Remove old `skill-set/` directory
5. Update `.claude-plugin/marketplace.json` with 5 plugins
6. Update root README.md with plugin overview

## Design Decisions

### Complete Independence
- No shared dependencies between plugins
- Each plugin is self-contained
- Users can install only what they need

### Flat Structure
- Remove unnecessary nesting (no `skills/` subdirectory within plugins)
- Direct access to SKILL.md and reference files
- Cleaner, more intuitive organization

### Monorepo Management
- Single repository for development
- Shared LICENSE and root README
- Independent plugin distribution via marketplace
- Simplified CI/CD and issue tracking

### Command Grouping
- Git commands (commit, push, pr) stay with managing-git-workflow
- CodeRabbit command stays with coderabbit-feedback agent
- Natural grouping by functionality

## Benefits

1. **User flexibility** - Install only needed plugins
2. **Clearer purpose** - Each plugin has focused responsibility
3. **Easier maintenance** - Changes isolated to specific plugins
4. **Better discovery** - Users can find specific functionality easily
5. **Version independence** - Plugins can evolve separately

## Testing Plan

After implementation:
1. Verify each plugin loads correctly
2. Test slash commands work with new paths
3. Verify agent execution
4. Confirm marketplace listing shows 5 plugins
5. Test installation of individual plugins

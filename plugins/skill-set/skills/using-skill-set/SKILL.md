---
name: using-skill-set
description: Establishes workflows for discovering and using skill-set skills. Use at session start to understand available capabilities, or when user asks about available skills, commands, or plugin features.
---

# Using skill-set

## Overview

This skill helps you discover and use skill-set features effectively. It provides a structured approach to finding relevant skills for your tasks.

## Available Skills

The following skills are currently installed:

{{INSTALLED_PLUGINS}}

### browser-automation
**Use when**: Testing web pages, automating browser tasks, screenshots, web testing, form automation, Playwright.

Automates browser interactions using Playwright CLI and templates.

### consulting-peer-llms
**Use when**: User explicitly requests review from other LLMs (e.g., "validate with codex", "get feedback from gemini").

Execute peer reviews from other LLM tools in parallel and synthesize actionable insights.

### managing-git-workflow
**Use when**: Creating commits, pushing to remote, creating pull requests.

Automates git commits, push, and PR creation with context-aware messages and ticket extraction.

**Commands**:
- `/skill-set:git:commit` - Create a git commit
- `/skill-set:git:push` - Push changes to remote
- `/skill-set:git:pr` - Create a pull request

### understanding-code-context
**Use when**: Understanding external libraries, frameworks, or dependencies.

Find and read official documentation using Context7.

### coderabbit-feedback
**Use when**: Processing CodeRabbit AI review comments on pull requests.

Interactive CodeRabbit review processing with severity classification and verified completion.

**Command**: `/skill-set:coderabbit:fix`

### writing-skills
**Use when**: Creating, improving, or reviewing skills; learning skill best practices.

Guide for creating effective Claude skills with structured workflow.

## How to Use Skills

### 1. Check for Relevant Skills

Before starting a task, consider if any installed skill applies:

- Git operations? → Use `managing-git-workflow`
- Browser testing? → Use `browser-automation`
- External library docs? → Use `understanding-code-context`
- Peer LLM review? → Use `consulting-peer-llms`
- Creating skills? → Use `writing-skills`

### 2. Load and Follow the Skill

When a skill is relevant:
1. Read the skill's SKILL.md to understand the workflow
2. Follow the documented steps
3. Reference linked files as needed

### 3. Announce When Using Skills

For transparency, briefly mention when using a skill:

"I'm using managing-git-workflow to create this commit."

This helps users understand your process.

## Common Rationalizations to Avoid

If you catch yourself thinking these, check for relevant skills first:

- "This is just a simple task" → Skills handle simple tasks efficiently
- "I can do this quickly without help" → Skills provide consistent workflows
- "Let me gather information first" → Skills define how to gather information
- "I remember how to do this" → Skills evolve; check the current version

## Best Practices

**Do check for skills** when:
- Starting git operations
- Working with external libraries
- Automating browser tasks
- Creating new skills

**Don't force skill usage** when:
- No skill is relevant to the task
- The task is conversational
- User explicitly opts out

## Quick Reference

| Task | Skill |
|------|-------|
| Git commit/push/PR | `managing-git-workflow` |
| Browser automation | `browser-automation` |
| External library docs | `understanding-code-context` |
| Peer LLM review | `consulting-peer-llms` |
| CodeRabbit feedback | `coderabbit-feedback` |
| Creating skills | `writing-skills` |

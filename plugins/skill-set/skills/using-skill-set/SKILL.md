---
name: using-skill-set
description: Discovers and routes to the right skill-set skill for any task. Use when user asks "what can you do", "which skills are available", "help me find the right tool", "list commands", "what features do you have", or mentions available skills, commands, or plugin capabilities. Also use at session start to understand available capabilities.
---

# Using skill-set

## Overview

Route tasks to the right skill-set skill. Each skill encodes a tested workflow that produces more consistent results than ad-hoc approaches — checking for a matching skill before starting work avoids reinventing steps that have already been refined.

## Available Skills

{{INSTALLED_PLUGINS}}

### consulting-peer-llms
**Use when**: User requests review from other LLMs (e.g., "validate with codex", "get feedback from gemini").

Execute peer reviews from other LLM tools in parallel and synthesize actionable insights.

**Command**: `/skill-set:consulting:review`

### managing-git-workflow
**Use when**: Creating commits, pushing to remote, creating pull requests, or user mentions git/GitHub operations.

Automates git commits, push, and PR creation with context-aware messages and ticket extraction.

**Commands**:
- `/skill-set:git:commit` — Create a git commit
- `/skill-set:git:push` — Push changes to remote
- `/skill-set:git:pr` — Create a pull request

### understanding-code-context
**Use when**: Looking up external library APIs, framework patterns, or dependency documentation.

Find and read official documentation using Context7.

### ralph
**Use when**: Planning or executing implementation work with fresh context per iteration. User mentions "ralph", "ralph loop", or "ralph wiggum".

Plans and executes via Ralph Wiggum loop — two modes (PLANNING/BUILDING), fresh subagent per iteration, plan file as single source of truth.

**Commands**:
- `/skill-set:ralph:plan` — Generate a Ralph-ready plan from any input
- `/skill-set:ralph:execute` — Execute a plan (auto-plans if none exists)

### autofixing-and-escalating
**Use when**: 2+ actionable items from an external source (linter, reviewer, scanner, test runner) appear — activates automatically without waiting for the user to ask.

Classifies issues by clarity of correctness, auto-fixes obvious ones, and escalates ambiguous ones with rationale and recommendations. Always reports what was auto-fixed.

### writing-clear-prose
**Use when**: Writing, drafting, revising, editing, or proofreading prose, proposals, reports, or technical documents.

Guides writing and revision with four core principles: concreteness, transcreation, steel man argumentation, and brevity.

### creating-skills
**Use when**: Creating, improving, or reviewing skills; learning skill best practices; editing SKILL.md files.

Comprehensive guide for creating effective Claude skills with structured workflow, testing, and optimization.

### guarding-agent-directives
**Use when**: Adding, modifying, or reviewing content in CLAUDE.md, AGENTS.md, or their referenced documents. Also applies when any agent autonomously attempts to modify these files.

Guards directive files against bloat by verifying additions through strict criteria while preserving user authority.

### developing-test-first
**Use when**: Implementing any feature or bugfix. Always before writing production code. User mentions TDD, test-first, red/green, or starts coding without tests.

Enforces strict Red/Green/Refactor discipline with Iron Law enforcement and rationalization prevention.

### driving-with-tests
**Use when**: Starting a coding session, designing test strategy, reviewing test changes, assessing coverage, or deciding what type of test to write.

Guides test strategy: orient (run suite first), probe (explore beyond tests), guard (protect tests as spec), and multi-layer test architecture. Pairs with `developing-test-first`.

### resolving-pr-blockers (agent)
**Use when**: PR has failing CI checks, merge conflicts, or unresolved review comments. User says "fix my PR", "CI failed", "resolve conflicts", "fix the build", "handle review comments", "PR won't merge".

Scans the current branch's PR for all blockers and dispatches specialized sub-agents to resolve them: merge conflicts, CI failures, and review feedback. Uses `autofixing-and-escalating` for classification.

**Command**: `/skill-set:pr:fix`

### shipping-pr
**Use when**: User wants to walk away after creating a PR and have it driven to clean state. Says "ship this PR", "wait for CI and fix", "auto-fix until clean", "PR autopilot".

Drives a PR end-to-end: creates the PR if missing (delegates to `managing-git-workflow`), polls CI checks and CodeRabbit reviews on each new HEAD SHA, dispatches `resolving-pr-blockers` when blockers appear, and re-polls after each fix-push cycle until the PR is clean, max-cycles is reached, or the resolver can't make progress.

**Command**: `/skill-set:pr:ship`

## Using Skills Effectively

Before starting a task, scan the catalog above for a matching skill. Skills encode workflows that have been tested and refined — they handle edge cases and produce consistent output that improves over time as the skill evolves.

When a skill matches:
1. Read the skill's SKILL.md to understand the workflow
2. Follow the documented steps and reference linked files as needed
3. Briefly mention which skill you are using for transparency (e.g., "Using managing-git-workflow for this commit.")

When no skill matches, proceed normally — skills should never be forced onto tasks they were not designed for. Also skip skills when the task is purely conversational or the user explicitly opts out.

## Why Check for Skills

Skills are worth checking because they solve problems Claude has already encountered:
- **Consistency** — A skill's workflow produces the same quality every time, while ad-hoc approaches vary between sessions
- **Evolved edge-case handling** — Skills accumulate fixes for failure modes discovered in real usage
- **Token efficiency** — Skills encode optimized tool-call sequences (e.g., combining git commands) that reduce round trips
- **Current best practice** — Skills get updated; what worked last session may have been improved since then

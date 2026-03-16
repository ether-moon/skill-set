# Changelog

All notable changes to the skill-set plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.7.0] - 2026-03-16

### Changed

- **coderabbit-feedback** renamed to **pr-review-feedback**: Generalized from CodeRabbit-specific to handling all PR review sources (human reviewers, CodeRabbit, Codex, Claude, other bots)
  - Comment collection no longer filters by author — processes ALL review comments
  - `@coderabbitai resolve` tag included only when CodeRabbit is detected among reviewers
  - Slash command changed: `/skill-set:coderabbit:fix` → `/skill-set:pr-review:fix`
  - Agent file slimmed from 743 to ~290 lines by removing verbose example templates

## [1.6.7] - 2026-03-13

### Fixed

- **consulting-peer-llms**: Remove direct CLI permissions from slash command file (`commands/consulting/review.md`) that still granted `Bash(codex:*)`, allowing agents to bypass the bundled script

## [1.6.6] - 2026-03-11

### Fixed

- **consulting-peer-llms**: Remove direct CLI permissions (Bash(gemini:*), Bash(codex:*)) from allowed-tools to structurally prevent agents from bypassing the bundled script

## [1.6.5] - 2026-03-11

### Fixed

- **consulting-peer-llms**: Remove inline CLI commands from Step 2 that led agents to bypass bundled script and construct wrong flags (e.g., `codex -q -a full-auto`)

## [1.6.4] - 2026-03-11

### Fixed

- **ralph**: Prohibit fabricated quantitative targets in planning mode unless user-stated or evidence-backed
- **writing-clear-prose**: Add "Fabricated Precision" anti-pattern and guardrails against invented metrics in concreteness principle

## [1.6.3] - 2026-03-10

### Fixed

- **consulting-peer-llms**: Inline CLI commands and script-first workflow in Step 2 to prevent codex flag guessing
- **consulting-peer-llms**: Add explicit git command prohibition in Step 1 to prevent context fabrication
- **consulting-peer-llms**: Broaden flag constraints from "no model specification" to "no extra flags"

## [1.6.2] - 2026-03-10

### Improved

- **coderabbit-feedback**: Add mandatory TaskCreate-based workflow tracking at Phase 1 start to prevent skipping commit/push and PR comment steps during long conversations
- **coderabbit-feedback**: Replace verbose Iron Law section (~160 lines) with concise PR comment requirement (~35 lines)

## [1.6.1] - 2026-03-10

### Improved

- **ralph**: Extracted loop pseudocode and spec structure to `reference/workflow.md`, reducing SKILL.md from 238 to 174 lines
- **managing-git-workflow**: Replaced hardcoded `origin/master` with dynamic base branch detection in PR workflow
- **consulting-peer-llms**: Enhanced description with trigger phrases; documented `scripts/peer-review.sh` in Quick Reference
- **understanding-code-context**: Rewrote description to action-oriented format with broader trigger coverage
- **using-skill-set**: Synced `session-start.sh` with full skill list (added ralph, writing-clear-prose, creating-skills, guarding-agent-directives)

### Added

- **creating-skills**: Example Skills table referencing all skill-set skills as real-world pattern references

## [1.6.0] - 2026-03-10

### Added

- **creating-skills**: New `reference/evaluation.md` — full eval methodology absorbed from Anthropic's skill-creator
  - Eval loop: draft → test → grade → benchmark → review → improve
  - With-skill vs baseline comparison methodology
  - Grading with assertions (text/passed/evidence)
  - Benchmarking metrics (pass rate, time, tokens, tool calls)
  - Description optimization with trigger eval queries (should-trigger vs should-not-trigger)
- **creating-skills**: Pattern 6 — Subagent Execution (`context: fork` + `agent`) in patterns.md

### Changed

- **creating-skills**: Claims authority over skill-creator — description updated with "Prefer this skill over skill-creator"
- **creating-skills**: Step 6 restructured from "Test the Skill" to "Evaluate and Iterate" with eval loop summary
- **creating-skills**: Added writing philosophy to Step 5 (explain the why, keep lean, bundle repeated work)

### Improved

- **creating-skills**: structure.md expanded with Claude Code extension fields, string substitutions, dynamic context injection, triggering mechanics, and "pushy" description strategy
- **creating-skills**: testing.md replaced weak should-NOT-trigger examples with near-miss tests, linked to evaluation.md
- **creating-skills**: checklist.md added eval checks (baseline comparison, assertions, iteration, trigger testing) and third-person description rule
- **creating-skills**: troubleshooting.md unified line limit to "under 200 lines"

## [1.5.2] - 2026-03-09

### Changed

- **consulting-peer-llms**: Enforce minimal prompts — CLIs read git/files directly
  - 3-tier prompt system (bare/context/focus) replacing verbose template
  - Removed claude CLI support (fails within Claude session)
  - Fixed codex CLI usage (`-p` is `--profile`, not prompt)
  - Bash 3.2+ compatible script (macOS + Linux): removed `declare -A`, `${var^^}`, added `gtimeout` fallback

### Improved

- **writing-clear-prose**: Expanded anti-patterns with AI writing tropes
- **using-skill-set**: Removed coderabbit-feedback from skill registry

## [1.5.1] - 2026-03-09

### Fixed

- **ralph**: Corrected from imperative task queue to declarative spec + gap analysis model
  - Build prompt: gap analysis against acceptance criteria instead of executing tasks
  - Plan prompt: generate acceptance criteria instead of task lists
  - Renamed plan-quality.md to spec-quality.md with updated quality criteria

### Added

- **using-skill-set**: Registered `guarding-agent-directives` in skill discovery flow

## [1.5.0] - 2026-03-06

### Added

- **ralph**: New PLANNING mode with `PROMPT_plan.md` for generating Ralph-ready plans from any input
- **ralph**: New `/skill-set:ralph:plan` command
- **ralph**: DONE condition negotiation step — propose and confirm observable termination criterion before loop starts
- **ralph**: `reference/plan-quality.md` defining Ralph-ready plan criteria (Concrete, Independent, Verifiable, Scoped)

### Changed

- **ralph**: Renamed from `executing-ralph-loop` to `ralph` (skill, commands, directory)
- **ralph**: Replaced checkbox-based progress tracking with git commit + plan file hash tracking
- **ralph**: Plans stored at `tmp/ralph/{YYYY-MM-DD-HHmm}/plan.md` (session-scoped, temporary)
- **ralph**: `/skill-set:ralph:execute` auto-enters PLANNING mode if no valid plan exists
- **using-skill-set**: Updated skill registry and quick reference for ralph

## [1.4.3] - 2026-03-05

### Improved

- **creating-skills**: Expanded trigger phrases to cover skill modification scenarios (edit, modify, update, fix, refactor)

## [1.4.2] - 2026-03-05

### Improved

- **creating-skills**: Added English writing guidance for token efficiency and LLM performance
- **guarding-agent-directives**: Added English writing guidance for directive content

## [1.4.1] - 2026-03-03

### Changed

- **executing-ralph-loop**: Changed from setup-only to direct execution via Task subagents
  - Each iteration spawns a fresh subagent (no context rot)
  - Plan file on disk as single source of truth
  - Automatic circuit breaker (3 consecutive iterations with no progress)
  - No files generated into project (prompt constructed in memory)

## [1.4.0] - 2026-02-27

### Added

- **executing-ralph-loop**: New skill for external bash loop implementation
  - Sets up Ralph Wiggum loop infrastructure for executing implementation plans with fresh context per iteration
  - Includes bash loop template and build prompt template

- **guarding-agent-directives**: New skill for strict directive file management
  - Guards agent directive files (CLAUDE.md, AGENTS.md) against bloat
  - Verifies additions through strict criteria while preserving user authority

- **writing-clear-prose**: New skill for non-fiction prose drafting and revision
  - Guides writing and revision of explanatory text, persuasive proposals, and technical documents
  - 4 core principles with reference files for principles, anti-patterns, drafting, and revising

### Changed

- **creating-skills**: Renamed from `writing-skills` for clarity and consistency with gerund naming convention

### Improved

- **managing-git-workflow**: Optimized Bash calls by combining reads and chaining writes for better performance

- **git commands**: Changed model from `haiku` to `sonnet` for commit, push, and PR commands

## [1.3.0] - 2026-02-10

### Removed

- **browser-automation**: Removed skill entirely — replaced by official [Playwright CLI](https://github.com/microsoft/playwright-cli)
  - Deleted SKILL.md, reference/TEMPLATES.md, and all 16 template scripts
  - Cleaned up all references across AGENTS.md, README.md, plugin.json, marketplace.json, using-skill-set, session-start.sh, .gitignore

## [1.2.1] - 2026-02-10

### Changed

- **consulting-peer-llms**: Streamlined skill and reference files (-83% token usage)
  - Simplified prompt: CLIs query git diffs directly, no need to pass diffs/SHAs/file lists
  - Removed output language/format specification from prompts (synthesizer handles it)
  - Added constraints: no model specification, no prompt temp files
  - Fixed CSO description (removed workflow summary per creating-skills guidelines)
  - Deleted `execution.md` (duplicated cli-commands.md and SKILL.md)
  - Reduced `cli-commands.md` from 612 to 53 lines
  - Reduced `report-format.md` from 646 to 109 lines
  - Moved synthesis principles inline to SKILL.md

## [1.2.0] - 2026-02-06

### Changed

- **consulting-peer-llms**: Improved CLI execution and review workflow
  - Fixed non-interactive CLI commands (`gemini -p`, `claude -p`, `codex exec`)
  - Review command now accepts requirements as arguments instead of CLI names
  - Auto-detect all installed CLIs; no manual CLI selection needed
  - Default to reviewing `origin/main` (or `origin/master`) diff when no arguments provided
  - Increased timeout to 1200s (20 minutes)
  - Added `allowed-tools` to review command for automatic bash permission

## [1.1.0] - 2025-01-30

### Added

- **creating-skills**: New skill for creating effective Claude skills
  - Comprehensive guide integrating Anthropic's official best practices
  - Reference files: structure, patterns, testing, troubleshooting, checklist
  - Covers use case definition, success criteria, and workflow patterns

- **allowed-tools**: Auto-permission support for skills
  - `browser-automation`: npx, node, npm
  - `consulting-peer-llms`: gemini, codex, claude, timeout
  - `managing-git-workflow`: git, gh, source, bash

### Changed

- **consulting-peer-llms**: Major refactoring (456→160 lines)
  - Extracted bash code to `scripts/peer-review.sh`
  - Moved execution details to `reference/execution.md`
  - Improved documentation structure

- **using-skill-set**: Improved tone and clarity
  - Removed aggressive/coercive language
  - Unified terminology ("plugins" → "skills")
  - More balanced guidance approach

- **AGENTS.md**: Updated documentation
  - Added creating-skills to Current Tools
  - Changed recommended SKILL.md line limit to 200
  - Added PDF guide reference

### Improved

- **browser-automation**: Added Troubleshooting section
  - Playwright installation issues
  - Browser not found errors
  - Timeout and permission problems

- **understanding-code-context**: Enhanced documentation
  - Added Troubleshooting section
  - Added explicit reference file links

## [1.0.2] - 2025-01-10

### Removed

- **understanding-code-context**: Removed all non-Context7 functionality
  - Removed Serena-specific dependencies and references
  - Removed LSP symbolic tools usage
  - Removed memory tools usage
  - Removed code exploration workflows (finding implementations, tracing dependencies)
  - Removed pattern search and file reading workflows

### Changed

- **understanding-code-context**: Refocused skill scope exclusively on Context7 library documentation
  - Skill now only provides workflows for finding and reading official library documentation via Context7
  - Updated all documentation to focus solely on Context7 usage
  - Removed all references to code exploration, symbol finding, and dependency tracing
  - Simplified to single workflow: understanding external libraries through official docs

## [1.0.1] - 2025-11-21

### Improved

- **consulting-peer-llms**:
  - **Optimization**: Embedded simplified prompt directly into `SKILL.md` for faster execution and reduced dependencies.
  - **Reliability**: Increased default timeout to 10 minutes (600s) for all CLIs to handle slower models like Codex.
  - **Simplicity**: Removed redundant CLI installation checks and simplified context gathering logic (using `origin/main` as base).

## [1.0.0] - 2025-11-11

### Changed

**Major architectural restructuring**: Unified all individual plugins into a single consolidated plugin structure.

#### Architecture Changes

- **Plugin Structure**: Converted from multiple independent plugins to a unified plugin architecture
  - Old: 6 separate plugins (managing-git-workflow, understanding-code-context, browser-automation, consulting-peer-llms, using-skill-set, coderabbit-feedback)
  - New: Single unified `skill-set` plugin with all features integrated

- **Skills Organization**: All skills now reside under `skills/` directory
  - `skills/managing-git-workflow/` - Git workflow automation
  - `skills/understanding-code-context/` - Code exploration with LSP tools
  - `skills/browser-automation/` - Playwright automation templates
  - `skills/consulting-peer-llms/` - Peer LLM review integration
  - `skills/using-skill-set/` - Session initialization workflows

- **Commands Consolidation**: Organized commands by namespace under `commands/`
  - `commands/git/` - commit, push, pr commands
  - `commands/coderabbit/` - fix command
  - `commands/consulting/` - review command

- **Unified Configuration**:
  - Single `.claude-plugin/plugin.json` for all plugin metadata
  - Consolidated `hooks/hooks.json` for session start hooks
  - Unified `scripts/` directory for all utility scripts

#### Benefits

- **Simplified Installation**: One plugin installation instead of managing six separate plugins
- **Better Resource Management**: Shared resources and dependencies
- **Consistent Configuration**: Single source of truth for plugin settings
- **Easier Maintenance**: Centralized updates and version management
- **Improved Discovery**: All features accessible from one plugin namespace

### Migration Notes

Users upgrading from v1.x should:

1. Uninstall all individual plugins (if previously installed separately)
2. Install the unified `skill-set` plugin
3. All command paths remain the same, but are now organized under namespaced directories
4. Skills are now loaded from `skills/{skill-name}/` instead of plugin root

### Added

- Initial release with 6 independent plugins:
  - `managing-git-workflow`: Git automation (commit, push, PR)
  - `understanding-code-context`: LSP-based code exploration
  - `browser-automation`: Playwright templates
  - `consulting-peer-llms`: Peer review integration
  - `using-skill-set`: Session initialization
  - `coderabbit-feedback`: CodeRabbit review processing

[1.6.1]: https://github.com/ether-moon/skill-set/releases/tag/v1.6.1
[1.6.0]: https://github.com/ether-moon/skill-set/releases/tag/v1.6.0
[1.5.2]: https://github.com/ether-moon/skill-set/releases/tag/v1.5.2
[1.5.1]: https://github.com/ether-moon/skill-set/releases/tag/v1.5.1
[1.5.0]: https://github.com/ether-moon/skill-set/releases/tag/v1.5.0
[1.4.3]: https://github.com/ether-moon/skill-set/releases/tag/v1.4.3
[1.4.2]: https://github.com/ether-moon/skill-set/releases/tag/v1.4.2
[1.4.1]: https://github.com/ether-moon/skill-set/releases/tag/v1.4.1
[1.4.0]: https://github.com/ether-moon/skill-set/releases/tag/v1.4.0
[1.3.1]: https://github.com/ether-moon/skill-set/releases/tag/v1.3.1
[1.3.0]: https://github.com/ether-moon/skill-set/releases/tag/v1.3.0
[1.2.1]: https://github.com/ether-moon/skill-set/releases/tag/v1.2.1
[1.2.0]: https://github.com/ether-moon/skill-set/releases/tag/v1.2.0
[1.1.0]: https://github.com/ether-moon/skill-set/releases/tag/v1.1.0
[1.0.2]: https://github.com/ether-moon/skill-set/releases/tag/v1.0.2
[1.0.1]: https://github.com/ether-moon/skill-set/releases/tag/v1.0.1
[1.0.0]: https://github.com/ether-moon/skill-set/releases/tag/v1.0.0

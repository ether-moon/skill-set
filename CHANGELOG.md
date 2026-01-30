# Changelog

All notable changes to the skill-set plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2025-01-30

### Added

- **writing-skills**: New skill for creating effective Claude skills
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
  - Added writing-skills to Current Tools
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

[1.1.0]: https://github.com/ether-moon/skill-set/releases/tag/v1.1.0
[1.0.2]: https://github.com/ether-moon/skill-set/releases/tag/v1.0.2
[1.0.1]: https://github.com/ether-moon/skill-set/releases/tag/v1.0.1
[1.0.0]: https://github.com/ether-moon/skill-set/releases/tag/v1.0.0

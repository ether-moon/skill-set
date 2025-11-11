# Changelog

All notable changes to the skill-set plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[1.0.0]: https://github.com/ether-moon/skill-set/releases/tag/v1.0.0

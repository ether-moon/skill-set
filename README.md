# skill-set

Collection of productivity skills and development tools for Claude Code.

## Installation

Add this plugin marketplace to Claude Code:

```bash
/plugin marketplace add https://github.com/ether-moon/skill-set
```

Then install the skill-set plugin:

```bash
/plugin install skill-set
```

## Usage

### Available Skills

- **managing-git-workflow**: Automates git commits, push, and PR creation with Korean commit messages and automatic ticket extraction

### Available Commands

- `/ss:commit` - Create a git commit with Korean messages and ticket extraction
- `/ss:push` - Push changes to remote (auto-commits if needed)
- `/ss:pr` - Create a pull request (auto-push and commit if needed)

## License

MIT
# skill-set

A unified Claude Code plugin for git and PR automation, testing discipline, skill authoring, architecture review, and technical writing.

## Installation

Add the plugin to Claude Code:

```bash
/plugin install skill-set
```

## Skills

### Delivery workflows

- **managing-git-workflow** — Creates context-aware commits, pushes branches, and opens pull requests.
- **autofixing-and-escalating** — Classifies external findings, fixes unambiguous issues, and escalates decisions that require user judgment.
- **shipping-pr** — Polls CI and review status, dispatches blocker resolvers, and repeats until a pull request is verified clean or convergence stops.
- **bumping-version** — Detects project version files, updates release metadata, and prepares the version bump for publication.

### Testing

- **developing-test-first** — Applies the Red/Green/Refactor cycle when implementing behavior changes.
- **driving-with-tests** — Establishes the test baseline, selects appropriate test layers, probes behavior, and protects tests as specifications.

### Planning and architecture

- **grilling-plans** — Stress-tests an existing plan one decision at a time before implementation.
- **improving-architecture** — Finds high-leverage module boundaries and refactor candidates across a codebase.
- **zooming-out-on-code** — Maps the responsibility, callers, dependencies, and siblings around unfamiliar code.

### Authoring and project guidance

- **creating-skills** — Guides skill design, structure, testing, evaluation, and iteration using repository conventions.
- **writing-clear-prose** — Improves explanatory, persuasive, and technical writing through structured drafting and revision.
- **guarding-agent-directives** — Reviews proposed agent directives for duplication, overreach, poor placement, and context bloat.

## Slash Commands

```text
/skill-set:git:commit
/skill-set:git:push
/skill-set:git:pr
/skill-set:pr:fix
/skill-set:pr:ship
/skill-set:plan:grill
/skill-set:code:zoom-out
```

Skills are also model-invocable and load automatically when their descriptions match the current task.

## Project Structure

```text
plugins/
└── skill-set/
    ├── .claude-plugin/
    │   └── plugin.json
    ├── .mcp.json
    ├── commands/
    │   ├── code/                  # zoom-out
    │   ├── git/                   # commit, push, pr
    │   ├── plan/                  # grill
    │   └── pr/                    # fix, ship
    ├── skills/
    │   ├── autofixing-and-escalating/
    │   ├── bumping-version/
    │   ├── creating-skills/
    │   ├── developing-test-first/
    │   ├── driving-with-tests/
    │   ├── grilling-plans/
    │   ├── guarding-agent-directives/
    │   ├── improving-architecture/
    │   ├── managing-git-workflow/
    │   ├── shipping-pr/
    │   ├── writing-clear-prose/
    │   └── zooming-out-on-code/
    └── agents/
        ├── resolving-pr-blockers.md
        ├── merge-conflict-resolver.md
        ├── ci-failure-resolver.md
        └── pr-review-feedback.md
```

## Design Principles

- **Progressive disclosure** — Keep core workflows in `SKILL.md` and load references only when needed.
- **Context awareness** — Adapt workflow output to project language and conventions.
- **Token efficiency** — Keep skill metadata and instructions focused on behavior the model cannot reliably infer.
- **Namespacing** — Organize commands to prevent collisions.
- **Verification** — Test runtime integrations in addition to validating static plugin structure.

## Requirements

- Claude Code
- Git for repository workflows
- GitHub CLI for pull request workflows

## Contributing

See [AGENTS.md](AGENTS.md) for repository conventions and skill development guidance.

## License

MIT

## Acknowledgements

The following skills were inspired by [mattpocock/skills](https://github.com/mattpocock/skills) (MIT license):

- `grilling-plans` ← `grill-me` / `grill-with-docs`
- `zooming-out-on-code` ← `zoom-out`
- `improving-architecture` ← `improve-codebase-architecture`
- `developing-test-first` (Horizontal Slicing section) ← `tdd`

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and migration notes.

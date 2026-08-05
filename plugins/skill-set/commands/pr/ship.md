---
description: Ship a PR through resumable CI, review, and blocker-resolution cycles
allowed-tools: Skill
---

Invoke the `shipping-pr` skill with the user's arguments.

Supported flags and defaults:

- `--max-cycles N` — resolver attempts, default 5
- `--ci-timeout MIN` — current-HEAD CI deadline, default 30
- `--review-timeout MIN` — current-HEAD CodeRabbit deadline, default 10
- `--no-coderabbit` — disable CodeRabbit completion checks
- `--no-create` — fail when the current branch has no PR
- `--required-only=BOOL` — select required checks only, default true

The workflow keeps state in the repository's Git common directory and rejects concurrent active runs. It binds publication to the live PR head repository/ref and the selected remote's canonical push URL, including fork remotes. Resume existing state instead of starting a second loop. Never include dirty files, publish partial resolver work, force-push, merge, pull, or rebase.

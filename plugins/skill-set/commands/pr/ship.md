---
description: Ship a PR end-to-end — create (if needed), poll CI and CodeRabbit, auto-fix blockers, repeat until clean
---

Invoke the `shipping-pr` skill to drive the full PR lifecycle: PR creation (delegated to `managing-git-workflow`), CI/CodeRabbit polling, blocker resolution (delegated to `resolving-pr-blockers`), and re-polling after each fix-push cycle until the PR is clean or convergence fails.

**Flags (all optional):**
- `--max-cycles N` — max ship cycles (default: 3)
- `--ci-timeout 30` — total CI wait budget per cycle in minutes (default: 30)
- `--review-timeout 10` — CodeRabbit incremental review wait per cycle in minutes (default: 10)
- `--no-coderabbit` — disable CodeRabbit detection and waiting
- `--no-create` — fail if no PR exists for the current branch (skip PR creation)
- `--required-only=BOOL` — wait only on required checks (default: true; pass `--required-only=false` to wait on advisory checks too)

**Behavior:**
- Each cycle posts its own PR summary comment via `pr-review-feedback` (intended; CodeRabbit resolution included when applicable)
- Pauses for user input on AMBIGUOUS items inside the fix step, then resumes the cycle
- Exits early on PR closure, convergence failure (fix produced no new commit), or max-cycles reached

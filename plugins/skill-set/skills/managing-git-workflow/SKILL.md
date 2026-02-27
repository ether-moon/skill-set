---
name: managing-git-workflow
description: Automates git commits, push, and PR creation with context-aware messages and ticket extraction. Use when performing git operations, creating commits/PRs, or when user mentions git, GitHub, commit, push, or pull request.
allowed-tools: "Bash(git:*) Bash(gh:*)"
---

# Managing Git Workflow

## Overview

Automates git workflows for commit, push, and PR creation with context-aware message generation and automatic ticket number extraction.

## When to Use

- Creating commits with auto-generated messages in project's language
- Pushing changes (with automatic commit if needed)
- Creating PRs (with automatic push and commit if needed)
- When user mentions: git, commit, push, pull request, PR, GitHub

## Workflow Selection

| Task | Reference Document | Handles internally |
|------|------|---------------------|
| Commit only | `managing-git-workflow/reference/commit.md` | — |
| Push to remote | `managing-git-workflow/reference/push.md` | Commit (if uncommitted changes) |
| Create PR | `managing-git-workflow/reference/pr.md` | Commit + Push (if needed) |

Each workflow is **self-contained** — no delegation between reference files. This eliminates duplicate state checks.

## Common Principles

**Commit Messages:**
- Use language specified in project context, prompts, or documentation (default to English if unspecified)
- Follow existing project patterns (analyze with `git log --oneline -10`)
- Include ticket numbers (FMT-XXXXX, FLEASVR-XXX, etc.) if found in branch name or changes

**Branch Naming:**
- Extract ticket numbers from branch names for PR titles
- Use descriptive, concrete names

**All commands start with `git` or `gh`** to ensure compatibility with standard permission patterns (`Bash(git:*)`, `Bash(gh:*)`).

### Bash Call Optimization

- **Combine independent reads** with `;` separator in a single Bash call (e.g., `git status --porcelain; git log --oneline -10; git branch --show-current`)
- **Chain sequential writes** with `&&` in a single Bash call (e.g., `git add -A && git commit -m "..." && git push`)
- **Self-contained workflows**: Each workflow handles its own state checks inline — no delegation to other reference files
- **Pre-staging analysis**: Use `git diff HEAD --stat` before staging to analyze changes without a separate `git add` call
- **Inline verification**: Append verification to write calls (e.g., `git commit -m "..." && git log --oneline -1`)
- **Separate `git` and `gh` commands**: Keep `git` and `gh` prefixed commands in separate Bash calls for `Bash(git:*)` / `Bash(gh:*)` pattern compatibility

## Quick Reference

```bash
# Check status
git status --porcelain                    # empty = clean
git rev-list --count @{u}..HEAD           # 0 = up to date
git branch --show-current                 # current branch name
gh pr list --head "$(git branch --show-current)" --json number --jq 'length'  # 0 = no PR
```

## Implementation

**For commit workflow:** See `managing-git-workflow/reference/commit.md`

**For push workflow:** See `managing-git-workflow/reference/push.md`

**For PR workflow:** See `managing-git-workflow/reference/pr.md`

Each reference document provides step-by-step instructions for that specific operation.

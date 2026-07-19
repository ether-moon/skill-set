---
name: managing-git-workflow
description: Safely inspects repository state and executes explicitly authorized commits, pushes, and pull-request creation through a constrained runner. Use when the user asks to commit selected work, push existing commits, create or inspect a pull request, save changes in Git, or publish a branch to GitHub.
allowed-tools: "Bash(${CLAUDE_PLUGIN_ROOT}/bin/skill-set-git:*) Edit(//**/.git/skill-set/inputs/commit-message.*/content) Edit(//**/.git/worktrees/*/skill-set/inputs/commit-message.*/content) Edit(//**/.git/skill-set/inputs/pr-body.*/content) Edit(//**/.git/worktrees/*/skill-set/inputs/pr-body.*/content)"
---

# Managing Git Workflow

## Overview

Turn an explicit Git or pull-request request into one bounded operation. Use only `${CLAUDE_PLUGIN_ROOT}/bin/skill-set-git` for Git and GitHub activity. The runner returns JSON, preserves shell metacharacters through file arguments, and applies index and remote compare-and-swap checks before mutation.

## Authorization Boundary

Inspection is read-only. Run `inspect` whenever repository state may have changed.

Treat each mutation as a separate capability:

- `commit`: authorized only by a request to create a commit; never pushes.
- `push`: authorized only by a request to push; publishes existing commits only.
- `pr-create`: authorized only by a request to create a PR; may push existing commits when the PR branch is not current remotely.

Do not infer one capability from another. A commit request does not authorize push, and a push request does not authorize creating a commit. Never execute direct Git or GitHub commands from this skill.

## Workflow Selection

| Request | Reference | Runner operation |
|---|---|---|
| Inspect or commit | `reference/commit.md` | `inspect`, `commit` |
| Push existing commits | `reference/push.md` | `inspect`, `push` |
| Create or find a PR | `reference/pr.md` | `inspect`, `pr-create` |

## Common Contract

1. Parse successful stdout as one JSON object.
2. Parse a nonzero command's stderr as a recoverable JSON error.
3. Stop on stale `index_fingerprint`, changed remote SHA, behind/diverged history, or ambiguous scope.
4. Use `--dry-run` before a mutation when the requested scope is not already fully confirmed.
5. Ask `input-prepare` for a managed path, replace its exact `SKILL_SET_INPUT_REPLACE_ME` sentinel through the scoped Edit capability, then pass it as `--message-file` or `--body-file`.
6. Preserve staged, unstaged, and untracked distinctions in every user-facing summary.

## Commit Scope Rules

- With no paths, commit the current index only.
- With user-named paths, pass one `--path` per path. The runner rejects staged paths outside that scope.
- Pass `--all` only when the user explicitly requested every current change.
- If the index is empty and no scope was named, ask for paths. Do not infer them from nearby files.
- Generate the message from `commit_context.staged_diff` or the `staged_preview` returned by commit dry-run, not from a general working-tree summary.

## Language Detection

Detect the user's language from the current conversation, project instructions, and recent commit subjects returned by `inspect`. Default to English. Adapt user-facing messages, commit messages, and PR text; keep commands, paths, and technical identifiers in English.

## Safety Invariants

- Never publish from `commit`.
- Never create a commit from `push` or `pr-create`.
- Never include dirty files in a PR implicitly.
- Require explicit confirmation before proceeding with dirty files excluded from a new PR.
- Return an existing PR URL instead of creating a duplicate.
- Use the committed PR range `origin/<base>...HEAD` reported by the runner.
- Do not resolve divergence or remote races automatically; report the recovery decision to the user.
- If the user cancels after preparing text, remove its managed allocation with `input-discard`.
- Never pass an unchanged sentinel; the runner rejects it before any commit, push, or PR creation.

## References

- `reference/commit.md` — index/path scope, message generation, and index CAS
- `reference/push.md` — expected remote SHA and existing-commit publication
- `reference/pr.md` — committed PR scope, dirty exclusion, and existing PR detection

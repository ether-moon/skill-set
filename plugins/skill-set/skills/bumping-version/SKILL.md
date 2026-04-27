---
name: bumping-version
description: Bump a project's version with changelog update — auto-detects version files (plugin.json, package.json, pyproject.toml, Cargo.toml, gemspec, VERSION, ...). Use when user says "bump", "version up", or "release". Per-repo policy (base branch, extra files, commit message) read from CLAUDE.md / AGENTS.md.
---

# Bumping Version

Bump a project's version, update its changelog, commit on top of the latest base branch, and either push directly or fall back to opening a PR if the base is protected.

The skill is repo-agnostic. Per-repo policy lives in `CLAUDE.md` / `AGENTS.md` under a `## Versioning` section. Defaults apply when the section is absent.

## Workflow

### 0. Preflight & worktree setup

1. **Determine the base branch:**
   - First check the repo's `## Versioning` section for `Base branch:`.
   - Fall back to `git symbolic-ref refs/remotes/origin/HEAD | sed 's|.*/||'` (e.g., `main`).

2. **Sync the base:**

```bash
git fetch origin <base>
```

3. **Create a temporary worktree on the latest base.** This isolates the bump from the user's current checkout — no preflight cleanliness required.

```bash
WT_PATH=".git/worktrees/bump-$(date +%s)"
git worktree add "$WT_PATH" "origin/<base>"
```

All subsequent steps use `git -C "$WT_PATH" ...`.

### 1. Analyze changes since last bump

Run two separate Bash calls (no `$(...)` substitution — Claude Code blocks it):

```bash
# Call 1: find last bump commit on base
git -C "$WT_PATH" log --oneline --grep="^chore: bump\|^chore: release" -1 --format="%H" origin/<base>
```

Read the SHA from the output. If empty, treat the first commit on base as the start. Then:

```bash
# Call 2: list commits since last bump (replace <SHA> with output from Call 1)
git -C "$WT_PATH" log --oneline <SHA>..origin/<base>
```

Reading from `origin/<base>` ensures the changelog reflects only merged commits.

### 2. Load repo context

Read the `## Versioning` section (case-insensitive header match) from `CLAUDE.md` first, then `AGENTS.md`. Recognized keys (all optional):

- `Base branch:` — overrides auto-detection.
- `Commit message:` — template; `{version}` placeholder replaced. Default: `chore: bump version to {version}`.
- `Extra version files:` — comma-separated paths to also update (in addition to auto-detected ones).
- `Changelog categories:` — override defaults (`Added`, `Improved`, `Fixed`).

If the section is missing, all defaults apply.

### 3. Detect version files & current version

Scan in order, list every file found and its current version:

| Ecosystem | File pattern | Field |
|---|---|---|
| Claude plugin | `**/.claude-plugin/plugin.json` | `.version` (JSON) |
| Node | `package.json` | `.version` (JSON) |
| Python (modern) | `pyproject.toml` | `[project].version` or `[tool.poetry].version` |
| Python (legacy) | `**/__init__.py` | line `__version__ =` |
| Rust | `Cargo.toml` | `[package].version` |
| Ruby | `*.gemspec`, `lib/**/version.rb` | `spec.version =` / `VERSION =` |
| Generic | `VERSION`, `version.txt` (root only) | whole file (one line) |
| Repo-specified | from `Extra version files:` | regex `version[:= ]+"?(\d+\.\d+\.\d+)"?` |

Display the discovered files with their current version.

### 4. Verify version consistency

All discovered files must show the same current version. If any differ, stop and ask which to take as truth before proceeding.

### 5. Suggest semver level

Based on the commit list, recommend `patch` / `minor` / `major` with one-line rationale, then ask the user to choose. Use the user's language for the prompt.

```
[In user's language]

Changes since last bump:
- [commit summary 1]
- [commit summary 2]

Current version: X.Y.Z
Suggested: <patch|minor|major> (reason)

Which level?
- [1] patch
- [2] minor
- [3] major
```

### 6. Update files

Apply the new version to every discovered manifest. For changelog (`CHANGELOG.md` at repo root):

- Format: Keep a Changelog (`## [X.Y.Z] - YYYY-MM-DD`).
- New entry prepended after the file header, before the previously-latest entry.
- Categories from context (default `Added` / `Improved` / `Fixed`).
- Date is today.

If `CHANGELOG.md` is absent, ask whether to create it; declining skips the changelog step.

### 7. Commit

Inside worktree: stage all updated files + changelog, create a single commit. Message uses the repo context template (default `chore: bump version to X.Y.Z`).

```bash
git -C "$WT_PATH" add -A
git -C "$WT_PATH" commit -m "chore: bump version to X.Y.Z"
```

### 8. Push or PR fallback

```bash
# 1st attempt: push directly to base
git -C "$WT_PATH" push origin HEAD:<base>
```

If push **succeeds** → proceed to cleanup.

If push **fails**, capture stderr and check for a protection-error pattern (regex `GH006|protected branch|remote rejected|hook declined`). On match, fall back to PR:

```bash
git -C "$WT_PATH" branch bump-version-X.Y.Z
git -C "$WT_PATH" push -u origin bump-version-X.Y.Z
gh -C "$WT_PATH" pr create \
  --base <base> \
  --head bump-version-X.Y.Z \
  --title "chore: bump version to X.Y.Z" \
  --body "$(cat <<'EOF'
## Changelog

<paste the new CHANGELOG entry here>
EOF
)"
```

Emit the PR URL to the user.

If the failure does **not** match the protection pattern (e.g., network error, auth issue), report the error verbatim, leave the worktree for inspection, and stop.

### 9. Cleanup

```bash
git worktree remove "$WT_PATH"
```

Always print the original branch name back to the user so they know nothing changed in their working tree.

## Rules

- Bump commit is always its own commit (never mixed with other work).
- Changelog date is today.
- Version inconsistency across manifests blocks automatic progress — always ask.
- Never `--force` push.
- If `gh` is missing or unauthenticated when PR fallback is needed, instruct the user to run `gh auth login` and re-run the skill; do not silently fail.

## Repo-context interface (example)

In `CLAUDE.md` or `AGENTS.md`:

```markdown
## Versioning

- **Base branch**: main
- **Commit message**: chore: bump version to {version}
- **Extra version files**: docs/install.md
- **Changelog categories**: Added, Improved, Fixed
```

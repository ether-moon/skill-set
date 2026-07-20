# Commit Workflow

Create one authorized commit without publishing it.

## 1. Inspect

Run:

```bash
"${CLAUDE_PLUGIN_ROOT}/bin/skill-set-git" inspect
```

Report `working_tree.staged`, `working_tree.unstaged`, and `working_tree.untracked` separately. Retain `index_fingerprint` for the commit compare-and-swap check.

## 2. Select the Scope

Choose exactly one mode:

- Existing index: no scope flag. Use only when staged files exist.
- Named paths: repeat `--path <path>` for paths the user selected.
- Every change: use `--all` only when the user explicitly requested all current changes.

If paths were named while unrelated paths are already staged, the runner returns `unrelated_staged_paths`. Stop and ask whether to commit the existing index separately or revise the requested path scope.

If no staged files and no scope are available, ask the user for paths. Never widen scope by inference.

## 3. Preview the Exact Index

Preview without a message file or mutation:

```bash
"${CLAUDE_PLUGIN_ROOT}/bin/skill-set-git" commit --dry-run --path path/to/file
```

Repeat `--path` as needed, omit scope flags for the current index, or use explicit `--all`. Generate the message from `staged_preview.diff` and `staged_preview.stat`. For an existing index, `inspect.commit_context` contains the same message-generation context.

## 4. Prepare the Message File

Match the repository's recent subject style and the user's language. Describe only the previewed diff. Include a ticket identifier from the branch only when it is actually present.

Allocate a private file owned by the runner:

```bash
"${CLAUDE_PLUGIN_ROOT}/bin/skill-set-git" input-prepare --kind commit-message
```

The allocated file contains exactly `SKILL_SET_INPUT_REPLACE_ME`. Use the scoped Edit capability on the returned `path`, with that sentinel as `old_string` and the exact commit message as `new_string`. This works without broad file-write permission and keeps the file inside worktree-specific Git metadata, where it cannot enter a commit scope. Do not interpolate the message into a shell command.

The runner rejects an empty file or any file where the sentinel remains, before creating a commit.

## 5. Commit with Index CAS

Use the fingerprint returned by the latest inspection:

```bash
"${CLAUDE_PLUGIN_ROOT}/bin/skill-set-git" commit \
  --expected-index "<index-fingerprint>" \
  --path path/to/file \
  --message-file /tmp/commit-message.txt
```

Use the same scope selected and previewed earlier. On success, report `commit.sha`, `commit.subject`, and `pushed:false`.

The runner consumes the managed message allocation after a successful commit. If the user cancels first, call `input-discard --input-file <managed-path>`.

If the runner returns `index_changed`, inspect again and re-confirm the scope. If it returns `nothing_staged` or `nothing_to_commit`, stop without creating an empty commit.

## Dry-Run Guarantee

`commit --dry-run` never changes HEAD or the real index. It uses a temporary index for path and all-change previews, so untracked files appear in the exact staged preview without being staged.

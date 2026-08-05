# Push Workflow

Publish existing commits without creating or rewriting commits.

## 1. Inspect and Confirm Authorization

Run:

```bash
<git-runner> inspect
```

Confirm that the user requested a push. Dirty staged, unstaged, and untracked files are reported as excluded; they do not become part of the publication.

Record `branch.remote_sha`. Use the literal value `absent` when it is `null`.

## 2. Preview

```bash
<git-runner> push \
  --expected-remote-sha "<sha-or-absent>" \
  --dry-run
```

Report `commits_to_push`, the destination, and `dirty_excluded`. A dry-run reads the remote twice and makes no publication.

## 3. Push Existing Commits

After confirming the destination:

```bash
<git-runner> push \
  --expected-remote-sha "<sha-or-absent>"
```

The runner reads the destination SHA again immediately before publication, rejects behind or diverged history, and verifies that the resulting remote SHA equals local HEAD. It never creates a commit or includes dirty files.

`--remote <name>` selects an explicit remote. `--remote-branch <short-name>` is reserved for an already-authorized resolver publishing an isolated worktree HEAD to a known PR branch; the runner validates that branch name and applies the same expected-SHA checks.

## Recovery

| Error code | Response |
|---|---|
| `remote_changed` | Inspect again and present the new state. |
| `remote_ahead` | Stop and ask how to reconcile incoming commits. |
| `diverged` | Stop and ask the user to choose a reconciliation strategy. |
| `push_failed` | Report authentication, protection, or server rejection without changing local commits. |

Do not perform automatic history reconciliation or retry with a widened publication policy.

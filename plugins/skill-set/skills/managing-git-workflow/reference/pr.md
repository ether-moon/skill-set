# Pull Request Workflow

Create a PR from committed work only, or return the existing PR URL.

## 1. Inspect the Committed Scope

Run with the intended base:

```bash
<git-runner> inspect --base "<base-branch>"
```

Use only `pr_scope.range`, `pr_scope.files`, and committed history to generate the title and body. The range is `origin/<base>...HEAD`. Never describe dirty changes as part of the PR.

Show staged, unstaged, and untracked paths as **excluded from the PR**. If any exist, obtain explicit confirmation that they should remain excluded before creating a new PR.

## 2. Prepare the Body File

Generate a concrete title and body in the user's language while preserving technical identifiers. Allocate the body file first:

```bash
<git-runner> input-prepare --kind pr-body
```

The allocated file contains exactly `SKILL_SET_INPUT_REPLACE_ME`. Use the scoped Edit capability on the returned `path`, replacing that exact `old_string` with the complete body as `new_string`. Do not interpolate it into a shell command. The runner rejects an empty body or a remaining sentinel before any push or PR operation, consumes a managed body after successful creation or existing-PR discovery, and preserves it on recoverable failure. Use `input-discard` if the user cancels.

Suggested body sections are Summary, Changes, and Test Plan when the committed evidence supports them. Do not invent tests.

## 3. Preview

```bash
<git-runner> pr-create \
  --base "<base-branch>" \
  --title "<pull-request-title>" \
  --body-file /tmp/pull-request-body.md \
  --confirm-dirty-excluded \
  --dry-run
```

Omit `--confirm-dirty-excluded` when the working tree and index are clean. The preview reports the exact committed scope and whether existing commits need publication.

## 4. Create or Reuse

Invoke the same command without `--dry-run`. The runner first checks for an open PR from the current branch.

- Existing PR: returns `existing:true`, `created:false`, and its URL without publication or duplication.
- New PR: rechecks the observed remote SHA, publishes existing commits only when required, passes the body file directly to GitHub CLI, and returns `created:true` with the URL.

The operation never commits dirty files. A PR request authorizes the necessary push of existing commits, but no other Git mutation.

## Recovery

Stop on `dirty_exclusion_unconfirmed`, `remote_changed`, `remote_ahead`, or `diverged`. Report the separate dirty lists and committed range so the user can make the next decision. If PR creation fails after a successful branch push, report that the remote branch remains available and do not create a second commit.

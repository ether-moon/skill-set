---
description: Create or find a pull request from committed changes
argument-hint: "[base branch and PR context]"
allowed-tools: "Edit(//**/.git/skill-set/inputs/pr-body.*/content) Edit(//**/.git/worktrees/*/skill-set/inputs/pr-body.*/content)"
---

Use the `managing-git-workflow` skill's pull-request workflow. Build the PR from `origin/<base>...HEAD`, show dirty files as excluded, and obtain explicit exclusion confirmation when needed. Return an existing PR URL instead of creating a duplicate. The runner may push existing commits required for a new PR but must never create a commit.

---
description: Push existing commits with remote SHA protection
argument-hint: "[remote or branch context]"
allowed-tools: "Bash(${CLAUDE_PLUGIN_ROOT}/bin/skill-set-git:*)"
---

Use the `managing-git-workflow` skill's push workflow. Inspect and record the destination SHA, preview the publication, then push existing commits only. Dirty files remain excluded. Do not create a commit or reconcile diverged history automatically.

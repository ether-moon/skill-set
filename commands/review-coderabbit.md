---
description: Process CodeRabbit AI feedback from current PR with severity-based classification and mandatory completion workflow
---

Use the `reviewing-coderabbit-feedback` skill to process CodeRabbit AI review comments:

1. Classify feedback by severity (CRITICAL/MAJOR/MINOR)
2. Auto-apply CRITICAL and MAJOR issues
3. Report MINOR as recommendations only
4. Complete mandatory workflow: commit → report → PR comment

**Task:** Review and apply CodeRabbit feedback from current PR with guaranteed workflow completion

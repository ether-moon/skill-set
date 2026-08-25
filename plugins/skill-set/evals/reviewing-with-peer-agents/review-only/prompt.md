Ask an independent LLM to review the current branch against `main`.

Intent: Preserve the greeting's user-visible behavior while identifying accidental implementation debris.

Decision record: Keep the formatter synchronous and dependency-free. Adding diagnostics or logging was explicitly rejected because it is outside this review. There are no unresolved product decisions.

This is review-only: report verified findings, but do not edit files, invoke a resolution workflow, commit, push, or publish comments.

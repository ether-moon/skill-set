Ask an independent LLM to review the current branch against `main`.

Intent: Preserve the greeting's user-visible behavior while removing accidental implementation debris.

Decision record: Keep the formatter synchronous and dependency-free. Adding diagnostics or logging was explicitly rejected because it is outside this cleanup. There are no unresolved product decisions.

Verify the reviewer's findings, immediately resolve anything that has exactly one objectively correct fix, and brief me on anything that requires a decision. Do not commit, push, or publish comments.

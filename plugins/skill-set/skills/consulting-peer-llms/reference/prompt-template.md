# Review Prompt Template

This template is based on the superpowers:code-reviewer prompt structure, adapted for peer LLM consultation.

## Core Principle

**CLIs share the same repository.** They can run `git diff`, `git log`, and read any file. The prompt should tell them *what to do* and *why*, not *what the code looks like*.

## Prompt Tiers

### Tier 1: Bare (no context — e.g., slash command without arguments)

Use when there is no conversation context and no user-specified focus. Do NOT read git log or files to fabricate a summary.

```markdown
# Code Review Request

Review all changes on the current branch compared to `origin/main` (or `origin/master`).
Use `git diff origin/main...HEAD` to see the full diff and read files directly from the repository.
```

### Tier 2: With context (conversation provides what was implemented)

Use when the conversation naturally provides context about what was built.

```markdown
# Code Review Request

Review all changes on the current branch compared to `origin/main` (or `origin/master`).
Use `git diff origin/main...HEAD` to see the full diff and read files directly from the repository.

## Context

{1-2 sentence summary of what was implemented and why — from conversation only}
```

### Tier 3: With review focus (user specifies areas)

Use when user explicitly asks to focus on specific files or aspects.

```markdown
# Code Review Request

Review all changes on the current branch compared to `origin/main` (or `origin/master`).
Use `git diff origin/main...HEAD` to see the full diff and read files directly from the repository.

{If context available from conversation:}
## Context

{1-2 sentence summary}

## Review Focus

{User's specific requirements, passed as-is}
```

## Template Variables

| Variable | Source | Required |
|----------|--------|----------|
| `{context}` | Conversation (never gathered from git/files) | No — omit if unknown |
| `{review_focus}` | User's explicit request | No — omit if not specified |

## What Belongs in the Prompt

| Include | Exclude |
|---------|---------|
| 1-2 sentence intent summary | File contents or code snippets |
| Instruction to use git | Git diffs, stats, or logs |
| User's review focus (if any) | File lists or directory trees |
| | SHAs or commit messages |
| | Path references (unless user explicitly asked) |
| | Change summaries or descriptions |

**Key rule**: If a CLI can discover it by running a command in the repo, don't put it in the prompt.

## Examples

### Bare (slash command, no arguments)

```markdown
# Code Review Request

Review all changes on the current branch compared to `origin/main`.
Use `git diff origin/main...HEAD` to see the full diff and read files directly from the repository.
```

### With conversation context

```markdown
# Code Review Request

Review all changes on the current branch compared to `origin/main`.
Use `git diff origin/main...HEAD` to see the full diff and read files directly from the repository.

## Context

Added JWT token-based authentication replacing the previous session system.
```

### With focus

```markdown
# Code Review Request

Review all changes on the current branch compared to `origin/main`.
Use `git diff origin/main...HEAD` to see the full diff and read files directly from the repository.

## Review Focus

Check thread safety of the connection pool under concurrent access.
```

## Anti-Patterns

These are common mistakes — if you catch yourself doing any of these, stop and simplify:

| Anti-Pattern | Fix |
|---|---|
| Running `git diff` and embedding output in prompt | Just tell CLI to run `git diff` itself |
| Reading files and pasting contents into prompt | Tell CLI to read files if needed |
| Listing changed files in the prompt | CLI discovers this via `git diff --name-only` |
| Including commit messages or SHAs | CLI runs `git log` itself |
| Adding paths "for context" when not explicitly requested | Omit — CLI explores the repo |

## Best Practices

1. **Start minimal**: Use Tier 1 by default, add focus only when user asks
2. **Summarize intent, not implementation**: "Added auth" not "Added login.js, auth.js, middleware.js..."
3. **Trust the CLI**: It has full repo access — don't hand-hold
4. **Keep under 500 tokens**: Shorter prompts produce more focused reviews

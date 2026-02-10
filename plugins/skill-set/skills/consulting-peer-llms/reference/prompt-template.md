# Review Prompt Template

This template is based on the superpowers:code-reviewer prompt structure, adapted for peer LLM consultation.

## Full Template

```markdown
# Code Review Request

## What Was Implemented

{Extract from conversation context}

Examples:
- "Implemented user authentication with JWT tokens"
- "Refactored database connection pooling logic"
- "Added error handling for API timeout scenarios"
- "Created new React component for data visualization"

## Requirements/Plan

{User's stated requirements or problem to solve}

Examples:
- "User requested secure login system with session management"
- "Need to improve database performance under high load"
- "Fix production bug where timeouts crash the service"
- "Display real-time metrics in dashboard UI"

## Changes

Please compare the current branch against `origin/main` (or `origin/master`) using git to review all changes.
Use commands like `git diff origin/main...HEAD` to see the full diff.

{If user provided specific review requirements, add:}
## Review Focus

{User's specific requirements, passed as-is}
{End conditional section}

```

## Template Variables

When generating the prompt, replace these placeholders:

| Variable | Source | Example |
|----------|--------|---------|
| `{what_implemented}` | Conversation analysis | "Implemented JWT authentication" |
| `{requirements}` | User's stated goal | "User requested secure login system" |

**Note:** Do not include SHAs, file lists, diffs, or change summaries — peer CLIs use git directly to compare the current branch against `origin/main`.


## Context Optimization

### What to Include in Prompt

**Essential:**
- Clear statement of what was built
- Why it was built (requirements)
- Instruction to compare current branch against `origin/main` (CLIs query git directly)

**Useful:**
- Programming language and framework
- Key design decisions from conversation
- Constraints mentioned by user

### What to Exclude from Prompt

- File lists, git diff output, change summaries (CLIs query these themselves)
- Entire file contents
- Complete conversation history
- Unrelated project context

**Rule of thumb:** Keep total prompt under 4000 tokens for best results.


## Example: Complete Prompt

```markdown
# Code Review Request

## What Was Implemented

Implemented JWT token-based user authentication system. Includes login, logout, and token refresh functionality.

## Requirements/Plan

User requested the following:
- Secure login/logout functionality
- JWT token-based session management
- Automatic token refresh
- Permission validation middleware

## Changes

Please compare the current branch against `origin/main` (or `origin/master`) using git to review all changes.
Use commands like `git diff origin/main...HEAD` to see the full diff.
```

## Best Practices

1. **Keep it focused**: Don't include everything, just what's relevant
2. **Be specific**: Implementation details and requirements, not raw diffs
3. **Structure clearly**: Use markdown headers for easy parsing
4. **Prioritize context**: Implementation details > historical context
5. **Optimize length**: Target 2000-4000 tokens for best results

# Review Prompt Template

This template is based on the superpowers:code-reviewer prompt structure, adapted for peer LLM consultation.

## Full Template

```markdown
# Code Review Request

{If project context specifies output language, add this section:}
## Output Language

Please provide your review in {LANGUAGE} (e.g., Korean, Japanese, English).
{End conditional section}

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

Base SHA: {base_sha}
Current SHA: {current_sha}

## Changes

**Instruction for Peer Agent:**
Please check the changes between `{base_sha}` and `{current_sha}` using your git tools (e.g., `git diff {base_sha}..{current_sha}` or `git status`).
The user has not provided the file list explicitly, assuming you can access the repository.

## Review Focus Areas

Please evaluate this work across these dimensions:

### 1. Code Quality
- **Separation of concerns**: Are responsibilities properly divided?
- **Error handling completeness**: All failure modes covered?
- **Edge cases and validation**: Input validation, boundary conditions?
- **Code clarity and maintainability**: Easy to understand and modify?
- **DRY principle**: Unnecessary duplication?

### 2. Architecture & Design
- **Design soundness**: Does the approach fit the requirements?
- **Scalability considerations**: Will it handle growth?
- **Potential performance issues**: Bottlenecks or inefficiencies?
- **Security implications**: Authentication, authorization, injection risks?
- **Coupling and cohesion**: Appropriate dependencies?

### 3. Testing & Reliability
- **Test coverage adequacy**: Critical paths tested?
- **Edge case handling**: Unusual inputs, failure scenarios?
- **Integration considerations**: Works with existing systems?
- **Error recovery**: Graceful degradation?

### 4. Requirements Alignment
- **All requirements met**: Nothing missing from the plan?
- **Scope creep**: Implemented extra features not requested?
- **Breaking changes**: Backward compatibility maintained?
- **Documentation**: Changes documented appropriately?

## Please Provide

Structure your review in these categories:

### 1. Critical Issues
Issues requiring immediate attention:
- Bugs that break functionality
- Security vulnerabilities
- Data loss or corruption risks
- Broken integrations

**Format:**
- Issue: {Clear description}
- Impact: {What breaks and why it matters}
- Location: {file:line references}
- Recommendation: {How to fix}

### 2. Important Issues
Issues to address before merge:
- Design problems affecting maintainability
- Incomplete feature implementation
- Weak error handling
- Missing test coverage for critical paths
- Performance problems

**Format:** Same as Critical Issues

### 3. Minor Issues
Nice-to-have improvements:
- Style inconsistencies
- Optimization opportunities
- Documentation enhancements
- Refactoring suggestions

**Format:** Briefer, can be listed

### 4. Strengths
What was done well:
- Good design decisions
- Thorough error handling
- Clear code organization
- Comprehensive tests

## Requirements

- **Be specific**: Always include file:line references
- **Explain impact**: Why does this matter?
- **Provide solutions**: How to fix, not just what's wrong
- **Be actionable**: Concrete steps, not vague advice
```

## Template Variables

When generating the prompt, replace these placeholders:

| Variable | Source | Example |
|----------|--------|---------|
| `{LANGUAGE}` | Project context / conversation language | `Korean`, `Japanese`, `English` |
| `{base_sha}` | `git rev-parse HEAD~1` or `origin/main` | `a3f2b91` |
| `{current_sha}` | `git rev-parse HEAD` | `d8e4c72` |
| `{modified_files}` | `git diff --name-only` | `src/auth.js\ntest/auth.test.js` |
| `{change_summary}` | `git diff --stat` | `2 files changed, 45 insertions(+), 12 deletions(-)` |
| `{what_implemented}` | Conversation analysis | "Implemented JWT authentication" |
| `{requirements}` | User's stated goal | "User requested secure login system" |
| `{key_changes}` | Git diff analysis | "Added AuthService class..." |

### Determining Output Language

**Check project context in this order:**

1. **Explicit language setting**: Check project config files (`.claude.md`, `AGENTS.md`, etc.)
2. **Conversation language**: Analyze recent user messages
   - Korean text detected → Use Korean
   - Japanese text detected → Use Japanese
   - Otherwise → Omit language specification (defaults to English)

**Detection logic:**
```bash
# Check if recent conversation contains non-ASCII characters
if echo "$RECENT_MESSAGES" | grep -q '[가-힣]'; then
    LANGUAGE="Korean"
elif echo "$RECENT_MESSAGES" | grep -q '[ぁ-ゔァ-ヴー々〆〤]'; then
    LANGUAGE="Japanese"
else
    # Omit language specification (English default)
    LANGUAGE=""
fi
```

## Context Optimization

### What to Include

**Essential:**
- Clear statement of what was built
- Why it was built (requirements)
- Which files changed
- High-level summary of changes

**Useful:**
- Programming language and framework
- Key design decisions from conversation
- Constraints mentioned by user

### What to Exclude

**Too verbose:**
- Full git diff output
- Entire file contents
- Complete conversation history
- Unrelated project context

**Rule of thumb:** Keep total prompt under 4000 tokens for best results.

## Language Adaptation

### When to Specify Output Language

**Include language specification when:**
- User is communicating in non-English language (Korean, Japanese, etc.)
- Project has explicit language preference in config
- Commit messages are in specific language

**Omit language specification when:**
- Conversation is entirely in English
- No clear language preference detected
- Mixed language usage (defaults to English)

### Examples by Language

**Korean project:**
```markdown
# Code Review Request

## Output Language

Please provide your review in Korean.

## What Was Implemented

Implemented JWT token-based user authentication system.

## Requirements/Plan

User requested a secure login system with session management.
```

## Customization Points

You can adjust the prompt based on review type:

**Security-focused review:**
```markdown
## Additional Focus: Security Review

Please pay special attention to:
- Authentication and authorization flaws
- SQL injection, XSS, CSRF vulnerabilities
- Secrets management
- Input validation and sanitization
```

**Performance review:**
```markdown
## Additional Focus: Performance Review

Please evaluate:
- Algorithmic complexity
- Database query efficiency
- Caching opportunities
- Memory usage patterns
```

**Architecture review:**
```markdown
## Additional Focus: Architecture Review

Please assess:
- Design pattern appropriateness
- Component boundaries and responsibilities
- Dependency management
- Extensibility and maintainability
```

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

Base SHA: a3f2b91
Current SHA: d8e4c72

### Modified Files
src/auth/AuthService.js
src/auth/TokenManager.js
src/middleware/authMiddleware.js
test/auth/AuthService.test.js

### Change Summary
 src/auth/AuthService.js         | 89 ++++++++++++++++++++++++++++++++++++++
 src/auth/TokenManager.js        | 56 ++++++++++++++++++++++++
 src/middleware/authMiddleware.js| 34 +++++++++++++++
 test/auth/AuthService.test.js   | 67 ++++++++++++++++++++++++++++
 4 files changed, 246 insertions(+)

### Key Changes
- Created AuthService class with login/logout/refresh methods
- Implemented TokenManager for JWT generation and validation
- Added authentication middleware for Express routes
- Comprehensive test coverage for AuthService

## Review Focus Areas

Please evaluate this work across these dimensions:

### 1. Code Quality
- Separation of concerns
- Error handling completeness
- Edge cases and validation
- Code clarity and maintainability

### 2. Architecture & Design
- Design soundness for the requirements
- Scalability considerations
- Potential performance issues
- Security implications

### 3. Testing & Reliability
- Test coverage adequacy
- Edge case handling
- Integration considerations

### 4. Requirements Alignment
- All requirements met?
- Scope creep or missing features?
- Breaking changes documented?

## Please Provide

1. **Critical Issues**: Bugs, security risks, broken functionality
2. **Important Issues**: Design problems, incomplete features, error handling gaps
3. **Minor Issues**: Style improvements, optimization opportunities
4. **Strengths**: What was done well

Be specific with file references (file:line) and explain impact.

## Output Constraints

Please strictly adhere to the following:
1. **NO Thinking Process**: Do not include any internal thinking, reasoning traces, or `<thinking>` tags in the output.
2. **NO System Logs**: Do not include any tool usage logs, MCP notifications, or system debug information.
3. **Clean Output**: Provide ONLY the requested review content in the specified format.
```

## Best Practices

1. **Keep it focused**: Don't include everything, just what's relevant
2. **Be specific**: File lists and summaries, not full content
3. **Structure clearly**: Use markdown headers for easy parsing
4. **Prioritize context**: Implementation details > historical context
5. **Optimize length**: Target 2000-4000 tokens for best results

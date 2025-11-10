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

Base SHA: {base_sha}
Current SHA: {current_sha}

### Modified Files
{Output from: git diff --name-only $BASE..$CURRENT}

### Change Summary
{Output from: git diff --stat $BASE..$CURRENT}

### Key Changes
{Human-readable summary of major changes}

Examples:
- Added new AuthService class with token validation
- Refactored DatabasePool to use connection reuse
- Wrapped all API calls with timeout error handlers
- Created MetricsChart component with real-time updates

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
| `{base_sha}` | `git rev-parse HEAD~1` or `origin/main` | `a3f2b91` |
| `{current_sha}` | `git rev-parse HEAD` | `d8e4c72` |
| `{modified_files}` | `git diff --name-only` | `src/auth.js\ntest/auth.test.js` |
| `{change_summary}` | `git diff --stat` | `2 files changed, 45 insertions(+), 12 deletions(-)` |
| `{what_implemented}` | Conversation analysis | "Implemented JWT authentication" |
| `{requirements}` | User's stated goal | "User requested secure login system" |
| `{key_changes}` | Git diff analysis | "Added AuthService class..." |

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

If the conversation is primarily in Korean:
- Keep section headers in English (standardized structure)
- Write descriptions in Korean
- CLI output (git) stays in original format

Example:
```markdown
## What Was Implemented

JWT 토큰 기반 사용자 인증 시스템을 구현했습니다.

## Requirements/Plan

사용자가 세션 관리가 포함된 안전한 로그인 시스템을 요청했습니다.
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

JWT 토큰 기반의 사용자 인증 시스템을 구현했습니다. 로그인, 로그아웃, 토큰 갱신 기능을 포함합니다.

## Requirements/Plan

사용자가 다음을 요청했습니다:
- 안전한 로그인/로그아웃 기능
- JWT 토큰 기반 세션 관리
- 자동 토큰 갱신
- 권한 검증 미들웨어

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
```

## Best Practices

1. **Keep it focused**: Don't include everything, just what's relevant
2. **Be specific**: File lists and summaries, not full content
3. **Structure clearly**: Use markdown headers for easy parsing
4. **Prioritize context**: Implementation details > historical context
5. **Optimize length**: Target 2000-4000 tokens for best results

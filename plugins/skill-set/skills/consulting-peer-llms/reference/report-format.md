# Report Format

Every consultation produces three outputs in sequence:

1. **Raw responses** - Each CLI's original, unmodified output
2. **Synthesized final report** - Analyzed and consolidated

## Example: Authentication Implementation

### Raw Gemini Response

```markdown
## Critical Issues

1. **JWT Secret Hardcoded** (src/auth/TokenManager.js:15)
   - Impact: Anyone with code access can forge tokens
   - Fix: Move to environment variable

2. **No Token Expiration Validation** (src/auth/TokenManager.js:45)
   - Impact: Expired tokens remain valid indefinitely

## Important Issues

1. **Missing Rate Limiting** (src/auth/AuthService.js:30)
2. **Incomplete Error Messages** (src/auth/AuthService.js:52)

## Strengths
- Good separation of concerns
- Comprehensive test coverage for happy paths
```

### Raw Codex Response

```markdown
## Critical

**Hardcoded Secret** - src/auth/TokenManager.js:15
**Token Expiration Not Checked** - src/auth/TokenManager.js:45

## Important

**Missing Refresh Token Logic** - only access tokens implemented
**Weak Password Validation** - no complexity requirements

## Good Points
- Error handling is consistent
- Code is well-commented
```

### Synthesized Final Report

```markdown
# Final Assessment

## Critical Issues

### JWT Secret Hardcoded
**Location:** src/auth/TokenManager.js:15
**Impact:** Anyone with repository access can forge authentication tokens
**Fix:** Move to `process.env.JWT_SECRET`

### Token Expiration Not Validated
**Location:** src/auth/TokenManager.js:45
**Impact:** Expired tokens remain valid indefinitely
**Fix:** Add expiration check in verify method

## Architecture & Design Concerns

### Missing Refresh Token Flow
Users must log in again when access tokens expire.
**Recommendation:** Short-lived access tokens + long-lived refresh tokens.

### Rate Limiting Missing
Login endpoint vulnerable to brute force attacks.

## What's Working Well
- Clean separation between AuthService and TokenManager
- Consistent error handling with async/await
- Good test coverage for major functions

## Actionable Recommendations
1. **Immediate:** Fix hardcoded secret + expiration validation
2. **Before Merge:** Refresh token flow + rate limiting
3. **Future:** 2FA, account lockout, audit logging
```

## Anti-Patterns

### Don't: Compare which CLI said what
```markdown
Gemini found SQL injection, Codex also found it.
Gemini rated it 10/10, Codex rated 9/10. Both agree.
```
This is **comparison**, not synthesis.

### Do: Synthesize into one assessment
```markdown
### SQL Injection Vulnerability
**Location:** src/db/QueryBuilder.js:45
**Impact:** Attacker can execute arbitrary SQL
**Fix:** Use parameterized queries
```

### Don't: Include everything both CLIs said
A dump of every minor point is **noise**.

### Do: Filter for what matters
Group by severity, skip irrelevant suggestions, consolidate duplicates.

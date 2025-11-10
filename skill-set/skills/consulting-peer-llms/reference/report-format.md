# Report Format Examples

Examples of how to synthesize peer LLM feedback into actionable final reports.

## Output Structure

Every consultation produces three outputs in sequence:

1. **Raw Gemini Response** - Original, unmodified
2. **Raw Codex Response** - Original, unmodified
3. **Synthesized Final Report** - Analyzed and consolidated

## Example 1: Authentication Implementation

### Stage 1: Raw Gemini Response

```markdown
# Gemini Review

## Critical Issues

1. **JWT Secret Hardcoded** (src/auth/TokenManager.js:15)
   - The JWT secret "mysecret123" is hardcoded in the source
   - Impact: Anyone with code access can forge tokens
   - Fix: Move to environment variable

2. **No Token Expiration Validation** (src/auth/TokenManager.js:45)
   - Token validation doesn't check expiration time
   - Impact: Expired tokens remain valid indefinitely
   - Fix: Add expiration check in verify method

## Important Issues

1. **Missing Rate Limiting** (src/auth/AuthService.js:30)
   - Login endpoint has no rate limiting
   - Impact: Vulnerable to brute force attacks
   - Fix: Add rate limiting middleware

2. **Incomplete Error Messages** (src/auth/AuthService.js:52)
   - Generic "Login failed" doesn't distinguish invalid user vs wrong password
   - Impact: Poor user experience, harder to debug
   - Fix: Return specific error codes

## Strengths

- Good separation of concerns between AuthService and TokenManager
- Comprehensive test coverage for happy paths
- Clean async/await usage throughout
```

### Stage 2: Raw Codex Response

```markdown
# Codex Review

## Security Concerns

**Critical: Hardcoded Secret**
- File: src/auth/TokenManager.js, line 15
- Issue: JWT secret is in source code
- Risk: Token forgery if repository is compromised
- Solution: Use process.env.JWT_SECRET

**Critical: Token Expiration Not Checked**
- File: src/auth/TokenManager.js, line 45
- Issue: verify() doesn't validate exp claim
- Risk: Old tokens never invalidate
- Solution: Check exp claim against current time

## Design Issues

**Missing: Refresh Token Logic**
- Current implementation only has access tokens
- Users will be logged out when tokens expire
- Consider implementing refresh token flow

**Weak: Password Validation**
- src/auth/AuthService.js:25 uses simple bcrypt compare
- No password complexity requirements
- Add strength validation

## Code Quality

**Good:**
- Error handling is consistent
- Type checking is thorough
- Code is well-commented

**Improve:**
- Extract magic numbers (token expiry duration)
- Add JSDoc comments for public methods
```

### Stage 3: Synthesized Final Report

```markdown
# Final Assessment

## Critical Issues Requiring Immediate Attention

### 1. JWT Secret Hardcoded
**Location:** src/auth/TokenManager.js:15
**Issue:** JWT secret "mysecret123" is hardcoded in source code
**Impact:** Anyone with repository access can forge authentication tokens, completely bypassing security
**Recommendation:**
```javascript
// Change from:
const SECRET = "mysecret123";

// To:
const SECRET = process.env.JWT_SECRET;
if (!SECRET) {
  throw new Error("JWT_SECRET environment variable is required");
}
```

### 2. Token Expiration Not Validated
**Location:** src/auth/TokenManager.js:45
**Issue:** The verify() method doesn't check if token has expired
**Impact:** Expired tokens remain valid indefinitely, defeating the purpose of expiration
**Recommendation:**
```javascript
verify(token) {
  const payload = jwt.verify(token, SECRET);

  // Add this check:
  if (payload.exp && payload.exp < Date.now() / 1000) {
    throw new Error("Token has expired");
  }

  return payload;
}
```

## Architecture & Design Concerns

### Missing Refresh Token Flow
The current implementation only uses access tokens. When they expire, users must log in again.

**Impact:** Poor user experience with frequent re-authentication

**Recommendation:** Implement refresh token pattern:
- Short-lived access tokens (15 minutes)
- Long-lived refresh tokens (7 days)
- Refresh endpoint to get new access token

This is a **before merge** priority.

### Rate Limiting Missing
Login endpoint (src/auth/AuthService.js:30) has no rate limiting.

**Impact:** Vulnerable to brute force password attacks

**Recommendation:** Add express-rate-limit middleware:
```javascript
const rateLimit = require("express-rate-limit");

const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5 // limit each IP to 5 requests per window
});

app.post("/login", loginLimiter, authController.login);
```

## Code Quality Issues

### Password Validation Weak
Currently only checks if password matches hash, no strength requirements.

**Impact:** Users can set weak passwords like "123456"

**Recommendation:** Add validation before hashing:
```javascript
function validatePasswordStrength(password) {
  if (password.length < 8) return false;
  if (!/[A-Z]/.test(password)) return false;
  if (!/[a-z]/.test(password)) return false;
  if (!/[0-9]/.test(password)) return false;
  return true;
}
```

### Magic Numbers Present
Token expiry duration (3600) is hardcoded in multiple places.

**Recommendation:** Extract to configuration constant:
```javascript
const TOKEN_EXPIRY_SECONDS = 3600; // 1 hour
```

### Error Messages Too Generic
Login failures return generic "Login failed" message.

**Impact:** Harder to debug and poor UX

**Recommendation:** Use specific error codes:
```javascript
// Instead of generic message, return:
{ error: "INVALID_CREDENTIALS", code: 401 }
{ error: "USER_NOT_FOUND", code: 404 }
{ error: "ACCOUNT_LOCKED", code: 423 }
```

## Testing Gaps

Tests cover happy paths well but missing:
- Expired token handling test
- Rate limiting bypass attempts
- Concurrent login attempts
- Invalid token format handling

**Recommendation:** Add test cases for these scenarios.

## What's Working Well

1. **Clean Architecture:** Good separation between AuthService (business logic) and TokenManager (token operations)
2. **Consistent Error Handling:** Try-catch blocks used appropriately throughout
3. **Good Test Coverage:** All major functions have test cases
4. **Modern JavaScript:** Proper async/await usage, no callback hell

## Actionable Recommendations

### 1. Immediate (Before Next Commit)
- [ ] Move JWT secret to environment variable
- [ ] Add token expiration validation
- [ ] Add rate limiting to login endpoint

### 2. Before Merge
- [ ] Implement refresh token flow
- [ ] Add password strength validation
- [ ] Improve error message specificity
- [ ] Add missing test cases

### 3. Future Enhancement
- [ ] Consider adding 2FA support
- [ ] Implement account lockout after N failed attempts
- [ ] Add audit logging for authentication events
- [ ] Extract configuration to separate file

## Summary

The authentication implementation has **solid architecture and code quality**, but contains **two critical security issues** that must be fixed immediately:
1. Hardcoded JWT secret
2. Missing token expiration validation

Additionally, the lack of rate limiting and refresh token flow should be addressed before merging to production. The code is well-structured and maintainable, making these improvements straightforward to implement.

**Overall Assessment:** Good foundation with critical security gaps that are easily fixable.

**Next Steps:** Fix critical issues first, then address rate limiting and refresh tokens before merge.
```

---

## Example 2: Database Refactoring

### Stage 1: Raw Gemini Response

```markdown
# Gemini Review

## Important Issues

1. **Connection Pool Not Released** (src/db/QueryBuilder.js:89)
   - Connections acquired but not always released
   - Can lead to connection pool exhaustion
   - Add proper finally block

2. **SQL Injection Risk** (src/db/QueryBuilder.js:45)
   - String concatenation used for WHERE clause
   - Use parameterized queries instead

## Minor Issues

- QueryBuilder could use builder pattern more consistently
- Some methods are too long (>50 lines)

## Strengths

- Significant performance improvement over old implementation
- Good use of connection pooling
- Clear method names
```

### Stage 2: Raw Codex Response

```markdown
# Codex Review

## Critical

**SQL Injection Vulnerability**
- QueryBuilder.where() concatenates user input directly
- File: src/db/QueryBuilder.js:45
- Fix: Use placeholders and bind parameters

## Important

**Resource Leak**
- Connections not released on error path
- File: src/db/QueryBuilder.js:89
- Memory leak will occur under heavy load

**No Transaction Support**
- Can't rollback failed multi-query operations
- Consider adding transaction wrapper

## Good Points

- Much faster than previous ORM
- Code is readable
```

### Stage 3: Synthesized Final Report

```markdown
# Final Assessment

## Critical Issues Requiring Immediate Attention

### SQL Injection Vulnerability
**Location:** src/db/QueryBuilder.js:45
**Issue:** WHERE clause uses string concatenation with user input
**Impact:** Attacker can execute arbitrary SQL, potentially dropping tables or stealing data

**Current vulnerable code:**
```javascript
where(field, value) {
  this.whereClause += ` WHERE ${field} = '${value}'`;  // DANGEROUS
  return this;
}
```

**Fix immediately:**
```javascript
where(field, value) {
  this.whereClause += ` WHERE ${field} = ?`;
  this.params.push(value);
  return this;
}
```

This is a **blocker** - do not merge until fixed.

## Architecture & Design Concerns

### Connection Pool Leaks
**Location:** src/db/QueryBuilder.js:89
**Issue:** Connections acquired but not released on error paths
**Impact:** Under load, connection pool will exhaust and application will hang

**Recommendation:**
```javascript
async execute() {
  const conn = await pool.getConnection();
  try {
    const result = await conn.query(this.sql, this.params);
    return result;
  } finally {
    conn.release();  // Always release, even on error
  }
}
```

### Missing Transaction Support
**Issue:** No way to rollback related operations if one fails
**Impact:** Partial updates can leave database in inconsistent state

**Recommendation:** Add transaction helper:
```javascript
async transaction(callback) {
  const conn = await pool.getConnection();
  await conn.beginTransaction();
  try {
    const result = await callback(conn);
    await conn.commit();
    return result;
  } catch (error) {
    await conn.rollback();
    throw error;
  } finally {
    conn.release();
  }
}
```

## Code Quality Issues

### Methods Too Long
Several methods exceed 50 lines (query(), join(), etc.)

**Impact:** Harder to understand and test

**Recommendation:** Extract sub-operations into private methods

### Inconsistent Builder Pattern
Some methods return `this`, others return `Promise<Result>`

**Impact:** Confusing API, breaks method chaining

**Recommendation:** Separate building (returns this) from execution (returns Promise):
```javascript
// Building - returns this
qb.select('*').where('id', 5).orderBy('name')

// Execution - returns Promise
await qb.execute()
```

## What's Working Well

1. **Performance:** Significant improvement over previous ORM (3x faster in benchmarks)
2. **Readability:** Method names are clear and self-documenting
3. **Connection Pooling:** Good use of pool for concurrent requests

## Actionable Recommendations

### 1. Immediate (Critical - Block Merge)
- [ ] Fix SQL injection vulnerability with parameterized queries
- [ ] Fix connection leak with finally block

### 2. Before Merge (Important)
- [ ] Add transaction support
- [ ] Refactor long methods
- [ ] Make builder pattern consistent

### 3. Future Enhancement
- [ ] Add query result caching
- [ ] Support for database replicas
- [ ] Query performance logging

## Summary

This refactoring delivers **excellent performance improvements** but contains a **critical SQL injection vulnerability** that absolutely must be fixed before merge. The connection leak is also serious and will cause production issues under load.

The good news: both critical issues have straightforward fixes that won't impact performance.

**Overall Assessment:** High-value refactoring with fixable critical security flaw.

**Next Steps:**
1. Fix SQL injection (30 minutes)
2. Fix connection leak (15 minutes)
3. Add transaction support (2 hours)
4. Then ready to merge
```

---

## Synthesis Principles

When creating the final report, follow these principles:

### 1. Consolidate Duplicates

Both LLMs mentioned "hardcoded JWT secret"?
→ **One entry** in Critical Issues, not two

### 2. Filter for Validity

LLM mentioned "consider adding GraphQL"?
→ **Skip** if not relevant to current requirements

### 3. Prioritize by Impact

Don't organize by "which LLM said it"
→ Organize by **actual severity and impact**

### 4. Make Actionable

LLM said "improve error handling"?
→ Convert to **specific code examples** of what to change

### 5. Remove Noise

LLM included style nitpicks?
→ **Group briefly** or skip if not important

### 6. Add Context

Both LLMs mentioned transactions?
→ **Explain why it matters** for this specific use case

### 7. Provide Code Examples

Don't just describe the problem
→ **Show current code and fixed code side by side**

### 8. Time Estimates

Add rough estimates for fixes
→ Helps user prioritize ("30 minutes" vs "2 days")

---

## Anti-Patterns to Avoid

### ❌ Don't: Compare Which LLM Said What

```markdown
## Critical Issues

Gemini found SQL injection, Codex also found it.
Gemini rated it 10/10 severity, Codex rated 9/10.
Both agree this is critical.
```

This is **comparison**, not synthesis.

### ✅ Do: Synthesize the Finding

```markdown
## Critical Issues

### SQL Injection Vulnerability
**Location:** src/db/QueryBuilder.js:45
**Issue:** User input concatenated directly into SQL
**Impact:** Attacker can execute arbitrary SQL
**Fix:** Use parameterized queries (see example above)
```

This is **synthesis** - one authoritative assessment.

---

### ❌ Don't: Include Everything Both LLMs Said

```markdown
## Minor Issues

Gemini: Consider adding TypeScript
Codex: Maybe use async generators
Gemini: Could optimize loop performance
Codex: Extract magic number on line 42
Gemini: Add more comments
...
```

This is **noise**.

### ✅ Do: Filter for What Actually Matters

```markdown
## Code Quality Issues

### Magic Numbers
Extract hardcoded values to constants (line 42, 67, 89)

### Performance
Loop optimization possible in hot path (QueryBuilder.execute)
```

This is **signal**.

---

## Report Length Guidelines

- **Raw responses:** As long as CLIs produce
- **Final report:** 500-1500 words typical
  - Critical: 200-400 words
  - Important: 200-400 words
  - Quality/Testing: 100-300 words
  - Strengths: 50-100 words
  - Recommendations: 100-200 words
  - Summary: 100-150 words

**Too short (<300 words):** Probably missing important details
**Too long (>2000 words):** Probably including too much noise

---

## Tone and Style

- **Direct and specific:** "Fix X in file:line" not "Consider improving"
- **Action-oriented:** "Add try-finally block" not "Error handling could be better"
- **Evidence-based:** "This causes pool exhaustion" not "This might be bad"
- **Respectful:** "Missing validation" not "Rookie mistake"
- **Helpful:** Include code examples, not just descriptions

---

## When One CLI Fails

If only one CLI succeeds:

```markdown
# Final Assessment

**Note:** Codex CLI was unavailable. This assessment is based solely on Gemini's review.

## Critical Issues
...
```

If both fail:

```markdown
# Final Assessment

**Error:** Both peer LLM CLIs failed to execute.

Please check:
- CLI installation: `which gemini codex`
- CLI functionality: `gemini "test"`
- API authentication if required

Cannot proceed with peer review until CLIs are functional.
```

---

## Customization by Review Type

### Security Review

Emphasize security sections more:
```markdown
## Security Issues (Critical)
## Security Issues (Important)
## Architecture & Design
## Code Quality
```

### Performance Review

Emphasize performance sections:
```markdown
## Performance Issues (Critical)
## Performance Issues (Important)
## Architecture & Design
## Code Quality
```

### Architecture Review

Emphasize design sections:
```markdown
## Design Issues
## Architecture Concerns
## Scalability
## Code Organization
```

Adapt report structure to what user cares about most.

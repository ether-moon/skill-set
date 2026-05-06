#!/usr/bin/env bash
# Initializes a git fixture repo with a main branch and a feature branch.
# Branch name uses ticket prefix PROJ-123 to test ticket extraction.
set -euo pipefail

git init -q -b main
git config user.email "fixture@example.com"
git config user.name "Fixture User"
git config commit.gpgsign false

# Main: seed with one commit
mkdir -p src
cat > src/index.js <<'EOF'
console.log('hello');
EOF
git add -A
git commit -q -m "chore: initial scaffold"

# Feature branch with PROJ-123 prefix
git checkout -q -b PROJ-123-rate-limiter

cat > src/rate-limiter.js <<'EOF'
class RateLimiter {
  constructor(limit, windowMs) {
    this.limit = limit;
    this.windowMs = windowMs;
    this.hits = new Map();
  }
  check(key) {
    const now = Date.now();
    const arr = this.hits.get(key) || [];
    const fresh = arr.filter(t => now - t < this.windowMs);
    if (fresh.length >= this.limit) return false;
    fresh.push(now);
    this.hits.set(key, fresh);
    return true;
  }
}
module.exports = RateLimiter;
EOF
git add -A
git commit -q -m "feat(rate-limit): add token-bucket rate limiter"

cat > src/rate-limiter.test.js <<'EOF'
const RateLimiter = require('./rate-limiter');
test('allows under limit', () => {
  const r = new RateLimiter(2, 1000);
  expect(r.check('k')).toBe(true);
  expect(r.check('k')).toBe(true);
  expect(r.check('k')).toBe(false);
});
EOF
git add -A
git commit -q -m "test(rate-limit): cover allow/deny boundary"

cat > src/middleware.js <<'EOF'
const RateLimiter = require('./rate-limiter');
const limiter = new RateLimiter(100, 60000);
module.exports = (req, res, next) => {
  if (!limiter.check(req.ip)) return res.status(429).end();
  next();
};
EOF
git add -A
git commit -q -m "feat(middleware): wire rate limiter into HTTP path"

echo "Feature branch ready: PROJ-123-rate-limiter (3 commits ahead of main)"
git log --oneline main..HEAD

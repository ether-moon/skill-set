#!/usr/bin/env bash
# Initializes a git fixture repo at the current working directory.
# Run this from inside an empty work directory before invoking the skill.
set -euo pipefail

if [[ -d .git ]] || [[ -n "$(ls -A 2>/dev/null)" ]]; then
  echo "Error: run setup.sh in an empty directory (no .git, no existing files)." >&2
  exit 1
fi

git init -q -b main
git config user.email "fixture@example.com"
git config user.name "Fixture User"
git config commit.gpgsign false

# Seed history: 5 conventional-commit-style commits in English.
mkdir -p src
cat > src/parser.js <<'EOF'
function parse(input) {
  return JSON.parse(input);
}
module.exports = { parse };
EOF
git add -A
git commit -q -m "feat: initial parser implementation"

cat > src/parser.test.js <<'EOF'
const { parse } = require('./parser');
test('parses object', () => {
  expect(parse('{"a":1}')).toEqual({ a: 1 });
});
EOF
git add -A
git commit -q -m "test: add parser unit tests"

echo "console.log('cli');" > src/cli.js
git add -A
git commit -q -m "feat(cli): add command-line entry point"

echo "// Note: see README" >> src/parser.js
git add -A
git commit -q -m "docs(parser): add README pointer comment"

echo "exports.version = '0.1.0';" >> src/parser.js
git add -A
git commit -q -m "chore(parser): expose version constant"

# Now stage a substantive new change (the change to be committed by the skill):
# Add nested array support to the parser. This is the "feature" the user staged.
cat > src/parser.js <<'EOF'
function parse(input) {
  const value = JSON.parse(input);
  return normalizeNestedArrays(value);
}

function normalizeNestedArrays(v) {
  if (Array.isArray(v)) {
    return v.map(normalizeNestedArrays);
  }
  if (v && typeof v === 'object') {
    const out = {};
    for (const k of Object.keys(v)) {
      out[k] = normalizeNestedArrays(v[k]);
    }
    return out;
  }
  return v;
}

module.exports = { parse, normalizeNestedArrays, version: '0.1.0' };
EOF
git add -A

echo "Fixture ready. Staged change: nested array support added to parser."
git status --short

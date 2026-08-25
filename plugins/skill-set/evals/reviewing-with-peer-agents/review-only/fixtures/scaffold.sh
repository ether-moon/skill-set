#!/usr/bin/env bash

set -euo pipefail

fixture_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

git init -q -b main
git config user.name 'Skill Eval'
git config user.email 'skill-eval@example.com'
git config commit.gpgsign false

mkdir -p src

cat >src/greeting.ts <<'EOF'
export function greet(name: string): string {
  return `Hello, ${name}!`;
}
EOF

git add src/greeting.ts
git commit -q -m 'feat: add greeting formatter'
git switch -q -c feature/greeting-review

cp "$fixture_dir/src/greeting.ts" src/greeting.ts

git add src/greeting.ts
git commit -q -m 'refactor: prepare greeting diagnostics'

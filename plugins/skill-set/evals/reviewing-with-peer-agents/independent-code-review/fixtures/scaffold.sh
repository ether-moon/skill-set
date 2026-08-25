#!/usr/bin/env bash

set -euo pipefail

fixture_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

git init -q -b main
git config user.name 'Skill Eval'
git config user.email 'skill-eval@example.com'
git config commit.gpgsign false

mkdir -p src test

cat >src/greeting.ts <<'EOF'
export function greet(name: string): string {
  return `Hello, ${name}!`;
}
EOF

cat >test/verify.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if grep -Fq 'debugLabel' src/greeting.ts; then
  echo 'unused debugLabel remains' >&2
  exit 1
fi
EOF
chmod +x test/verify.sh

git add src/greeting.ts test/verify.sh
git commit -q -m 'feat: add greeting formatter'
git switch -q -c feature/greeting-cleanup

cp "$fixture_dir/src/greeting.ts" src/greeting.ts

git add src/greeting.ts
git commit -q -m 'refactor: prepare greeting diagnostics'

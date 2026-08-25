#!/usr/bin/env bash

set -euo pipefail

fixture_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

git init -q -b main
git config user.name 'Skill Eval'
git config user.email 'skill-eval@example.com'
git config commit.gpgsign false

mkdir -p src test

cat >src/permissions.ts <<'EOF'
export type User = { role: "admin" | "member" | "guest" };

export function canManageBilling(user: User): boolean {
  return user.role === "admin";
}
EOF

cat >test/permissions.test.ts <<'EOF'
import { canManageBilling } from "../src/permissions";

if (!canManageBilling({ role: "admin" })) throw new Error("admin denied");
if (canManageBilling({ role: "member" })) throw new Error("member allowed");
if (canManageBilling({ role: "guest" })) throw new Error("guest allowed");
EOF

git add src/permissions.ts test/permissions.test.ts
git commit -q -m 'feat: add billing permission check'
git switch -q -c feature/billing-permissions

cp "$fixture_dir/src/permissions.ts" src/permissions.ts

git add src/permissions.ts
git commit -q -m 'refactor: simplify billing permission check'

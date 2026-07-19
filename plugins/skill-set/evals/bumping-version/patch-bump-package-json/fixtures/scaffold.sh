#!/usr/bin/env bash
set -euo pipefail
fixture_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cp -R "$fixture_dir/." .
rm -f scaffold.sh

git init -q .
git checkout -q -b main
git config user.name "Skill Eval"
git config user.email "skill-eval@example.com"
git add -- package.json CHANGELOG.md recent-commits.txt
git commit -q -m "chore: bump version to 1.0.0"
while IFS= read -r commit_line; do
  [[ -n "$commit_line" ]] || continue
  commit_subject=${commit_line#* }
  git commit -q --allow-empty -m "$commit_subject"
done <recent-commits.txt
git init -q --bare .eval-origin.git
git remote add origin "$PWD/.eval-origin.git"
git push -q -u origin main
git config core.hooksPath "$PWD/.eval-hooks"
mkdir -p outputs

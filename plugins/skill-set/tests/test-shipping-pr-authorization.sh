#!/usr/bin/env bash

set -euo pipefail

test_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
plugin_dir=$(cd -- "$test_dir/.." && pwd)
skill_file=$plugin_dir/skills/shipping-pr/SKILL.md
resolver_file=$plugin_dir/agents/resolving-pr-blockers.md
# shellcheck source=plugins/skill-set/tests/test-helper.sh
source "$test_dir/test-helper.sh"

assert_file "$skill_file"
assert_file "$resolver_file"

grep -Fq 'A shipping request authorizes the initial branch commit and push' "$skill_file" || \
  fail 'shipping request must authorize the initial commit and push'
grep -Fq 'Do not ask for separate confirmation before committing or pushing.' "$skill_file" || \
  fail 'shipping must not request redundant commit or push confirmation'
grep -Fq 'commit --all' "$skill_file" || \
  fail 'shipping must define the automatic all-change commit operation'
grep -Fq 'push --expected-remote-sha' "$skill_file" || \
  fail 'shipping must define automatic publication of existing commits'
grep -Fq 'Edit(//**/.git/skill-set/inputs/commit-message.*/content)' "$skill_file" || \
  fail 'shipping must allow writing a managed commit message without a new permission prompt'
grep -Fq 'Edit(//**/.git/skill-set/inputs/pr-body.*/content)' "$skill_file" || \
  fail 'shipping must allow writing a managed PR body without a new permission prompt'

if grep -Fq 'Never auto-commit working-tree changes for shipping.' "$skill_file"; then
  fail 'shipping still forbids the requested automatic initial commit'
fi
if grep -Fq 'require explicit exclusion confirmation' "$skill_file"; then
  fail 'shipping still requires a redundant dirty-file confirmation'
fi

grep -Fq 'Do not request separate user approval for those commits or for runner publication.' \
  "$resolver_file" || \
  fail 'resolver must treat the shipping capability contract as sufficient authorization'

printf 'PASS: shipping-pr authorization contract\n'

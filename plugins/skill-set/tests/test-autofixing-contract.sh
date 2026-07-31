#!/usr/bin/env bash

set -euo pipefail

test_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
plugin_dir=$(cd -- "$test_dir/.." && pwd)
# shellcheck source=plugins/skill-set/tests/test-helper.sh
source "$test_dir/test-helper.sh"

skill=$plugin_dir/skills/autofixing-and-escalating/SKILL.md
resolution=$plugin_dir/skills/autofixing-and-escalating/reference/resolution.md

grep -Eq 'resolve-authorized' "$skill"
if grep -Eq 'review-only' "$skill" "$resolution"; then
  fail 'review-only mode must not exist'
fi
grep -Eq 'Default to `edit: true`' "$skill"
grep -Eq 'pause before any mutation' "$skill"
grep -Eq 'after every required decision is complete, automatically apply all queued OBVIOUS fixes' "$skill"
grep -Eq 'without another confirmation' "$skill"
grep -Eq 'without another confirmation' "$resolution"
for capability in edit commit push comment; do
  grep -Eq "${capability}" "$skill" || fail "missing capability: $capability"
done
for boundary in 'public API' 'data or schema' 'dependencies' 'security policy' 'destructive' 'multiple valid'; do
  grep -Eqi "$boundary" "$skill" || fail "missing ALWAYS AMBIGUOUS boundary: $boundary"
done
if grep -Eq 'more than ~?[0-9]+ lines|parallel (via )?subagents|publication decision|decides? (whether|when) to publish' "$skill" "$resolution"; then
  fail 'classification skill must not use line thresholds, dispatch subagents, or own publication'
fi
grep -Eq 'caller owns orchestration' "$resolution"
grep -Eq 'caller owns publication' "$resolution"

printf 'PASS: autofixing capability contract\n'

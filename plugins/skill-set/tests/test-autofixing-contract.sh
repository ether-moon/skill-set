#!/usr/bin/env bash

set -euo pipefail

test_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
plugin_dir=$(cd -- "$test_dir/.." && pwd)
# shellcheck source=plugins/skill-set/tests/test-helper.sh
source "$test_dir/test-helper.sh"

skill=$plugin_dir/skills/autofixing-and-escalating/SKILL.md
resolution=$plugin_dir/skills/autofixing-and-escalating/reference/resolution.md

grep -Eq 'review-only' "$skill"
grep -Eq 'resolve-authorized' "$skill"
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

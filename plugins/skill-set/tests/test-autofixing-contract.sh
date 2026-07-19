#!/usr/bin/env bash

set -euo pipefail

test_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
plugin_dir=$(cd -- "$test_dir/.." && pwd)
# shellcheck source=plugins/skill-set/tests/test-helper.sh
source "$test_dir/test-helper.sh"

skill=$plugin_dir/skills/autofixing-and-escalating/SKILL.md
resolution=$plugin_dir/skills/autofixing-and-escalating/reference/resolution.md

rg -q 'review-only' "$skill"
rg -q 'resolve-authorized' "$skill"
for capability in edit commit push comment; do
  rg -q "${capability}" "$skill" || fail "missing capability: $capability"
done
for boundary in 'public API' 'data or schema' 'dependencies' 'security policy' 'destructive' 'multiple valid'; do
  rg -qi "$boundary" "$skill" || fail "missing ALWAYS AMBIGUOUS boundary: $boundary"
done
if rg -q 'more than ~?[0-9]+ lines|parallel (via )?subagents|publication decision|decides? (whether|when) to publish' "$skill" "$resolution"; then
  fail 'classification skill must not use line thresholds, dispatch subagents, or own publication'
fi
rg -q 'caller owns orchestration' "$resolution"
rg -q 'caller owns publication' "$resolution"

printf 'PASS: autofixing capability contract\n'

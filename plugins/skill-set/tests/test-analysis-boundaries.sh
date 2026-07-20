#!/usr/bin/env bash

set -euo pipefail

test_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
plugin_dir=$(cd -- "$test_dir/.." && pwd)
# shellcheck source=plugins/skill-set/tests/test-helper.sh
source "$test_dir/test-helper.sh"

zoom=$plugin_dir/skills/zooming-out-on-code/SKILL.md
architecture=$plugin_dir/skills/improving-architecture/SKILL.md
grill=$plugin_dir/skills/grilling-plans/SKILL.md
directives=$plugin_dir/skills/guarding-agent-directives/SKILL.md

for heading in Responsibility Callers Dependencies Siblings Unknowns; do
  grep -Eq "^##? ${heading}$|\\*\\*${heading}:?\\*\\*" "$zoom" || fail "zoom output misses $heading"
done
grep -Eqi 'read-only' "$zoom"
grep -Eqi 'do not.*(recommend|refactor|modify)' "$zoom"

for field in Files Evidence Problem 'Proposed seam' 'Locality gain' 'Leverage gain' 'Test impact' Risks; do
  grep -Eq "$field" "$architecture" || fail "architecture candidate misses $field"
done
grep -Eqi 'ranked candidates' "$architecture"
grep -Eqi 'read-only' "$architecture"
grep -Eqi 'stop after.*candidates' "$architecture"

for ledger in Confirmed Rejected Unresolved; do
  grep -Eq "$ledger" "$grill" || fail "grilling ledger misses $ledger"
done
grep -Eqi 'one question per turn' "$grill"
grep -Eqi '(default|maximum).*5|5.*user questions' "$grill"
grep -Eqi 'stop.*Unresolved|Unresolved.*stop' "$grill"

grep -Eq 'verify-addition' "$directives"
grep -Eq 'audit-existing' "$directives"
grep -Eq 'Q5.*Correct location' "$directives"
grep -Eqi 'keep.*revise.*remove' "$directives"
grep -Eqi 'audit-existing.*read-only|read-only.*audit-existing' "$directives"
grep -Eqi 'user override' "$directives"
grep -Eqi 'exact diff' "$directives"

active_paths=(
  "$plugin_dir/skills/zooming-out-on-code"
  "$plugin_dir/skills/improving-architecture"
  "$plugin_dir/skills/grilling-plans"
  "$plugin_dir/skills/guarding-agent-directives"
  "$plugin_dir/commands/code/zoom-out.md"
  "$plugin_dir/commands/plan/grill.md"
)
if grep -Ern 'superpowers:|`simplify`|handoff to|hand off to|auto(matically)? (invoke|run|write)' "${active_paths[@]}"; then
  fail 'analysis/directive skills retain an unbundled dependency or automatic handoff'
fi
assert_equals '1' "$(find "$plugin_dir/evals/zooming-out-on-code" -type f -name case.yaml -exec grep -El '^  - functional$' {} + | wc -l | tr -d ' ')" 'zoom functional eval count'
assert_equals '2' "$(find "$plugin_dir/evals/improving-architecture" -type f -name case.yaml -exec grep -El '^  - functional$' {} + | wc -l | tr -d ' ')" 'architecture functional eval count'
assert_equals '2' "$(find "$plugin_dir/evals/grilling-plans" -type f -name case.yaml -exec grep -El '^  - functional$' {} + | wc -l | tr -d ' ')" 'grilling functional eval count'
assert_equals '4' "$(find "$plugin_dir/evals/guarding-agent-directives" -type f -name case.yaml -exec grep -El '^  - functional$' {} + | wc -l | tr -d ' ')" 'directive functional eval count'

for read_only_case in \
  "$plugin_dir/evals/zooming-out-on-code/order-validation-map" \
  "$plugin_dir/evals/improving-architecture/deletion-test-on-thin-wrapper" \
  "$plugin_dir/evals/improving-architecture/shallow-validators-cluster" \
  "$plugin_dir/evals/grilling-plans/early-stop-ledger" \
  "$plugin_dir/evals/guarding-agent-directives/audit-existing"; do
  if grep -Erq -- '- Write|- Edit|outputs/' "$read_only_case"; then
    fail "read-only eval grants or requests mutation: $read_only_case"
  fi
done

for confirmation_case in accept-specific-rule reject-vague-rule; do
  if grep -Eq -- '- Write|- Edit' "$plugin_dir/evals/guarding-agent-directives/$confirmation_case/case.yaml"; then
    fail "pre-confirmation directive eval grants mutation: $confirmation_case"
  fi
done

printf 'PASS: analysis and directive boundaries\n'

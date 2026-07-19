#!/usr/bin/env bash

set -euo pipefail

test_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
plugin_dir=$(cd -- "$test_dir/.." && pwd)
repo_dir=$(cd -- "$plugin_dir/../.." && pwd)
# shellcheck source=plugins/skill-set/tests/test-helper.sh
source "$test_dir/test-helper.sh"

skill=$plugin_dir/skills/driving-with-tests/SKILL.md
tdd=$plugin_dir/skills/driving-with-tests/reference/tdd.md

[[ ! -d $plugin_dir/skills/developing-test-first ]] || fail 'developing-test-first must be integrated and removed'
assert_file "$tdd"
rg -q 'Orient.*Red/Green/Refactor.*Probe.*Guard' "$skill"
rg -qi 'new behavior.*Red/Green/Refactor' "$skill"
rg -qi 'bug fix.*Red/Green/Refactor' "$skill"
rg -qi 'pure refactor.*characterization.*green baseline' "$skill"
rg -qi 'documentation.*configuration.*generated code.*analysis.*test-only' "$skill"
rg -qi 'alternative validation' "$skill"
rg -qi 'existing implementation|user changes' "$skill"
rg -qi 'regression or characterization test' "$skill"
rg -qi 'project directive|user.*strict TDD' "$skill"
rg -q 'one test.*one implementation.*one cycle' "$tdd"
rg -q 'Verify RED' "$tdd"
rg -q 'Minimal GREEN' "$tdd"
rg -q 'Refactor only while green' "$tdd"

if rg -n 'developing-test-first' \
  "$repo_dir/README.md" "$repo_dir/AGENTS.md" \
  "$plugin_dir/.claude-plugin" "$plugin_dir/commands" "$plugin_dir/agents" "$plugin_dir/skills" \
  "$plugin_dir/tests/expected-inventory.json"; then
  fail 'active plugin content still references developing-test-first'
fi
assert_equals '11' "$(jq -r '.skills' "$plugin_dir/tests/expected-inventory.json")" 'integrated skill count'
assert_equals '7' "$(rg -l '^  - functional$' "$plugin_dir/evals/driving-with-tests" -g case.yaml | wc -l | tr -d ' ')" 'testing mode eval count'

printf 'PASS: integrated testing skill\n'

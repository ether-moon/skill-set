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
grep -Eq 'Orient.*Red/Green/Refactor.*Probe.*Guard' "$skill"
grep -Eqi 'new behavior.*Red/Green/Refactor' "$skill"
grep -Eqi 'bug fix.*Red/Green/Refactor' "$skill"
grep -Eqi 'pure refactor.*characterization.*green baseline' "$skill"
grep -Eqi 'documentation.*configuration.*generated code.*analysis.*test-only' "$skill"
grep -Eqi 'alternative validation' "$skill"
grep -Eqi 'existing implementation|user changes' "$skill"
grep -Eqi 'regression or characterization test' "$skill"
grep -Eqi 'project directive|user.*strict TDD' "$skill"
grep -Eq 'one test.*one implementation.*one cycle' "$tdd"
grep -Eq 'Verify RED' "$tdd"
grep -Eq 'Minimal GREEN' "$tdd"
grep -Eq 'Refactor only while green' "$tdd"

if grep -Ern 'developing-test-first' \
  "$repo_dir/README.md" "$repo_dir/AGENTS.md" \
  "$plugin_dir/.claude-plugin" "$plugin_dir/commands" "$plugin_dir/agents" "$plugin_dir/skills" \
  "$plugin_dir/tests/expected-inventory.json"; then
  fail 'active plugin content still references developing-test-first'
fi
assert_equals '11' "$(jq -r '.skills' "$plugin_dir/tests/expected-inventory.json")" 'integrated skill count'
assert_equals '7' "$(find "$plugin_dir/evals/driving-with-tests" -type f -name case.yaml -exec grep -El '^  - functional$' {} + | wc -l | tr -d ' ')" 'testing mode eval count'

printf 'PASS: integrated testing skill\n'

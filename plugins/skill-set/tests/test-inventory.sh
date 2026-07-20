#!/usr/bin/env bash

set -euo pipefail

test_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
plugin_dir=$(cd -- "$test_dir/.." && pwd)
repo_dir=$(cd -- "$plugin_dir/../.." && pwd)
# shellcheck source=plugins/skill-set/tests/test-helper.sh
source "$test_dir/test-helper.sh"

inventory=$plugin_dir/scripts/generate-inventory
assert_executable "$inventory"
"$inventory" --check

skill_count=$(find "$plugin_dir/skills" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
agent_count=$(find "$plugin_dir/agents" -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')
command_count=$(find "$plugin_dir/commands" -type f -name '*.md' | wc -l | tr -d ' ')
expected_inventory=$test_dir/expected-inventory.json
assert_file "$expected_inventory"

assert_equals "$(jq -r '.skills' "$expected_inventory")" "$skill_count" "skill count"
assert_equals "$(jq -r '.agents' "$expected_inventory")" "$agent_count" "agent count"
assert_equals "$(jq -r '.commands' "$expected_inventory")" "$command_count" "legacy command count"

grep -Eq '<!-- skill-set-inventory:start -->' "$repo_dir/README.md"
grep -Eq '<!-- skill-set-inventory:start -->' "$repo_dir/AGENTS.md"
if grep -Eq '^## Project Structure$|^### Project Structure$' "$repo_dir/README.md" "$repo_dir/AGENTS.md"; then
  fail "manual component trees must not duplicate the generated inventory"
fi
while IFS= read -r layout_path; do
  [[ -e $plugin_dir/$layout_path ]] || fail "generated layout contains missing path: $layout_path"
done < <(awk '/^[├└]── / { print $2 }' "$repo_dir/README.md")
printf 'PASS: inventory\n'

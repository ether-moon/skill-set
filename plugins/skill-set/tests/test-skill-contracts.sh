#!/usr/bin/env bash

set -euo pipefail

test_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
plugin_dir=$(cd -- "$test_dir/.." && pwd)
# shellcheck source=plugins/skill-set/tests/test-helper.sh
source "$test_dir/test-helper.sh"

skill_count=0
while IFS= read -r skill_file; do
  skill_count=$((skill_count + 1))
  skill_dir=$(dirname "$skill_file")
  expected_name=$(basename "$skill_dir")
  line_count=$(wc -l <"$skill_file" | tr -d ' ')
  ((line_count <= 200)) || fail "SKILL.md exceeds the focused 200-line budget: $skill_file ($line_count)"

  name=$(awk '
    NR == 1 && $0 == "---" { frontmatter = 1; next }
    frontmatter && $0 == "---" { exit }
    frontmatter && /^name: / { sub(/^name: /, ""); print; exit }
  ' "$skill_file")
  description=$(awk '
    NR == 1 && $0 == "---" { frontmatter = 1; next }
    frontmatter && $0 == "---" { exit }
    frontmatter && /^description: / { sub(/^description: /, ""); print; exit }
  ' "$skill_file")
  description=${description#\"}
  description=${description%\"}

  assert_equals "$expected_name" "$name" "skill directory/frontmatter name"
  [[ $name =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || fail "invalid kebab-case skill name: $name"
  ((${#name} <= 64)) || fail "skill name exceeds 64 characters: $name"
  [[ -n $description ]] || fail "skill description is empty: $skill_file"
  ((${#description} <= 1024)) || fail "skill description exceeds 1024 characters: $skill_file"
  [[ $description == *'. Use '* || $description == *'. Use when '* ]] || \
    fail "skill description must state what it does and when to use it: $skill_file"
  [[ $description != *'<'* && $description != *'>'* ]] || \
    fail "skill description contains XML-like brackets: $skill_file"

  [[ ! -f $skill_dir/README.md ]] || fail "skill bundles an unnecessary README.md: $skill_dir"
done < <(find "$plugin_dir/skills" -mindepth 2 -maxdepth 2 -type f -name SKILL.md | sort)

assert_equals "$(jq -r '.skills' "$plugin_dir/tests/expected-inventory.json")" "$skill_count" \
  'skill contract inventory count'

"$plugin_dir/scripts/validate-references" >/dev/null

printf 'PASS: skill authoring contracts\n'

#!/usr/bin/env bash

set -euo pipefail

test_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
plugin_dir=$(cd -- "$test_dir/.." && pwd)
# shellcheck source=plugins/skill-set/tests/test-helper.sh
source "$test_dir/test-helper.sh"

catalog=$plugin_dir/evals/trigger-cases.json
generator=$plugin_dir/scripts/generate-trigger-evals

assert_file "$catalog"
assert_executable "$generator"

skill_count=$(find "$plugin_dir/skills" -mindepth 2 -maxdepth 2 -type f -name SKILL.md | wc -l | tr -d ' ')
assert_equals "$skill_count" "$(jq 'keys | length' "$catalog")" 'trigger catalog skill count'

jq -e '
  all(.[];
    (.positive | type) == "array" and
    (.negative | type) == "array" and
    (.positive | length) >= 8 and (.positive | length) <= 10 and
    (.negative | length) >= 8 and (.negative | length) <= 10)
' "$catalog" >/dev/null

jq -e '
  ."shipping-pr".positive[2] |
  contains("Ship PR 42 end to end") and
  contains("do not stop until the PR is clean") and
  contains("terminal stop")
' "$catalog" >/dev/null

"$generator" --check
"$plugin_dir/scripts/validate-evals" --require-trigger-matrix >/dev/null

positive=$(find "$plugin_dir/evals" -type f -name case.yaml -exec rg -l '^  - trigger-positive$' {} + | wc -l | tr -d ' ')
negative=$(find "$plugin_dir/evals" -type f -name case.yaml -exec rg -l '^  - trigger-negative$' {} + | wc -l | tr -d ' ')
assert_equals "$((skill_count * 8))" "$positive" 'positive trigger case count'
assert_equals "$((skill_count * 8))" "$negative" 'negative trigger case count'

while IFS= read -r case_file; do
  if rg -q '^  - trigger-positive$' "$case_file"; then
    rg -q '^    tool: Skill$' "$case_file" || fail "positive trigger lacks Skill grader: $case_file"
    rg -q '^    min: 1$' "$case_file" || fail "positive trigger lacks minimum call count: $case_file"
    if awk '
      /^  - type: tool_used$/ { in_tool = 1; next }
      in_tool && /^    arm:/ { found = 1 }
      in_tool && /^  - / { exit }
      END { exit found ? 0 : 1 }
    ' "$case_file"; then
      fail "positive Skill grader must stay display-only in the ablation arm: $case_file"
    fi
  else
    rg -q '^    min: 0$' "$case_file" || fail "negative trigger lacks zero minimum: $case_file"
    rg -q '^    max: 0$' "$case_file" || fail "negative trigger lacks zero maximum: $case_file"
    rg -q '^    arm: both$' "$case_file" || fail "negative trigger is not enforced in both arms: $case_file"
  fi
  rg -q '^  - type: llm$' "$case_file" || fail "trigger case lacks an outcome grader: $case_file"
done < <(find "$plugin_dir/evals" -type f -name case.yaml \( -path '*/trigger-positive-*/*' -o -path '*/trigger-negative-*/*' \) | sort)

printf 'PASS: generated trigger eval matrix\n'

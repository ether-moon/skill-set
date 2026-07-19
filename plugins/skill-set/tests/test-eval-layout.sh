#!/usr/bin/env bash

set -euo pipefail

test_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
plugin_dir=$(cd -- "$test_dir/.." && pwd)
# shellcheck source=plugins/skill-set/tests/test-helper.sh
source "$test_dir/test-helper.sh"

if find "$plugin_dir/skills" -path '*/evals/evals.json' -print -quit | grep -q .; then
  fail "legacy per-skill evals.json files remain"
fi
[[ ! -e "$plugin_dir/skills/EVALS.md" ]] || fail "legacy skills/EVALS.md remains"

case_count=$(find "$plugin_dir/evals" -type f \( -name case.yaml -o -name prompt.md \) -exec dirname {} \; 2>/dev/null | sort -u | wc -l | tr -d ' ')
((case_count >= 10)) || fail "expected at least 10 migrated eval cases, got $case_count"

while IFS= read -r case_dir; do
  if [[ -f "$case_dir/case.yaml" ]]; then
    rg -q '^schema_version: "1\.[01]"$' "$case_dir/case.yaml" || fail "missing supported schema_version: $case_dir/case.yaml"
    scaffold_script=$(awk -F ': ' '$1 == "  scaffold_script" { print $2; exit }' "$case_dir/case.yaml")
    if [[ -n $scaffold_script ]]; then
      sandbox=$(mktemp -d "${TMPDIR:-/tmp}/skill-set-scaffold-test.XXXXXX")
      (cd "$sandbox" && "$case_dir/$scaffold_script" >/dev/null)
      find "$sandbox" -mindepth 1 -print -quit | grep -q . || fail "scaffold produced no fixture: $case_dir"
      rm -rf "$sandbox"
    fi
  else
    find "$case_dir/graders" -type f -name '*.md' -print -quit | grep -q . || fail "missing grader: $case_dir"
  fi
done < <(find "$plugin_dir/evals" -type f \( -name case.yaml -o -name prompt.md \) -exec dirname {} \; | sort -u)

runner=$plugin_dir/scripts/run-evals
assert_executable "$runner"
"$runner" --help | rg -q '95c1b2a'
eval_plan=$(/bin/bash "$runner" --plan --runs 1 --model test-model --judge-model test-judge --max-cost-usd 1 --tag trigger-positive)
printf '%s\n' "$eval_plan" | rg -q -- '--allow-tools Bash Write Edit Skill'
printf '%s\n' "$eval_plan" | rg -q -- '--output-dir [^ ]+/candidate'
if printf '%s\n' "$eval_plan" | rg -q -- '--output-dir --'; then
  fail 'run-evals left --output-dir without its value'
fi

validator=$plugin_dir/scripts/validate-evals
assert_executable "$validator"
"$validator"
printf 'PASS: eval layout\n'

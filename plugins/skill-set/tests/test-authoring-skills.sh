#!/usr/bin/env bash

set -euo pipefail

test_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
plugin_dir=$(cd -- "$test_dir/.." && pwd)
# shellcheck source=plugins/skill-set/tests/test-helper.sh
source "$test_dir/test-helper.sh"

creating_dir=$plugin_dir/skills/creating-skills
prose_dir=$plugin_dir/skills/writing-clear-prose
creating=$creating_dir/SKILL.md
prose=$prose_dir/SKILL.md

if rg -qi 'writing-clear-prose|writing clear prose' "$creating_dir" "$plugin_dir/evals/creating-skills" 2>/dev/null; then
  fail 'creating-skills must be independent from writing-clear-prose'
fi
if rg -qi 'creating-skills|creating skills' "$prose_dir" "$plugin_dir/evals/writing-clear-prose" 2>/dev/null; then
  fail 'writing-clear-prose must be independent from creating-skills'
fi

for lifecycle_term in 'use cases' triggers structure scripts evaluation benchmark iterate; do
  rg -qi "$lifecycle_term" "$creating" || fail "creating-skills misses lifecycle term: $lifecycle_term"
done
rg -qi 'new skill.*existing skill|existing skill.*new skill' "$creating"
rg -qi 'optional.*skill-creator|skill-creator.*optional' "$creating"
rg -qi 'unavailable|not installed|absent' "$creating"
rg -q 'case.yaml' "$creating_dir/reference/evaluation.md"
rg -q -- '--ablation with-without' "$creating_dir/reference/evaluation.md"
rg -qi 'independent.*(judge|grader)|(judge|grader).*independent' "$creating_dir/reference/evaluation.md"
if rg -q 'evals\.json|without_skill|with_skill/outputs' "$creating_dir"; then
  fail 'creating-skills retains a legacy custom eval layout'
fi

for near_miss in 'skill authoring' 'commit and PR messages' 'code comments' 'creative writing' 'everyday conversation'; do
  rg -qi "$near_miss" "$prose" || fail "prose misses negative trigger: $near_miss"
done
for criterion in clarity structure specificity concision 'facts and requirements'; do
  rg -qi "$criterion" "$prose" || fail "prose misses rubric criterion: $criterion"
done
rg -qi 'hard fail.*(invented|unsupported).*(number|claim)|(?:invented|unsupported).*(number|claim).*hard fail' "$prose"
rg -qi 'hard fail.*technical meaning|technical meaning.*hard fail' "$prose"
assert_equals '4' "$(rg -l '^  - functional$' "$plugin_dir/evals/creating-skills" -g case.yaml | wc -l | tr -d ' ')" 'creating-skills functional eval count'
assert_equals '3' "$(rg -l '^  - functional$' "$plugin_dir/evals/writing-clear-prose" -g case.yaml | wc -l | tr -d ' ')" 'writing-clear-prose functional eval count'

for case_dir in \
  "$plugin_dir/evals/creating-skills/new-with-creator" \
  "$plugin_dir/evals/creating-skills/new-without-creator" \
  "$plugin_dir/evals/creating-skills/existing-with-creator" \
  "$plugin_dir/evals/creating-skills/existing-without-creator"; do
  assert_executable "$case_dir/fixtures/scaffold.sh"
  rg -q '^  scaffold_script: fixtures/scaffold\.sh$' "$case_dir/case.yaml"
  rg -q '^  - type: file_exists$' "$case_dir/case.yaml"
  rg -q '^  - type: tool_order$' "$case_dir/case.yaml"
  rg -q 'validate-skill\.sh' "$case_dir/prompt.md" "$case_dir/case.yaml" "$case_dir/graders"
  if rg -qi 'Do not (create|edit) files' "$case_dir"; then
    fail "creating-skills functional eval is explanation-only: $case_dir"
  fi
done

validator_root=$(mktemp -d "${TMPDIR:-/tmp}/skill-set-authoring-validator.XXXXXX")
trap 'rm -rf -- "$validator_root"' EXIT

new_root=$validator_root/new
mkdir -p "$new_root"
(
  cd "$new_root"
  "$plugin_dir/evals/creating-skills/new-without-creator/fixtures/scaffold.sh"
  if ./validate-skill.sh outputs/incident-triage >/dev/null 2>&1; then
    fail 'new-skill validator accepted missing artifacts'
  fi
  mkdir -p outputs/incident-triage \
    outputs/evals/incident-triage/trigger-positive-01 \
    outputs/evals/incident-triage/trigger-negative-01
  cat >outputs/incident-triage/SKILL.md <<'SKILL'
---
name: incident-triage
description: Triages active production alerts. Use when an incident is ongoing; do not use for post-incident status summaries.
---

# Incident Triage
SKILL
  cat >outputs/evals/incident-triage/trigger-positive-01/case.yaml <<'CASE'
schema_version: "1.1"
name: incident-triage-trigger-positive-01
graders:
  - name: selected-incident-triage
CASE
  cat >outputs/evals/incident-triage/trigger-negative-01/case.yaml <<'CASE'
schema_version: "1.1"
name: incident-triage-trigger-negative-01
graders:
  - name: did-not-select-incident-triage
CASE
  ./validate-skill.sh outputs/incident-triage >/dev/null
)

existing_root=$validator_root/existing
mkdir -p "$existing_root"
(
  cd "$existing_root"
  "$plugin_dir/evals/creating-skills/existing-without-creator/fixtures/scaffold.sh"
  if ./validate-skill.sh outputs/skills/deploying-safely >/dev/null 2>&1; then
    fail 'existing-skill validator accepted the known trigger defect'
  fi
  cat >outputs/skills/deploying-safely/SKILL.md <<'SKILL'
---
name: deploying-safely
description: Performs production deployment and rollback workflows. Use when changing a deployed version. Do not use for general release information.
---

# Deploying Safely

Preserve the reversible deployment workflow.
SKILL
  mkdir -p outputs/evals/deploying-safely/trigger-positive-rollback \
    outputs/evals/deploying-safely/trigger-negative-general-release
  cat >outputs/evals/deploying-safely/trigger-positive-rollback/case.yaml <<'CASE'
schema_version: "1.1"
name: deploying-safely-trigger-positive-rollback
graders:
  - name: selected-deploying-safely
CASE
  cat >outputs/evals/deploying-safely/trigger-negative-general-release/case.yaml <<'CASE'
schema_version: "1.1"
name: deploying-safely-trigger-negative-general-release
graders:
  - name: did-not-select-deploying-safely
CASE
  ./validate-skill.sh outputs/skills/deploying-safely >/dev/null
)

printf 'PASS: independent authoring skills\n'

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

if grep -Erqi 'writing-clear-prose|writing clear prose' "$creating_dir" "$plugin_dir/evals/creating-skills" 2>/dev/null; then
  fail 'creating-skills must be independent from writing-clear-prose'
fi
if grep -Erqi 'creating-skills|creating skills' "$prose_dir" "$plugin_dir/evals/writing-clear-prose" 2>/dev/null; then
  fail 'writing-clear-prose must be independent from creating-skills'
fi

for lifecycle_term in 'use cases' triggers structure scripts evaluation benchmark iterate; do
  grep -Eqi "$lifecycle_term" "$creating" || fail "creating-skills misses lifecycle term: $lifecycle_term"
done
grep -Eqi 'new skill.*existing skill|existing skill.*new skill' "$creating"
grep -Eqi 'primary entry point.*skill-creator|skill-creator.*primary entry point' "$creating" || \
  fail 'creating-skills must win the overlapping skill-creator entry point'
grep -Eqi 'delegate.*(complete|full).*(loop|lifecycle).*skill-creator|skill-creator.*delegate.*(complete|full).*(loop|lifecycle)' "$creating" || \
  fail 'creating-skills must delegate the complete supported loop to skill-creator'
grep -Eqi 'final.*(accept|reject|retire)|(accept|reject|retire).*final' "$creating" || \
  fail 'creating-skills must retain the final lifecycle decision'
grep -Eqi 'unavailable|not installed|absent' "$creating"
grep -Eqi 'capability skill' "$creating"
grep -Eqi 'preference skill' "$creating"
grep -Eq 'case.yaml' "$creating_dir/reference/evaluation.md"
for dimension in outcome conformance safety efficiency; do
  grep -Eqi "$dimension" "$creating_dir/reference/evaluation.md" || \
    fail "creating-skills evaluation policy misses dimension: $dimension"
done
grep -Eqi 'grade outcomes.*not paths|outcomes.*rather than paths' "$creating_dir/reference/evaluation.md" || \
  fail 'creating-skills must grade outcomes rather than incidental paths'
grep -Eqi 'independent.*(judge|grader)|(judge|grader).*independent' "$creating_dir/reference/evaluation.md"
claude_cli_pattern='(^|[^[:alnum:]_-])claude[[:space:]]+(plugin|--version)([^[:alnum:]_-]|$)'
# shellcheck disable=SC2016 # Backticks are literal documentation text.
printf '%s\n' '- Run `claude plugin eval` through the host adapter.' | \
  grep -Eq "$claude_cli_pattern" || fail 'Claude CLI boundary matcher misses inline documentation references'
if grep -Erq "$claude_cli_pattern" "$creating_dir"; then
  fail 'creating-skills must not require the Claude CLI for validation or evaluation'
fi
if grep -Erq '\.claude/' "$plugin_dir/evals/creating-skills"; then
  fail 'creating-skills eval fixtures must not require Claude-specific skill discovery'
fi
grep -Eqi 'host-provided.*validator|validator.*host-provided' "$creating_dir/reference/testing.md" || \
  fail 'creating-skills must define a host-neutral validator boundary'
grep -Eqi 'evaluation adapter|eval adapter' "$creating_dir/reference/evaluation.md" || \
  fail 'creating-skills must define a host-neutral evaluation adapter boundary'
grep -Eqi '(fresh|isolated).*(case|arm|trial)|(case|arm|trial).*(fresh|isolated)' "$creating_dir/reference/testing.md" || \
  fail 'creating-skills must isolate every nondeterministic run'
grep -Eqi 'cross-host|supported host' "$creating_dir/reference/testing.md" || \
  fail 'creating-skills must verify every claimed host'
grep -Eqi 'no-skill.*(retire|retirement)|(retire|retirement).*no-skill' "$creating_dir/reference/checklist.md" || \
  fail 'creating-skills must recheck whether a capability skill can retire'
grep -Eqi 'preserve.*(explicitly requested|existing).*name|(explicitly requested|existing).*name.*preserve' \
  "$creating_dir/reference/structure.md" || \
  fail 'creating-skills must preserve valid user-selected and existing skill names'
grep -Eqi 'repository (content|artifacts).*(English)|English.*repository (content|artifacts)' \
  "$creating_dir/reference/structure.md" || \
  fail 'creating-skills must keep repository artifacts in English'
grep -Eqi 'runtime.*user.*language|user.*language.*runtime' \
  "$creating_dir/reference/structure.md" || \
  fail 'creating-skills must separate runtime language from artifact language'
grep -Eqi 'do not copy.*skill wholesale|skill wholesale.*do not copy' \
  "$creating_dir/reference/structure.md" || \
  fail 'creating-skills must prohibit wholesale skill copying'
grep -Eqi 'provenance' "$creating_dir/reference/structure.md" || \
  fail 'creating-skills must require understood provenance for reused material'
grep -Eqi 'untrusted.*frontmatter|frontmatter.*untrusted' \
  "$creating_dir/reference/structure.md" || \
  fail 'creating-skills must treat imported frontmatter as untrusted input'
grep -Eqi 'time-sensitive.*(validation source|update condition)|(validation source|update condition).*time-sensitive' \
  "$creating_dir/reference/structure.md" || \
  fail 'creating-skills must govern time-sensitive content'
grep -Eqi 'content polic(y|ies).*(contract|policy gate)|(contract|policy gate).*content polic(y|ies)' "$creating" || \
  fail 'creating-skills must pass durable content policies through its contract and policy gate'
grep -Eqi 'must not require Claude Code|do not require Claude Code' "$creating" || \
  fail 'creating-skills must explicitly preserve non-Claude execution'
if grep -Erq 'evals\.json|without_skill|with_skill/outputs' "$creating_dir"; then
  fail 'creating-skills retains a legacy custom eval layout'
fi

for near_miss in 'skill authoring' 'commit and PR messages' 'code comments' 'creative writing' 'everyday conversation'; do
  grep -Eqi "$near_miss" "$prose" || fail "prose misses negative trigger: $near_miss"
done
for criterion in clarity structure specificity concision 'facts and requirements'; do
  grep -Eqi "$criterion" "$prose" || fail "prose misses rubric criterion: $criterion"
done
grep -Eqi 'hard fail.*(invented|unsupported).*(number|claim)|(invented|unsupported).*(number|claim).*hard fail' "$prose"
grep -Eqi 'hard fail.*technical meaning|technical meaning.*hard fail' "$prose"
assert_equals '4' "$(find "$plugin_dir/evals/creating-skills" -type f -name case.yaml -exec grep -El '^  - functional$' {} + | wc -l | tr -d ' ')" 'creating-skills functional eval count'
assert_equals '3' "$(find "$plugin_dir/evals/writing-clear-prose" -type f -name case.yaml -exec grep -El '^  - functional$' {} + | wc -l | tr -d ' ')" 'writing-clear-prose functional eval count'

for case_dir in \
  "$plugin_dir/evals/creating-skills/new-with-creator" \
  "$plugin_dir/evals/creating-skills/new-without-creator" \
  "$plugin_dir/evals/creating-skills/existing-with-creator" \
  "$plugin_dir/evals/creating-skills/existing-without-creator"; do
  assert_executable "$case_dir/fixtures/scaffold.sh"
  grep -Eq '^  scaffold_script: fixtures/scaffold\.sh$' "$case_dir/case.yaml"
  grep -Eq '^  - type: file_exists$' "$case_dir/case.yaml"
  grep -Eq '^  - type: tool_order$' "$case_dir/case.yaml"
  grep -Erq 'validate-skill\.sh' "$case_dir/prompt.md" "$case_dir/case.yaml" "$case_dir/graders"
  if grep -Erqi 'Do not (create|edit) files' "$case_dir"; then
    fail "creating-skills functional eval is explanation-only: $case_dir"
  fi
done

for case_dir in \
  "$plugin_dir/evals/creating-skills/new-with-creator" \
  "$plugin_dir/evals/creating-skills/existing-with-creator"; do
  grep -Eqi 'delegate' "$case_dir/prompt.md" || \
    fail "creator-present eval must request delegation: $case_dir"
  grep -Eqi 'skill-creator.*(owns|own).*(authoring|execution|loop)|(authoring|execution|loop).*(owned|owns).*skill-creator' \
    "$case_dir/graders/lifecycle.md" || \
    fail "creator-present eval must give execution ownership to skill-creator: $case_dir"
done

grep -Eqi 'repository artifacts.*English|English.*repository artifacts' \
  "$plugin_dir/evals/creating-skills/new-with-creator/prompt.md" || \
  fail 'creator-present eval must pass the repository artifact language policy'
grep -Eqi 'runtime.*Korean|Korean.*runtime' \
  "$plugin_dir/evals/creating-skills/new-with-creator/graders/lifecycle.md" || \
  fail 'creator-present eval must verify runtime and artifact languages independently'

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

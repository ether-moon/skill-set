#!/usr/bin/env bash

set -euo pipefail

test_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
plugin_dir=$(cd -- "$test_dir/.." && pwd)
# shellcheck source=plugins/skill-set/tests/test-helper.sh
source "$test_dir/test-helper.sh"

creating_dir=$plugin_dir/skills/creating-skills
prose_dir=$plugin_dir/skills/writing-clear-prose
creating=$creating_dir/SKILL.md
eval_budget_planner=$creating_dir/scripts/plan_eval_budget.py
evaluation_policy=$creating_dir/reference/evaluation.md
testing_policy=$creating_dir/reference/testing.md
checklist_policy=$creating_dir/reference/checklist.md
troubleshooting_policy=$creating_dir/reference/troubleshooting.md
prose=$prose_dir/SKILL.md

assert_executable "$eval_budget_planner"
allowed_plan=$(
  "$eval_budget_planner" --cases 4 --json
)
assert_equals '4' "$(jq -r '.total_calls' <<<"$allowed_plan")" 'allowed plan call count'
assert_equals '100000' "$(jq -r '.projected_tokens' <<<"$allowed_plan")" 'allowed plan projected tokens'
assert_equals '4' "$(jq -r '.max_calls' <<<"$allowed_plan")" 'default call limit'
assert_equals '100000' "$(jq -r '.max_total_tokens' <<<"$allowed_plan")" 'default projected-token limit'
assert_equals 'true' "$(jq -r '.allowed' <<<"$allowed_plan")" 'boundary plan allowed'
assert_equals '0' "$(jq -r '.reasons | length' <<<"$allowed_plan")" 'allowed plan reasons'
assert_equals 'false' "$(jq -r '.max_total_tokens_is_runtime_hard_cap' <<<"$allowed_plan")" \
  'projected-token limit semantics'

if blocked_call_plan=$(
  "$eval_budget_planner" --cases 5 --estimated-tokens-per-call 1 --json
); then
  fail 'eval budget planner allowed a plan above the call limit'
else
  assert_equals '2' "$?" 'call-limit block exit code'
fi
assert_equals '5' "$(jq -r '.total_calls' <<<"$blocked_call_plan")" 'blocked call count'
assert_equals 'false' "$(jq -r '.allowed' <<<"$blocked_call_plan")" 'call-limit plan allowed'
jq -e '.reasons | any(contains("model calls"))' <<<"$blocked_call_plan" >/dev/null

if blocked_token_plan=$(
  "$eval_budget_planner" --cases 4 --estimated-tokens-per-call 25001 --json
); then
  fail 'eval budget planner allowed a plan above the projected-token limit'
else
  assert_equals '2' "$?" 'projected-token block exit code'
fi
assert_equals '100004' "$(jq -r '.projected_tokens' <<<"$blocked_token_plan")" \
  'blocked projected tokens'
jq -e '.reasons | any(contains("projected tokens"))' <<<"$blocked_token_plan" >/dev/null

if expanded_plan=$(
  "$eval_budget_planner" --cases 1 --arms 2 --trials 2 --judge-calls 1 --json
); then
  fail 'eval budget planner allowed multiplicative comparison expansion'
else
  assert_equals '2' "$?" 'expanded comparison block exit code'
fi
assert_equals '4' "$(jq -r '.execution_calls' <<<"$expanded_plan")" \
  'expanded comparison execution calls'
assert_equals '5' "$(jq -r '.total_calls' <<<"$expanded_plan")" \
  'expanded comparison total calls'

p95_plan=$(
  "$eval_budget_planner" --cases 4 --estimated-tokens-per-call 20000 --json
)
assert_equals '80000' "$(jq -r '.projected_tokens' <<<"$p95_plan")" 'p95 projected tokens'
assert_equals 'recent_equivalent_trace_p95' "$(jq -r '.estimate_source' <<<"$p95_plan")" \
  'p95 estimate source'

for invalid_plan in \
  '--cases 0' \
  '--cases -1' \
  '--cases 1 --arms 0' \
  '--cases 1 --trials 0' \
  '--cases 1 --judge-calls -1' \
  '--cases 1 --estimated-tokens-per-call 0' \
  '--cases 1 --max-calls 0' \
  '--cases 1 --max-total-tokens 0'; do
  read -r -a invalid_args <<<"$invalid_plan"
  if "$eval_budget_planner" "${invalid_args[@]}" >/dev/null 2>&1; then
    fail "eval budget planner accepted invalid arguments: $invalid_plan"
  else
    assert_equals '2' "$?" "invalid argument exit code: $invalid_plan"
  fi
done

if grep -Erqi 'writing-clear-prose|writing clear prose' "$creating_dir" "$plugin_dir/evals/creating-skills" 2>/dev/null; then
  fail 'creating-skills must be independent from writing-clear-prose'
fi
if grep -Erqi 'creating-skills|creating skills' "$prose_dir" "$plugin_dir/evals/writing-clear-prose" 2>/dev/null; then
  fail 'writing-clear-prose must be independent from creating-skills'
fi

for lifecycle_term in 'use cases' triggers structure scripts evaluation benchmark iteration; do
  grep -Eqi "$lifecycle_term" "$creating" || fail "creating-skills misses lifecycle term: $lifecycle_term"
done
grep -Eqi 'new skill.*existing skill|existing skill.*new skill' "$creating"
grep -Eqi 'primary entry point.*skill-creator|skill-creator.*primary entry point' "$creating" || \
  fail 'creating-skills must win the overlapping skill-creator entry point'
grep -Eqi 'skill-creator.*supported.*(budget|stage)|delegate.*supported.*budget' "$creating" || \
  fail 'creating-skills must delegate supported work inside the evaluation budget'
grep -Eqi 'final.*(accept|reject|retire)|(accept|reject|retire).*final' "$creating" || \
  fail 'creating-skills must retain the final lifecycle decision'
grep -Eqi 'unavailable|not installed|absent' "$creating"
grep -Eqi 'capability skill' "$creating"
grep -Eqi 'preference skill' "$creating"
grep -Eq 'case.yaml' "$evaluation_policy"
for dimension in outcome conformance safety efficiency; do
  grep -Eqi "$dimension" "$evaluation_policy" || \
    fail "creating-skills evaluation policy misses dimension: $dimension"
done
grep -Eqi 'grade outcomes.*not paths|outcomes.*rather than paths' "$evaluation_policy" || \
  fail 'creating-skills must grade outcomes rather than incidental paths'
grep -Eqi 'model grader.*qualit|qualit.*model grader' "$evaluation_policy"
if grep -Eriq '\b(Codex|Claude|Kimi)\b' \
  "$creating" "$evaluation_policy" "$testing_policy" "$checklist_policy" \
  "$troubleshooting_policy" "$eval_budget_planner"; then
  fail 'creating-skills model-eval policy must use product-neutral terms'
fi
grep -Eqi 'host-provided.*validator|validator.*host-provided' "$testing_policy" || \
  fail 'creating-skills must define a host-neutral validator boundary'
grep -Eqi 'evaluation adapter|eval adapter' "$evaluation_policy" || \
  fail 'creating-skills must define a host-neutral evaluation adapter boundary'
grep -Eqi '(fresh|isolated).*(case|arm|trial)|(case|arm|trial).*(fresh|isolated)' "$testing_policy" || \
  fail 'creating-skills must isolate every nondeterministic run'
grep -Eqi 'campaign.*explicit|explicit.*campaign' "$testing_policy" || \
  fail 'creating-skills must require explicit campaign authorization'
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
grep -Eqi 'must not require a vendor-specific|do not require a vendor-specific' "$creating" || \
  fail 'creating-skills must preserve vendor-neutral execution'
if grep -Erq 'evals\.json|without_skill|with_skill/outputs' "$creating_dir"; then
  fail 'creating-skills retains a legacy custom eval layout'
fi

for stage in 'deterministic validation' 'development smoke' 'focused comparison' campaign; do
  grep -Eqi "$stage" "$creating" "$evaluation_policy" || \
    fail "creating-skills misses evaluation stage: $stage"
done
grep -Eqi 'development smoke.*candidate-only|candidate-only.*development smoke' \
  "$creating" "$evaluation_policy" "$checklist_policy" || \
  fail 'development smoke must be candidate-only'
grep -Eqi 'development smoke.*(one trial|single-trial)|(one trial|single-trial).*development smoke' \
  "$creating" "$evaluation_policy" "$checklist_policy" || \
  fail 'development smoke must use one trial'
grep -Eqi 'focused comparison.*(separate|fresh).*(purpose|budget)|(purpose|budget).*(separate|fresh).*focused comparison' \
  "$creating" "$evaluation_policy" "$checklist_policy" || \
  fail 'focused comparisons require a separate purpose and budget'
grep -Eqi 'campaign.*(full suite|repeated trials|cross-model)' "$creating" "$evaluation_policy" || \
  fail 'campaign policy must own expanded evaluation scope'
grep -Eqi 'do not.*(advance|expand).*automatically|no stage expanded automatically' \
  "$creating" "$evaluation_policy" "$checklist_policy" || \
  fail 'evaluation stages must not expand automatically'
grep -Eqi 'reuse.*(earlier|previous).*approval|earlier.*approval.*reused' \
  "$creating" "$evaluation_policy" "$testing_policy" "$checklist_policy" || \
  fail 'evaluation approval must not be reused across stages'
grep -Fq 'execution calls = cases × arms × trials' "$creating"
grep -Fq 'projected tokens = total calls × estimated tokens per call' "$creating"
grep -Eqi '4 total calls.*100,000 projected tokens|4 calls.*100,000 projected tokens' \
  "$creating" "$evaluation_policy"
grep -Eqi 'max-total-tokens.*not a runtime hard cap' "$creating" "$evaluation_policy" \
  "$troubleshooting_policy"
grep -Eqi 'provider-specific adapters' "$creating"
grep -Eqi 'token-debit state machines' "$creating"
grep -Eqi 'execution-history databases' "$creating"
grep -Eqi 'automatic retries' "$creating"
grep -Eqi 'automatic iterations' "$creating"
for efficient_rule in 'one regression risk' 'full policy' 'file existence' 'merge expectations' \
  'genuinely qualitative' 'one batched model-grader' 'duplicates an existing deterministic test' \
  'rerun only affected cases'; do
  grep -Eqi "$efficient_rule" "$testing_policy" || \
    fail "creating-skills misses token-efficient case rule: $efficient_rule"
done
if grep -Eriq 'at least three|blanket.*three|rerun the (full )?suite automatically|then rerun the suite' \
  "$creating" "$evaluation_policy" "$testing_policy" "$checklist_policy" \
  "$troubleshooting_policy"; then
  fail 'creating-skills retains blanket repeated-trial or automatic full-suite guidance'
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
grep -Eqi 'every generated repository artifact.*English|English.*every generated repository artifact' \
  "$plugin_dir/evals/creating-skills/new-with-creator/graders/lifecycle.md" || \
  fail 'creator-present eval must require every generated repository artifact to be in English'
grep -Eqi 'English-language positive and negative.*eval|positive and negative.*eval.*in English' \
  "$plugin_dir/evals/creating-skills/new-with-creator/graders/lifecycle.md" || \
  fail 'creator-present eval must require English positive and negative eval files'

for runtime_output in conversations reports summaries errors warnings 'status updates' prompts 'generated PR comments'; do
  grep -Eqi "$runtime_output" "$creating_dir/reference/checklist.md" || \
    fail "creating-skills language checklist misses runtime output: $runtime_output"
done
grep -Eqi 'detected user language' "$creating_dir/reference/checklist.md" || \
  fail 'creating-skills language checklist must use the detected user language'

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

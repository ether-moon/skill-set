#!/usr/bin/env bash

set -euo pipefail

test_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
plugin_dir=$(cd -- "$test_dir/.." && pwd)
# shellcheck source=plugins/skill-set/tests/test-helper.sh
source "$test_dir/test-helper.sh"

runner=$plugin_dir/scripts/run-evals
mock_claude=$test_dir/fixtures/mock-claude-eval
assert_executable "$runner"
assert_executable "$mock_claude"

test_root=$(mktemp -d "${TMPDIR:-/tmp}/skill-set-run-evals.XXXXXX")
test_root=$(cd -- "$test_root" && pwd -P)
trap 'rm -rf -- "$test_root"' EXIT
mkdir -p -- "$test_root/bin"
ln -s -- "$mock_claude" "$test_root/bin/claude"
root_log=$test_root/mock-roots.log
: >"$root_log"

set +e
PATH="$test_root/bin:$PATH" FAKE_CLAUDE_ROOT_LOG="$root_log" \
  "$runner" \
    --stage development-smoke \
    --case creating-skills-existing-with-creator \
    --max-calls 1 \
    --output-dir "$test_root/rejected-results" \
    >"$test_root/rejected-plan.json" 2>"$test_root/rejected-plan.stderr"
rejected_plan_status=$?
set -e
assert_equals 2 "$rejected_plan_status" "preflight rejection exit status"
jq -e '
  .allowed == false and
  .total_calls == 2 and
  .projected_tokens == 50000 and
  .max_calls == 1 and
  (.reasons | length) == 1
' "$test_root/rejected-plan.json" >/dev/null
[[ ! -s $root_log ]] || fail "preflight rejection invoked the model executor"
[[ ! -e $test_root/rejected-results/candidate.json ]] || fail "preflight rejection produced model output"

allowed_plan=$(PATH="$test_root/bin:$PATH" "$runner" \
  --plan \
  --stage focused-comparison \
  --case creating-skills-existing-with-creator \
  --baseline no-plugin \
  --reason 'Compare one qualitative regression risk.' \
  --max-calls 4 \
  --max-total-tokens 100000)
printf '%s\n' "$allowed_plan" | jq -e '
  .budget.allowed == true and
  .budget.execution_calls == 2 and
  .budget.judge_calls == 2 and
  .budget.total_calls == 4 and
  .budget.projected_tokens == 100000
' >/dev/null

set +e
PATH="$test_root/bin:$PATH" FAKE_CLAUDE_ROOT_LOG="$root_log" \
  "$runner" \
    --stage campaign \
    --reason 'Exercise a deliberately oversized matrix.' \
    --runs 2 \
    --max-calls 4 \
    --max-total-tokens 100000 \
    --output-dir "$test_root/exploded-results" \
    >"$test_root/exploded-plan.json" 2>"$test_root/exploded-plan.stderr"
exploded_plan_status=$?
set -e
assert_equals 2 "$exploded_plan_status" "exploded plan exit status"
jq -e '
  .allowed == false and
  .execution_calls > 4 and
  .judge_calls > 0 and
  .total_calls > .execution_calls and
  .projected_tokens > .max_total_tokens and
  (.reasons | length) == 2
' "$test_root/exploded-plan.json" >/dev/null
[[ ! -s $root_log ]] || fail "exploded preflight plan invoked the model executor"

mkdir -p -- "$test_root/tmp"
set +e
TMPDIR="$test_root/tmp" PATH="$test_root/bin:$PATH" \
  FAKE_CLAUDE_GIT_SANDBOX=true FAKE_CLAUDE_TEE_MUTATE_SANDBOX=true \
  "$runner" \
    --output-dir "$test_root/dirty-worktree-results" \
    --case reviewing-with-peer-agents-review-only \
    --model haiku \
    --judge-model sonnet \
    >"$test_root/dirty-worktree.stdout" 2>"$test_root/dirty-worktree.stderr"
dirty_worktree_status=$?
set -e
assert_equals 1 "$dirty_worktree_status" "dirty eval worktree exit status"
grep -Fq 'Eval sandbox has unstaged changes' "$test_root/dirty-worktree.stderr" || \
  fail 'run-evals did not enforce the case clean-worktree contract'
[[ ! -e $test_root/dirty-worktree-results/acceptance-summary.json ]] || \
  fail 'dirty eval worktree emitted acceptance evidence'

set +e
FAKE_CLAUDE_REQUIRE_PR_RUNNER=true SKILL_SET_PR_RUNNER=relative-runner \
  "$mock_claude" plugin eval "$plugin_dir" \
    --ablation none \
    --output-dir "$test_root/invalid-runner-output" \
    --json "$test_root/invalid-runner.json" \
    >"$test_root/invalid-runner.stdout" 2>"$test_root/invalid-runner.stderr"
invalid_runner_status=$?
set -e
assert_equals 1 "$invalid_runner_status" "invalid PR runner exit status"
grep -Fq 'mock eval requires an executable absolute SKILL_SET_PR_RUNNER' \
  "$test_root/invalid-runner.stderr" || fail "invalid PR runner diagnostic is missing"

PATH="$test_root/bin:$PATH" FAKE_CLAUDE_ROOT_LOG="$root_log" \
  FAKE_CLAUDE_REQUIRE_PR_RUNNER=true \
  "$runner" \
    --output-dir "$test_root/results" \
    --case creating-skills-trigger-positive-01 \
    --model haiku \
    --judge-model sonnet >/dev/null

for artifact in \
  eval-plan.json metadata.json candidate.json safety-contract.json \
  acceptance-summary.json combined-results.json; do
  [[ -s $test_root/results/$artifact ]] || fail "missing run-evals artifact: $artifact"
done
[[ ! -e $test_root/results/baseline.json ]] || fail "development smoke ran an unrequested baseline"

jq -e '
  .stage == "development-smoke" and
  .arms == ["candidate"] and
  .trials == 1 and
  .selected_cases == ["creating-skills-trigger-positive-01"] and
  .budget.allowed == true and
  .budget.total_calls == 1
' "$test_root/results/eval-plan.json" >/dev/null
jq -e '
  .stage == "development-smoke" and
  .arms == ["candidate"] and
  .trace_retention.path == "traces" and
  .safety_contract.hash_algorithm == "git-hash-object"
' "$test_root/results/metadata.json" >/dev/null
jq -e '
  .status == "passed" and
  .coverage_status == "partial" and
  .plan_match == true and
  .acceptance.complete == false and
  .acceptance.current_stage == "development-smoke" and
  .cases[0].trace_evidence.candidate[0].tool_calls[0].name == "Skill" and
  .cases[0].token_usage.candidate[0].agent.usage.input_tokens == 17
' "$test_root/results/acceptance-summary.json" >/dev/null

trace_count=$(find "$test_root/results/traces" -type f -name '*.jsonl' | wc -l | tr -d ' ')
[[ $trace_count == 1 ]] || fail "expected 1 retained trace, got $trace_count"
while IFS= read -r sandbox_root; do
  [[ -n $sandbox_root ]] || continue
  [[ ! -e $sandbox_root ]] || fail "mock eval sandbox was not cleaned: $sandbox_root"
done <"$root_log"

PATH="$test_root/bin:$PATH" FAKE_CLAUDE_ROOT_LOG="$root_log" \
  "$runner" \
    --stage focused-comparison \
    --case creating-skills-trigger-positive-01 \
    --baseline no-plugin \
    --reason 'Confirm the trigger-boundary change against no skill.' \
    --max-calls 4 \
    --max-total-tokens 100000 \
    --output-dir "$test_root/focused-results" \
    --model haiku \
    --judge-model sonnet >/dev/null
jq -e '
  .stage == "focused-comparison" and
  .arms == ["candidate", "no-plugin"] and
  .budget.total_calls == 2 and
  .budget.projected_tokens == 50000
' "$test_root/focused-results/eval-plan.json" >/dev/null
jq -e '
  .status == "passed" and
  .coverage_status == "partial" and
  .plan_match == true and
  .actual_calls.execution_calls == 2 and
  .acceptance.complete == false
' "$test_root/focused-results/acceptance-summary.json" >/dev/null
[[ ! -e $test_root/focused-results/baseline.json ]] || fail "no-plugin comparison emitted deletion baseline output"
focused_trace_count=$(find "$test_root/focused-results/traces" -type f -name '*.jsonl' | wc -l | tr -d ' ')
[[ $focused_trace_count == 2 ]] || fail "expected 2 focused-comparison traces, got $focused_trace_count"

jq '.trials = 2 | .budget.trials = 2' \
  "$test_root/focused-results/eval-plan.json" >"$test_root/mismatched-plan.json"
"$plugin_dir/scripts/summarize-evals" \
  --stage focused-comparison \
  --candidate "$test_root/focused-results/candidate.json" \
  --metadata "$test_root/focused-results/metadata.json" \
  --plan "$test_root/mismatched-plan.json" \
  --safety-contract "$test_root/focused-results/safety-contract.json" \
  --output "$test_root/mismatched-summary.json"
jq -e '
  .status == "invalid" and
  .plan_match == false and
  (.reasons | any(contains("trials")))
' "$test_root/mismatched-summary.json" >/dev/null

PATH="$test_root/bin:$PATH" FAKE_CLAUDE_ROOT_LOG="$root_log" \
  "$runner" \
    --stage campaign \
    --reason 'Run the explicitly approved release campaign.' \
    --runs 1 \
    --max-calls 1000 \
    --max-total-tokens 30000000 \
    --output-dir "$test_root/campaign-results" \
    --model haiku \
    --judge-model sonnet >/dev/null
jq -e '
  .stage == "campaign" and
  .arms == ["candidate", "no-plugin", "deletion-baseline"] and
  .trials == 1 and
  .budget.allowed == true
' "$test_root/campaign-results/eval-plan.json" >/dev/null
jq -e '
  .status == "incomplete" and
  .provenance.baseline_identity_valid == true and
  .safety.contract_identity_valid == true and
  .traces.complete == true
' "$test_root/campaign-results/acceptance-summary.json" >/dev/null
campaign_trace_count=$(find "$test_root/campaign-results/traces" -type f -name '*.jsonl' | wc -l | tr -d ' ')
[[ $campaign_trace_count == 3 ]] || fail "expected 3 campaign traces, got $campaign_trace_count"

run_drift_case() {
  local name=$1
  local mutation_target=$2
  local expected_contract_drift=$3
  local candidate_dir=$test_root/$name-candidate
  local result_dir=$test_root/$name-results
  mkdir -p -- "$candidate_dir/evals/creating-skills"
  cp -- "$plugin_dir/evals/safety-contract.json" "$candidate_dir/evals/safety-contract.json"
  cp -R -- "$plugin_dir/evals/creating-skills/trigger-positive-01" \
    "$candidate_dir/evals/creating-skills/trigger-positive-01"
  mkdir -p -- "$candidate_dir/skills/creating-skills/scripts" "$candidate_dir/skills/shipping-pr/scripts"
  cp -- "$plugin_dir/skills/creating-skills/scripts/plan_eval_budget.py" \
    "$candidate_dir/skills/creating-skills/scripts/plan_eval_budget.py"
  cp -- "$plugin_dir/skills/shipping-pr/scripts/skill-set-pr" \
    "$candidate_dir/skills/shipping-pr/scripts/skill-set-pr"
  cp -- "$plugin_dir/.claude-plugin/plugin.json" "$candidate_dir/marker.txt"

  local target_path
  case $mutation_target in
    candidate) target_path=$candidate_dir/marker.txt ;;
    safety-contract) target_path=$candidate_dir/evals/safety-contract.json ;;
    *) fail "unknown drift mutation target: $mutation_target" ;;
  esac

  if PATH="$test_root/bin:$PATH" \
    FAKE_CLAUDE_ROOT_LOG="$root_log" \
    FAKE_CLAUDE_MUTATE_FILE="$target_path" \
    FAKE_CLAUDE_MUTATION_TEXT=' ' \
    "$runner" \
      --candidate "$candidate_dir" \
      --output-dir "$result_dir" \
      --case creating-skills-trigger-positive-01 \
      --model haiku \
      --judge-model sonnet >/dev/null 2>"$test_root/$name.stderr"; then
    fail "run-evals accepted $mutation_target drift"
  fi

  [[ -s $result_dir/provenance-drift.json ]] || fail "missing drift artifact for $mutation_target"
  jq -e --argjson expected_contract_drift "$expected_contract_drift" '
    .error == "eval-input-drift" and
    .candidate_sha_changed == false and
    .candidate_fingerprint_changed == true and
    .safety_contract_changed == $expected_contract_drift and
    .acceptance == "discard"
  ' "$result_dir/provenance-drift.json" >/dev/null
  [[ ! -e $result_dir/metadata.json ]] || fail "drifted eval emitted trusted metadata"
  [[ ! -e $result_dir/acceptance-summary.json ]] || fail "drifted eval emitted acceptance"
}

run_drift_case candidate-drift candidate false
run_drift_case safety-contract-drift safety-contract true

printf 'PASS: run-evals enforces staged budgets and retains exact trace evidence\n'

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
    --runs 1 \
    --model haiku \
    --judge-model sonnet >/dev/null

for artifact in \
  metadata.json candidate.json baseline.json safety-contract.json \
  acceptance-summary.json combined-results.json; do
  [[ -s $test_root/results/$artifact ]] || fail "missing run-evals artifact: $artifact"
done

expected_sha=$(git -C "$plugin_dir" rev-parse '95c1b2a^{commit}')
jq -e --arg expected_sha "$expected_sha" '
  .baseline_ref == "95c1b2a" and
  .baseline_sha == $expected_sha and
  .trace_retention.path == "traces" and
  .safety_contract.hash_algorithm == "git-hash-object"
' "$test_root/results/metadata.json" >/dev/null
jq -e '
  .status == "incomplete" and
  .provenance.baseline_identity_valid == true and
  .safety.contract_identity_valid == true and
  .traces.complete == true and
  .cases[0].trace_evidence.candidate[0].tool_calls[0].name == "Skill" and
  .cases[0].token_usage.candidate[0].agent.usage.input_tokens == 17 and
  .cases[0].token_usage.candidate[0].judge.available == false
' "$test_root/results/acceptance-summary.json" >/dev/null

trace_count=$(find "$test_root/results/traces" -type f -name '*.jsonl' | wc -l | tr -d ' ')
[[ $trace_count == 3 ]] || fail "expected 3 retained traces, got $trace_count"
while IFS= read -r sandbox_root; do
  [[ -n $sandbox_root ]] || continue
  [[ ! -e $sandbox_root ]] || fail "mock eval sandbox was not cleaned: $sandbox_root"
done <"$root_log"

run_drift_case() {
  local name=$1
  local mutation_target=$2
  local expected_contract_drift=$3
  local candidate_dir=$test_root/$name-candidate
  local result_dir=$test_root/$name-results
  mkdir -p -- "$candidate_dir/evals"
  cp -- "$plugin_dir/evals/safety-contract.json" "$candidate_dir/evals/safety-contract.json"
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
      --runs 1 \
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

printf 'PASS: run-evals pins baseline and retains exact trace evidence\n'

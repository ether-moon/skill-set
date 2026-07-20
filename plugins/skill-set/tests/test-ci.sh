#!/usr/bin/env bash

set -euo pipefail

test_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
plugin_dir=$(cd -- "$test_dir/.." && pwd)
repo_dir=$(cd -- "$plugin_dir/../.." && pwd)
# shellcheck source=plugins/skill-set/tests/test-helper.sh
source "$test_dir/test-helper.sh"

workflow=$repo_dir/.github/workflows/validate-skill-set.yml
assert_file "$workflow"
grep -Eq 'claude plugin validate --strict plugins/skill-set' "$workflow"
grep -Eq 'plugins/skill-set/tests/run.sh' "$workflow"
grep -Eq 'shellcheck' "$workflow"
grep -Eq 'shellcheck ruby' "$workflow"
grep -Eq 'generate-inventory --check' "$workflow"
grep -Eq 'generate-trigger-evals --check' "$workflow"
grep -Eq 'validate-evals --require-trigger-matrix' "$workflow"
grep -Eq 'validate-references' "$workflow"

if grep -Eq 'apt-get install.*ripgrep' "$workflow"; then
  fail 'deterministic validation must not install ripgrep'
fi

if {
  grep -En '(^|[^[:alnum:]_])rg[[:space:]]' "$workflow" || true
  find "$plugin_dir/scripts" "$plugin_dir/tests" "$plugin_dir/evals" \
    -type f -perm -u+x -exec grep -En '(^|[^[:alnum:]_])rg[[:space:]]' {} \;
} | grep -q .; then
  fail 'deterministic executables must not invoke rg'
fi

eval_workflow=$repo_dir/.github/workflows/evaluate-skill-set.yml
assert_file "$eval_workflow"
grep -Eq 'schedule:' "$eval_workflow"
grep -Eq 'workflow_dispatch:' "$eval_workflow"
grep -Eq 'fetch-depth: 0' "$eval_workflow"
grep -Eq 'scripts/run-evals' "$eval_workflow"
grep -Eq -- '--model "\$EVAL_MODEL"' "$eval_workflow"
grep -Eq -- '--judge-model "\$JUDGE_MODEL"' "$eval_workflow"
grep -Eq 'acceptance-summary.json' "$eval_workflow"
grep -Eq "REQUESTED_RUNS:.*'3'" "$eval_workflow"
grep -Eq 'human review' "$eval_workflow"
grep -Eq 'upload-artifact' "$eval_workflow"
grep -Eq 'early access' "$eval_workflow"
printf 'PASS: CI workflow\n'

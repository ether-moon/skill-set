#!/usr/bin/env bash

set -euo pipefail

test_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
plugin_dir=$(cd -- "$test_dir/.." && pwd)
repo_dir=$(cd -- "$plugin_dir/../.." && pwd)
# shellcheck source=plugins/skill-set/tests/test-helper.sh
source "$test_dir/test-helper.sh"

workflow=$repo_dir/.github/workflows/validate-skill-set.yml
assert_file "$workflow"
rg -q 'claude plugin validate --strict plugins/skill-set' "$workflow"
rg -q 'plugins/skill-set/tests/run.sh' "$workflow"
rg -q 'shellcheck' "$workflow"
rg -q 'generate-inventory --check' "$workflow"
rg -q 'validate-evals' "$workflow"
rg -q 'validate-references' "$workflow"

eval_workflow=$repo_dir/.github/workflows/evaluate-skill-set.yml
assert_file "$eval_workflow"
rg -q 'schedule:' "$eval_workflow"
rg -q 'workflow_dispatch:' "$eval_workflow"
rg -q 'fetch-depth: 0' "$eval_workflow"
rg -q 'scripts/run-evals' "$eval_workflow"
rg -q 'upload-artifact' "$eval_workflow"
rg -q 'early access' "$eval_workflow"
printf 'PASS: CI workflow\n'

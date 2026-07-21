#!/usr/bin/env bash

set -euo pipefail

test_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
plugin_dir=$(cd -- "$test_dir/.." && pwd)
# shellcheck source=plugins/skill-set/tests/test-helper.sh
source "$test_dir/test-helper.sh"

commit_case=$plugin_dir/evals/managing-git-workflow/commit-with-conventional-style
preview_case=$plugin_dir/evals/managing-git-workflow/pr-title-and-body-generation
contract=$plugin_dir/evals/safety-contract.json

for case_file in "$commit_case/case.yaml" "$preview_case/case.yaml"; do
  grep -Eq "name: selected-managing-git-workflow" "$case_file"
  grep -Eq "name: invoked-git-runner-inspect" "$case_file"
  grep -Fq 'Bash(*skill-set-git:*)' "$case_file"
  ! grep -Eq '^    - (Bash|Write|Edit)$' "$case_file" || \
    fail "managing-git eval has an unrestricted operator grant: $case_file"
  grep -Eq 'name: safety-no-write-tool' "$case_file"
  grep -Eq 'name: safety-no-unrelated-bash' "$case_file"
done

grep -Eq 'name: invoked-git-runner-input-prepare' "$commit_case/case.yaml"
grep -Eq 'name: invoked-git-runner-commit' "$commit_case/case.yaml"
grep -Eq 'name: safety-no-direct-git-commit' "$commit_case/case.yaml"
assert_executable "$commit_case/fixtures/.eval-hooks/post-commit"

jq -e '
  any(.trace_policies[];
    .case == "managing-git-workflow-commit-with-conventional-style" and
    .forbidden_tools == ["Write"] and
    .bash_command_policy == "git-commit-runner-only" and
    .edit_path_policy == "managed-commit-message-only") and
  any(.trace_policies[];
    .case == "managing-git-workflow-pr-title-and-body-generation" and
    .forbidden_tools == ["Write"] and
    .bash_command_policy == "git-inspect-runner-only" and
    .edit_path_policy == "pr-preview-artifacts-only")
' "$contract" >/dev/null

fixture_root=$(mktemp -d "${TMPDIR:-/tmp}/skill-set-managing-evals.XXXXXX")
trap 'rm -rf -- "$fixture_root"' EXIT
commit_root=$fixture_root/commit
preview_root=$fixture_root/preview
mkdir -p -- "$commit_root" "$preview_root"

(
  cd "$commit_root"
  /bin/bash "$commit_case/fixtures/setup.sh" >/dev/null
  git commit -q -m 'feat(parser): normalize nested arrays'
  [[ $(sed -n '1p' outputs/commit-message.txt) == \
    'feat(parser): normalize nested arrays' ]] || fail 'post-commit evidence was not captured'
)

(
  cd "$preview_root"
  /bin/bash "$preview_case/fixtures/setup.sh" >/dev/null
  [[ $(<outputs/pr-title.txt) == PR_TITLE_REPLACE_ME ]] || fail 'missing PR title sentinel'
  [[ $(<outputs/pr-body.md) == PR_BODY_REPLACE_ME ]] || fail 'missing PR body sentinel'
)

printf 'PASS: managing-git functional eval isolation\n'

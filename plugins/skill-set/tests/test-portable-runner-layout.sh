#!/usr/bin/env bash

set -euo pipefail

test_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
plugin_dir=$(cd -- "$test_dir/.." && pwd)
# shellcheck source=plugins/skill-set/tests/test-helper.sh
source "$test_dir/test-helper.sh"

managing_skill=$plugin_dir/skills/managing-git-workflow
shipping_skill=$plugin_dir/skills/shipping-pr
git_runner=$managing_skill/scripts/skill-set-git
pr_runner=$shipping_skill/scripts/skill-set-pr

assert_executable "$git_runner"
assert_executable "$pr_runner"

if grep -R -Fq 'CLAUDE_PLUGIN_ROOT' "$managing_skill" "$shipping_skill"; then
  fail 'skill execution must not depend on CLAUDE_PLUGIN_ROOT'
fi

install_root=$(mktemp -d "${TMPDIR:-/tmp}/skill-set-portable.XXXXXX")
trap 'rm -rf -- "$install_root"' EXIT
mkdir -p "$install_root/skills"
cp -R "$managing_skill" "$shipping_skill" "$install_root/skills/"

installed_git_runner=$install_root/skills/managing-git-workflow/scripts/skill-set-git
installed_pr_runner=$install_root/skills/shipping-pr/scripts/skill-set-pr
assert_executable "$installed_git_runner"
assert_executable "$installed_pr_runner"

repo=$install_root/repo
git init --quiet -b main "$repo"
(
  cd "$repo"
  prepared=$(/bin/bash "$installed_git_runner" input-prepare --kind commit-message)
  input_path=$(jq -r .path <<<"$prepared")
  jq -e '.ok == true and .operation == "input-prepare"' <<<"$prepared" >/dev/null || fail 'git runner did not return ok for input-prepare'
  /bin/bash "$installed_git_runner" input-discard --input-file "$input_path" >/dev/null

  if /bin/bash "$installed_pr_runner" >stdout.json 2>stderr.json; then
    fail 'skill-set-pr without a subcommand must fail with usage information'
  fi
  jq -e '.ok == false and .error.code == "usage"' stderr.json >/dev/null || fail 'skill-set-pr did not return usage error'

)

printf 'PASS: portable runner layout\n'

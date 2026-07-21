#!/usr/bin/env bash

set -euo pipefail

test_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
plugin_dir=$(cd -- "$test_dir/.." && pwd)
# shellcheck source=plugins/skill-set/tests/test-helper.sh
source "$test_dir/test-helper.sh"

runner=$plugin_dir/bin/skill-set-git
mock_bin=$test_dir/fixtures/git-runner/bin
assert_file "$runner"
assert_executable "$runner"
assert_executable "$mock_bin/gh"

test_root=$(mktemp -d "${TMPDIR:-/tmp}/skill-set-git-test.XXXXXX")
trap 'rm -rf -- "$test_root"' EXIT

git_configure_identity() {
  git config user.name "Skill Set Test"
  git config user.email "skill-set@example.invalid"
}

test_runner_omits_forbidden_publication_shortcuts() {
  local runner_source
  runner_source=$(<"$runner")
  [[ $runner_source != *"git add -A"* ]] || fail "runner must not use implicit all-change staging"
  [[ $runner_source != *"git pull"* ]] || fail "runner must not synchronize incoming commits implicitly"
  [[ $runner_source != *"git rebase"* ]] || fail "runner must not rewrite commits implicitly"
  [[ $runner_source != *"--force"* ]] || fail "runner must not bypass remote fast-forward checks"
}

test_managed_input_prepare_and_discard() {
  local repo git_dir
  local prepared prepared_path discarded
  repo=$(make_repo managed-input)

  (
    cd "$repo"
    git_dir=$(git rev-parse --absolute-git-dir)
    prepared=$(/bin/bash "$runner" input-prepare --kind commit-message)
    prepared_path=$(jq -r '.path' <<<"$prepared")

    jq -e '.ok == true and .operation == "input-prepare" and .kind == "commit-message"' <<<"$prepared" >/dev/null
    [[ $prepared_path == "$git_dir"/skill-set/inputs/commit-message.*/content ]] || fail "managed input path escaped the worktree Git directory"
    [[ -f $prepared_path && ! -L $prepared_path ]] || fail "managed input must be a regular non-symlink file"
    assert_equals "SKILL_SET_INPUT_REPLACE_ME" "$(<"$prepared_path")" "managed input sentinel"

    printf 'feat: managed message\n' > "$prepared_path"
    discarded=$(/bin/bash "$runner" input-discard --input-file "$prepared_path")
    jq -e '.ok == true and .operation == "input-discard" and .discarded == true' <<<"$discarded" >/dev/null
    [[ ! -e $prepared_path ]] || fail "managed input discard must remove the allocated file"
  )

  grep -F 'Edit(//**/.git/skill-set/inputs/commit-message.*/content)' "$plugin_dir/skills/managing-git-workflow/SKILL.md" >/dev/null || fail "skill lacks main-worktree commit-message permission"
  grep -F 'Edit(//**/.git/worktrees/*/skill-set/inputs/commit-message.*/content)' "$plugin_dir/skills/managing-git-workflow/SKILL.md" >/dev/null || fail "skill lacks linked-worktree commit-message permission"
  grep -F 'Edit(//**/.git/skill-set/inputs/pr-body.*/content)' "$plugin_dir/skills/managing-git-workflow/SKILL.md" >/dev/null || fail "skill lacks main-worktree PR-body permission"
  grep -F 'Edit(//**/.git/worktrees/*/skill-set/inputs/pr-body.*/content)' "$plugin_dir/skills/managing-git-workflow/SKILL.md" >/dev/null || fail "skill lacks linked-worktree PR-body permission"
  grep -F 'Edit(//**/.git/skill-set/inputs/commit-message.*/content)' "$plugin_dir/commands/git/commit.md" >/dev/null || fail "commit command lacks scoped message permission"
  grep -F 'Edit(//**/.git/worktrees/*/skill-set/inputs/commit-message.*/content)' "$plugin_dir/commands/git/commit.md" >/dev/null || fail "commit command lacks scoped worktree message permission"
  grep -F 'Edit(//**/.git/skill-set/inputs/pr-body.*/content)' "$plugin_dir/commands/git/pr.md" >/dev/null || fail "PR command lacks scoped body permission"
  grep -F 'Edit(//**/.git/worktrees/*/skill-set/inputs/pr-body.*/content)' "$plugin_dir/commands/git/pr.md" >/dev/null || fail "PR command lacks scoped worktree body permission"
  ! grep -F 'Edit(' "$plugin_dir/commands/git/push.md" >/dev/null || fail "push command must not grant file-edit permission"
}

test_commit_consumes_managed_message_after_success() {
  local repo expected prepared message_path result before_head
  local status
  local stdout_file=$test_root/managed-sentinel-stdout.json
  local stderr_file=$test_root/managed-sentinel-stderr.json
  repo=$(make_repo managed-commit-message)

  (
    cd "$repo"
    printf 'managed\n' > managed.txt
    git add -- managed.txt
    expected=$(git write-tree)
    prepared=$(/bin/bash "$runner" input-prepare --kind commit-message)
    message_path=$(jq -r '.path' <<<"$prepared")
    before_head=$(git rev-parse HEAD)

    set +e
    /bin/bash "$runner" commit \
      --expected-index "$expected" \
      --message-file "$message_path" \
      >"$stdout_file" 2>"$stderr_file"
    status=$?
    set -e
    [[ $status -ne 0 ]] || fail "commit must reject an unchanged managed input sentinel"
    jq -e '.code == "managed_input_unwritten" and .recoverable == true' "$stderr_file" >/dev/null
    assert_equals "$before_head" "$(git rev-parse HEAD)" "sentinel rejection head"
    [[ -e $message_path ]] || fail "rejected managed input must remain recoverable"

    printf 'feat: consume managed message\n' > "$message_path"

    result=$(/bin/bash "$runner" commit \
      --expected-index "$expected" \
      --message-file "$message_path")

    jq -e '.ok == true and .input_consumed == true' <<<"$result" >/dev/null
    [[ ! -e $message_path ]] || fail "successful commit must consume its managed message"
  )
}

make_repo() {
  local name=$1
  local bare=$test_root/$name-remote.git
  local work=$test_root/$name-work

  git init --bare --quiet "$bare"
  git init --quiet -b main "$work"
  (
    cd "$work"
    git_configure_identity
    printf 'seed\n' > tracked.txt
    git add -- tracked.txt
    git commit --quiet -m "seed"
    git remote add origin "$bare"
    git push --quiet -u origin main
    git remote set-head origin main
  )
  printf '%s\n' "$work"
}

test_inspect_reports_separate_nul_safe_state() {
  local repo
  local staged_name
  local result
  repo=$(make_repo inspect)
  staged_name=$(printf 'staged\nname.txt')

  (
    cd "$repo"
    git switch --quiet -c feature
    printf 'feature\n' > feature.txt
    git add -- feature.txt
    git commit --quiet -m "feature"
    git push --quiet -u origin feature
    printf 'second\n' >> feature.txt
    git add -- feature.txt
    git commit --quiet -m "second"
    printf 'staged\n' > "$staged_name"
    git add -- "$staged_name"
    printf 'unstaged\n' >> tracked.txt
    printf 'untracked\n' > "untracked file.txt"

    result=$(/bin/bash "$runner" inspect --base main)
    jq -e '.ok == true and .operation == "inspect"' <<<"$result" >/dev/null
    jq -e --arg path "$staged_name" '.working_tree.staged | index($path) != null' <<<"$result" >/dev/null
    jq -e '.working_tree.unstaged == ["tracked.txt"]' <<<"$result" >/dev/null
    jq -e '.working_tree.untracked == ["untracked file.txt"]' <<<"$result" >/dev/null
    jq -e '.branch.name == "feature" and .branch.upstream == "origin/feature"' <<<"$result" >/dev/null
    jq -e '.branch.ahead == 1 and .branch.behind == 0 and .branch.diverged == false' <<<"$result" >/dev/null
    jq -e '.branch.remote == "origin" and (.branch.remote_sha | length == 40)' <<<"$result" >/dev/null
    jq -e '.working_tree.dirty_fingerprint | test("^[0-9a-f]{40}$")' <<<"$result" >/dev/null
    jq -e '.index_fingerprint | test("^[0-9a-f]{40}$")' <<<"$result" >/dev/null
    jq -e '.commit_context.staged_diff | contains("+staged")' <<<"$result" >/dev/null
    jq -e '.commit_context.recent_subjects[0] == "second"' <<<"$result" >/dev/null
    jq -e '.pr_scope.base == "main" and .pr_scope.range == "origin/main...HEAD"' <<<"$result" >/dev/null
    jq -e '.pr_scope.files == ["feature.txt"] and .pr_scope.commit_count == 2' <<<"$result" >/dev/null
  )
}

test_commit_uses_existing_index_without_push() {
  local repo
  local before_remote
  local expected
  local result
  repo=$(make_repo commit-index)

  (
    cd "$repo"
    git switch --quiet -c feature
    printf 'staged\n' > staged.txt
    git add -- staged.txt
    expected=$(git write-tree)
    printf 'feat: commit the selected index\n\nBody from a file.\n' > "$test_root/commit-message.txt"
    before_remote=$(git ls-remote origin refs/heads/feature)

    result=$(/bin/bash "$runner" commit --expected-index "$expected" --message-file "$test_root/commit-message.txt")
    jq -e '.ok == true and .operation == "commit" and .source == "index"' <<<"$result" >/dev/null
    jq -e '.commit.sha | test("^[0-9a-f]{40}$")' <<<"$result" >/dev/null
    assert_equals "feat: commit the selected index

Body from a file." "$(git log -1 --pretty=%B | sed '${/^$/d;}')" "commit message"
    assert_equals "$before_remote" "$(git ls-remote origin refs/heads/feature)" "commit must not push"
    assert_equals "" "$(git status --porcelain)" "committed index state"
  )
}

test_commit_requires_index_fingerprint() {
  local repo before_head
  local status
  local stdout_file=$test_root/index-required-stdout.json
  local stderr_file=$test_root/index-required-stderr.json
  repo=$(make_repo commit-index-required)

  (
    cd "$repo"
    printf 'staged\n' > staged.txt
    git add -- staged.txt
    printf 'feat: require index CAS\n' > "$test_root/index-required-message.txt"
    before_head=$(git rev-parse HEAD)

    set +e
    /bin/bash "$runner" commit \
      --message-file "$test_root/index-required-message.txt" \
      >"$stdout_file" 2>"$stderr_file"
    status=$?
    set -e

    [[ $status -ne 0 ]] || fail "commit must require an inspected index fingerprint"
    jq -e '.code == "expected_index_required" and .recoverable == true' "$stderr_file" >/dev/null
    assert_equals "$before_head" "$(git rev-parse HEAD)" "missing index CAS head"
  )
}

test_commit_rejects_unrelated_staged_paths() {
  local repo
  local before_head
  local expected
  local stdout_file=$test_root/unrelated-stdout.json
  local stderr_file=$test_root/unrelated-stderr.json
  local status
  repo=$(make_repo commit-unrelated)

  (
    cd "$repo"
    printf 'unrelated\n' > unrelated.txt
    git add -- unrelated.txt
    expected=$(git write-tree)
    printf 'selected\n' > selected.txt
    printf 'feat: selected only\n' > "$test_root/selected-message.txt"
    before_head=$(git rev-parse HEAD)

    set +e
    /bin/bash "$runner" commit \
      --path selected.txt \
      --expected-index "$expected" \
      --message-file "$test_root/selected-message.txt" \
      >"$stdout_file" 2>"$stderr_file"
    status=$?
    set -e

    [[ $status -ne 0 ]] || fail "path commit must reject an unrelated staged file"
    assert_equals "" "$(<"$stdout_file")" "failed command stdout"
    jq -e '.ok == false and .operation == "commit" and .code == "unrelated_staged_paths" and .recoverable == true' "$stderr_file" >/dev/null
    assert_equals "$before_head" "$(git rev-parse HEAD)" "rejected commit head"
    assert_equals "unrelated.txt" "$(git diff --cached --name-only)" "preserved unrelated index"
    assert_equals "selected.txt" "$(git ls-files --others --exclude-standard)" "selected path remains untracked"
  )
}

test_commit_stages_only_requested_paths() {
  local repo
  local expected
  local result
  repo=$(make_repo commit-path)

  (
    cd "$repo"
    printf 'selected\n' > selected.txt
    printf 'unstaged\n' >> tracked.txt
    printf 'excluded\n' > excluded.txt
    printf 'feat: add selected path\n' > "$test_root/path-message.txt"
    expected=$(git write-tree)

    result=$(/bin/bash "$runner" commit \
      --path selected.txt \
      --expected-index "$expected" \
      --message-file "$test_root/path-message.txt")

    jq -e '.ok == true and .source == "paths" and .requested_paths == ["selected.txt"] and .pushed == false' <<<"$result" >/dev/null
    assert_equals "selected.txt" "$(git show --pretty= --name-only HEAD)" "path commit contents"
    assert_equals " M tracked.txt
?? excluded.txt" "$(git status --porcelain)" "excluded worktree state"
  )
}

test_commit_requires_explicit_all_changes_scope() {
  local repo
  local expected
  local stdout_file=$test_root/all-stdout.json
  local stderr_file=$test_root/all-stderr.json
  local status
  local result
  repo=$(make_repo commit-all)

  (
    cd "$repo"
    printf 'modified\n' >> tracked.txt
    printf 'new\n' > new.txt
    printf 'feat: commit all requested changes\n' > "$test_root/all-message.txt"
    expected=$(git write-tree)

    set +e
    /bin/bash "$runner" commit --expected-index "$expected" --message-file "$test_root/all-message.txt" >"$stdout_file" 2>"$stderr_file"
    status=$?
    set -e
    [[ $status -ne 0 ]] || fail "commit without index or path scope must fail"
    jq -e '.code == "nothing_staged" and .recoverable == true' "$stderr_file" >/dev/null
    assert_equals " M tracked.txt
?? new.txt" "$(git status --porcelain)" "implicit commit must not stage"

    result=$(/bin/bash "$runner" commit --all --expected-index "$expected" --message-file "$test_root/all-message.txt")
    jq -e '.ok == true and .source == "all" and .requested_paths == []' <<<"$result" >/dev/null
    assert_equals "new.txt
tracked.txt" "$(git show --pretty= --name-only HEAD)" "explicit all commit contents"
    assert_equals "" "$(git status --porcelain)" "explicit all worktree state"
  )
}

test_commit_dry_run_does_not_mutate_index_or_head() {
  local repo
  local before_head before_index
  local result
  repo=$(make_repo commit-dry-run)

  (
    cd "$repo"
    printf 'staged\n' > staged.txt
    git add -- staged.txt
    printf 'feat: dry run\n' > "$test_root/dry-message.txt"
    before_head=$(git rev-parse HEAD)
    before_index=$(git write-tree)

    result=$(/bin/bash "$runner" commit --dry-run --message-file "$test_root/dry-message.txt")

    jq -e '.ok == true and .operation == "commit" and .dry_run == true and .source == "index" and .would_commit == ["staged.txt"]' <<<"$result" >/dev/null
    assert_equals "$before_head" "$(git rev-parse HEAD)" "dry-run head"
    assert_equals "$before_index" "$(git write-tree)" "dry-run index"
  )
}

test_commit_path_dry_run_reports_diff_without_message_file() {
  local repo before_head before_index
  local result
  repo=$(make_repo commit-path-dry-run)

  (
    cd "$repo"
    printf 'selected\n' > selected.txt
    printf 'excluded\n' >> tracked.txt
    before_head=$(git rev-parse HEAD)
    before_index=$(git write-tree)

    result=$(/bin/bash "$runner" commit --path selected.txt --dry-run)

    jq -e '.ok == true and .dry_run == true and .source == "paths" and .would_commit == ["selected.txt"]' <<<"$result" >/dev/null
    jq -e '.staged_preview.diff | contains("+selected")' <<<"$result" >/dev/null
    jq -e '.staged_preview.stat | contains("selected.txt")' <<<"$result" >/dev/null
    assert_equals "$before_head" "$(git rev-parse HEAD)" "path dry-run head"
    assert_equals "$before_index" "$(git write-tree)" "path dry-run index"
    assert_equals " M tracked.txt
?? selected.txt" "$(git status --porcelain)" "path dry-run worktree"
  )
}

test_commit_rejects_changed_index_fingerprint() {
  local repo expected before_head
  local status
  local stdout_file=$test_root/index-cas-stdout.json
  local stderr_file=$test_root/index-cas-stderr.json
  repo=$(make_repo commit-index-cas)

  (
    cd "$repo"
    printf 'first\n' > first.txt
    git add -- first.txt
    expected=$(git write-tree)
    printf 'second\n' > second.txt
    git add -- second.txt
    before_head=$(git rev-parse HEAD)
    printf 'feat: stale inspection\n' > "$test_root/index-cas-message.txt"

    set +e
    /bin/bash "$runner" commit \
      --expected-index "$expected" \
      --message-file "$test_root/index-cas-message.txt" \
      >"$stdout_file" 2>"$stderr_file"
    status=$?
    set -e

    [[ $status -ne 0 ]] || fail "commit must reject a stale index fingerprint"
    jq -e '.code == "index_changed" and .recoverable == true' "$stderr_file" >/dev/null
    assert_equals "$before_head" "$(git rev-parse HEAD)" "index CAS head"
    assert_equals "first.txt
second.txt" "$(git diff --cached --name-only)" "index CAS preservation"
  )
}

test_commit_allows_an_explicit_tree_identical_merge() {
  local repo input_head base_sha expected before_tree result
  repo=$(make_repo commit-tree-identical-merge)

  (
    cd "$repo"
    git switch --quiet -c feature
    printf 'shared\n' > shared.txt
    git add -- shared.txt
    git commit --quiet -m "feat: carry shared content"
    input_head=$(git rev-parse HEAD)
    before_tree=$(git rev-parse "HEAD^{tree}")

    git switch --quiet main
    printf 'shared\n' > shared.txt
    git add -- shared.txt
    git commit --quiet -m "feat: add shared content"
    base_sha=$(git rev-parse HEAD)

    git switch --quiet feature
    git merge --quiet --no-commit --no-ff "$base_sha"
    expected=$(git write-tree)
    assert_equals "$before_tree" "$expected" "tree-identical merge index"
    printf 'merge: integrate main ancestry\n' > "$test_root/tree-identical-merge-message.txt"

    result=$(/bin/bash "$runner" commit --dry-run --allow-tree-identical-merge)
    jq -e --arg merge_head "$base_sha" '
      .ok == true and .dry_run == true and
      .source == "tree-identical-merge" and .would_commit == [] and
      .tree_identical_merge == true and .merge_head == $merge_head
    ' <<<"$result" >/dev/null
    assert_equals "$input_head" "$(git rev-parse HEAD)" "tree-identical merge dry-run head"

    result=$(/bin/bash "$runner" commit \
      --allow-tree-identical-merge \
      --expected-index "$expected" \
      --message-file "$test_root/tree-identical-merge-message.txt")

    jq -e --arg merge_head "$base_sha" '
      .ok == true and .source == "tree-identical-merge" and
      .tree_identical_merge == true and .merge_head == $merge_head
    ' <<<"$result" >/dev/null
    assert_equals "$input_head $base_sha" "$(git show -s --format='%P' HEAD)" "tree-identical merge parents"
    assert_equals "$before_tree" "$(git rev-parse "HEAD^{tree}")" "tree-identical merge committed tree"
    assert_equals "" "$(git status --porcelain)" "tree-identical merge worktree"
  )
}

test_tree_identical_merge_flag_rejects_unsafe_states() {
  local repo base_sha status
  local stdout_file=$test_root/tree-identical-unsafe-stdout.json
  local stderr_file=$test_root/tree-identical-unsafe-stderr.json
  repo=$(make_repo commit-tree-identical-unsafe)

  (
    cd "$repo"

    set +e
    /bin/bash "$runner" commit --dry-run --allow-tree-identical-merge \
      >"$stdout_file" 2>"$stderr_file"
    status=$?
    set -e
    [[ $status -ne 0 ]] || fail "tree-identical merge flag must require an active merge"
    jq -e '.code == "merge_not_in_progress" and .recoverable == true' "$stderr_file" >/dev/null

    git switch --quiet -c feature
    git switch --quiet main
    printf 'base\n' > base.txt
    git add -- base.txt
    git commit --quiet -m "feat: add base content"
    base_sha=$(git rev-parse HEAD)
    git switch --quiet feature
    git merge --quiet --no-commit --no-ff "$base_sha"

    set +e
    /bin/bash "$runner" commit --dry-run --allow-tree-identical-merge \
      >"$stdout_file" 2>"$stderr_file"
    status=$?
    set -e
    [[ $status -ne 0 ]] || fail "tree-identical merge flag must reject a changed merge tree"
    jq -e '.code == "merge_tree_changed" and .recoverable == true' "$stderr_file" >/dev/null
    git merge --abort
  )
}

test_push_sends_only_existing_commits() {
  local repo
  local before_head
  local result remote_sha
  repo=$(make_repo push-existing)

  (
    cd "$repo"
    git switch --quiet -c feature
    printf 'committed\n' > committed.txt
    git add -- committed.txt
    git commit --quiet -m "feat: existing commit"
    before_head=$(git rev-parse HEAD)
    printf 'dirty\n' >> tracked.txt
    printf 'excluded\n' > excluded.txt

    result=$(/bin/bash "$runner" push --expected-remote-sha absent)
    remote_sha=$(git ls-remote origin refs/heads/feature)
    remote_sha=${remote_sha%%$'\t'*}

    jq -e '.ok == true and .operation == "push" and .pushed == true and .head_sha == .remote_sha' <<<"$result" >/dev/null
    jq -e '.dirty_excluded.unstaged == ["tracked.txt"] and .dirty_excluded.untracked == ["excluded.txt"]' <<<"$result" >/dev/null
    assert_equals "$before_head" "$(git rev-parse HEAD)" "push local head"
    assert_equals "$before_head" "$remote_sha" "pushed remote head"
    assert_equals " M tracked.txt
?? excluded.txt" "$(git status --porcelain)" "push excluded dirty state"
  )
}

test_push_dry_run_rechecks_without_publishing() {
  local repo
  local expected before_remote before_head
  local result
  repo=$(make_repo push-dry-run)

  (
    cd "$repo"
    git switch --quiet -c feature
    git push --quiet -u origin feature
    expected=$(git rev-parse HEAD)
    printf 'local\n' > local.txt
    git add -- local.txt
    git commit --quiet -m "feat: local only"
    before_head=$(git rev-parse HEAD)
    before_remote=$(git ls-remote origin refs/heads/feature)

    result=$(/bin/bash "$runner" push --expected-remote-sha "$expected" --dry-run)

    jq -e '.ok == true and .operation == "push" and .dry_run == true and .would_push == true and .commits_to_push == 1' <<<"$result" >/dev/null
    assert_equals "$before_remote" "$(git ls-remote origin refs/heads/feature)" "push dry-run remote"
    assert_equals "$before_head" "$(git rev-parse HEAD)" "push dry-run head"
  )
}

test_push_rejects_remote_race_and_divergence() {
  local repo other remote_url
  local expected remote_now local_head inspect_result
  local status
  local stdout_file=$test_root/race-stdout.json
  local stderr_file=$test_root/race-stderr.json
  repo=$(make_repo push-race)

  (
    cd "$repo"
    git switch --quiet -c feature
    git push --quiet -u origin feature
    expected=$(git rev-parse HEAD)
    remote_url=$(git remote get-url origin)
    other=$test_root/push-race-other
    git clone --quiet --branch feature "$remote_url" "$other"
    (
      cd "$other"
      git_configure_identity
      printf 'remote\n' > remote.txt
      git add -- remote.txt
      git commit --quiet -m "remote"
      git push --quiet origin feature
    )
    remote_now=$(git -C "$other" rev-parse HEAD)
    printf 'local\n' > local.txt
    git add -- local.txt
    git commit --quiet -m "local"
    local_head=$(git rev-parse HEAD)

    set +e
    /bin/bash "$runner" push --expected-remote-sha "$expected" >"$stdout_file" 2>"$stderr_file"
    status=$?
    set -e
    [[ $status -ne 0 ]] || fail "push must reject a changed remote SHA"
    assert_equals "" "$(<"$stdout_file")" "remote race stdout"
    jq -e '.code == "remote_changed" and .recoverable == true' "$stderr_file" >/dev/null
    inspect_result=$(/bin/bash "$runner" inspect --base main)
    jq -e '.branch.ahead == 1 and .branch.behind == 1 and .branch.diverged == true' <<<"$inspect_result" >/dev/null

    set +e
    /bin/bash "$runner" push --expected-remote-sha "$remote_now" >"$stdout_file" 2>"$stderr_file"
    status=$?
    set -e
    [[ $status -ne 0 ]] || fail "push must reject diverged histories"
    jq -e '.code == "diverged" and .recoverable == true' "$stderr_file" >/dev/null
    assert_equals "$local_head" "$(git rev-parse HEAD)" "diverged local head"
    assert_equals "$remote_now" "$(git -C "$other" rev-parse HEAD)" "diverged remote head"
  )
}

test_push_allows_validated_remote_branch_override() {
  local repo expected head_sha remote_feature
  local result
  repo=$(make_repo push-destination)

  (
    cd "$repo"
    expected=$(git rev-parse HEAD)
    git push --quiet origin HEAD:refs/heads/feature
    git switch --quiet -c resolver-worktree
    printf 'resolved\n' > resolved.txt
    git add -- resolved.txt
    git commit --quiet -m "fix: resolve blocker"
    head_sha=$(git rev-parse HEAD)

    result=$(/bin/bash "$runner" push \
      --remote origin \
      --remote-branch feature \
      --expected-remote-sha "$expected")
    remote_feature=$(git ls-remote origin refs/heads/feature)
    remote_feature=${remote_feature%%$'\t'*}

    jq -e '.ok == true and .pushed == true and .branch == "resolver-worktree" and .remote_branch == "feature"' <<<"$result" >/dev/null
    assert_equals "$head_sha" "$remote_feature" "destination override remote head"
    assert_equals "" "$(git ls-remote origin refs/heads/resolver-worktree)" "destination override source branch"
  )
}

test_pr_create_returns_existing_pr_without_mutation() {
  local repo
  local before_head before_remote
  local result
  repo=$(make_repo pr-existing)

  (
    cd "$repo"
    git switch --quiet -c feature
    printf 'feature\n' > feature.txt
    git add -- feature.txt
    git commit --quiet -m "feat: existing PR"
    git push --quiet -u origin feature
    before_head=$(git rev-parse HEAD)
    before_remote=$(git ls-remote origin refs/heads/feature)
    : > "$test_root/existing-gh.log"
    printf 'Existing body\n' > "$test_root/existing-body.md"

    result=$(PATH="$mock_bin:$PATH" \
      MOCK_GH_EXISTING_URL=https://example.invalid/pull/42 \
      MOCK_GH_LOG="$test_root/existing-gh.log" \
      /bin/bash "$runner" pr-create \
        --base main \
        --title "Existing title" \
        --body-file "$test_root/existing-body.md")

    jq -e '.ok == true and .operation == "pr-create" and .existing == true and .url == "https://example.invalid/pull/42" and .created == false' <<<"$result" >/dev/null
    assert_equals "" "$(<"$test_root/existing-gh.log")" "existing PR create log"
    assert_equals "$before_head" "$(git rev-parse HEAD)" "existing PR head"
    assert_equals "$before_remote" "$(git ls-remote origin refs/heads/feature)" "existing PR remote"
  )
}

test_pr_create_requires_dirty_exclusion_confirmation_and_supports_dry_run() {
  local repo before_head
  local result status
  local stdout_file=$test_root/pr-dirty-stdout.json
  local stderr_file=$test_root/pr-dirty-stderr.json
  repo=$(make_repo pr-dirty)

  (
    cd "$repo"
    git switch --quiet -c feature
    printf 'feature\n' > feature.txt
    git add -- feature.txt
    git commit --quiet -m "feat: PR scope"
    before_head=$(git rev-parse HEAD)
    printf 'staged\n' > staged.txt
    git add -- staged.txt
    printf 'unstaged\n' >> tracked.txt
    printf 'untracked\n' > untracked.txt
    printf '## Summary\n- Feature scope\n' > "$test_root/pr-dirty-body.md"
    : > "$test_root/pr-dirty-gh.log"

    set +e
    PATH="$mock_bin:$PATH" MOCK_GH_LOG="$test_root/pr-dirty-gh.log" \
      /bin/bash "$runner" pr-create \
        --base main --title "Feature scope" --body-file "$test_root/pr-dirty-body.md" \
        >"$stdout_file" 2>"$stderr_file"
    status=$?
    set -e
    [[ $status -ne 0 ]] || fail "PR creation with dirty files must require confirmation"
    jq -e '.code == "dirty_exclusion_unconfirmed" and .recoverable == true' "$stderr_file" >/dev/null

    result=$(PATH="$mock_bin:$PATH" MOCK_GH_LOG="$test_root/pr-dirty-gh.log" \
      /bin/bash "$runner" pr-create \
        --base main --title "Feature scope" --body-file "$test_root/pr-dirty-body.md" \
        --confirm-dirty-excluded --dry-run)

    jq -e '.ok == true and .dry_run == true and .would_push == true and .would_create == true' <<<"$result" >/dev/null
    jq -e '.committed_scope.range == "origin/main...HEAD" and .committed_scope.files == ["feature.txt"] and .committed_scope.commit_count == 1' <<<"$result" >/dev/null
    jq -e '.dirty_excluded.staged == ["staged.txt"] and .dirty_excluded.unstaged == ["tracked.txt"] and .dirty_excluded.untracked == ["untracked.txt"]' <<<"$result" >/dev/null
    assert_equals "$before_head" "$(git rev-parse HEAD)" "PR dry-run head"
    assert_equals "" "$(git ls-remote origin refs/heads/feature)" "PR dry-run remote"
    assert_equals "" "$(<"$test_root/pr-dirty-gh.log")" "PR dry-run gh log"
  )
}

test_pr_create_pushes_commits_and_uses_body_file() {
  local repo head_sha remote_sha prepared body_path
  local result status
  local stdout_file=$test_root/pr-sentinel-stdout.json
  local stderr_file=$test_root/pr-sentinel-stderr.json
  repo=$(make_repo pr-create)

  (
    cd "$repo"
    git switch --quiet -c feature
    printf 'feature\n' > feature.txt
    git add -- feature.txt
    git commit --quiet -m "feat: create PR"
    head_sha=$(git rev-parse HEAD)
    prepared=$(/bin/bash "$runner" input-prepare --kind pr-body)
    body_path=$(jq -r '.path' <<<"$prepared")
    : > "$test_root/pr-create-gh.log"

    set +e
    PATH="$mock_bin:$PATH" MOCK_GH_LOG="$test_root/pr-create-gh.log" \
      /bin/bash "$runner" pr-create \
        --base main \
        --title "Sentinel must fail" \
        --body-file "$body_path" \
        >"$stdout_file" 2>"$stderr_file"
    status=$?
    set -e
    [[ $status -ne 0 ]] || fail "PR creation must reject an unchanged managed input sentinel"
    jq -e '.code == "managed_input_unwritten" and .recoverable == true' "$stderr_file" >/dev/null
    assert_equals "" "$(git ls-remote origin refs/heads/feature)" "sentinel rejection PR remote"
    assert_equals "" "$(<"$test_root/pr-create-gh.log")" "sentinel rejection gh log"

    # shellcheck disable=SC2016 # Verify that file arguments preserve shell metacharacters literally.
    printf '## Summary\n- Preserve $dollars and `backticks` literally.\n' > "$body_path"

    result=$(PATH="$mock_bin:$PATH" \
      MOCK_GH_LOG="$test_root/pr-create-gh.log" \
      MOCK_GH_CREATED_URL=https://example.invalid/pull/77 \
      /bin/bash "$runner" pr-create \
        --base main \
        --title 'Feature: preserve $title' \
        --body-file "$body_path")
    remote_sha=$(git ls-remote origin refs/heads/feature)
    remote_sha=${remote_sha%%$'\t'*}

    jq -e '.ok == true and .created == true and .existing == false and .pushed == true and .input_consumed == true and .url == "https://example.invalid/pull/77"' <<<"$result" >/dev/null
    jq -e '.committed_scope.range == "origin/main...HEAD" and .committed_scope.files == ["feature.txt"]' <<<"$result" >/dev/null
    jq -e '.title == "Feature: preserve $title" and .body == "## Summary\n- Preserve $dollars and `backticks` literally." and .base == "main" and .head == "feature"' "$test_root/pr-create-gh.log" >/dev/null
    assert_equals "$head_sha" "$remote_sha" "PR pushed head"
    assert_equals "$head_sha" "$(git rev-parse HEAD)" "PR local head"
    [[ ! -e $body_path ]] || fail "successful PR creation must consume its managed body"
  )
}

test_pr_create_reports_github_error() {
  local repo status
  local stdout_file=$test_root/pr-create-error-stdout.json
  local stderr_file=$test_root/pr-create-error-stderr.json
  repo=$(make_repo pr-create-error)

  (
    cd "$repo"
    git switch --quiet -c feature
    printf 'feature\n' > feature.txt
    git add -- feature.txt
    git commit --quiet -m "feat: rejected PR"
    printf '## Summary\n- Rejected PR\n' > "$test_root/pr-create-error-body.md"

    set +e
    PATH="$mock_bin:$PATH" \
      MOCK_GH_CREATE_ERROR='GraphQL: simulated pull request rejection' \
      /bin/bash "$runner" pr-create \
        --base main \
        --title "Rejected PR" \
        --body-file "$test_root/pr-create-error-body.md" \
        >"$stdout_file" 2>"$stderr_file"
    status=$?
    set -e

    [[ $status -ne 0 ]] || fail "PR creation must propagate GitHub rejection"
    jq -e '
      .code == "pr_create_failed" and
      (.message | contains("GraphQL: simulated pull request rejection")) and
      .recoverable == true
    ' "$stderr_file" >/dev/null
  )
}

test_runner_omits_forbidden_publication_shortcuts
test_managed_input_prepare_and_discard
test_commit_consumes_managed_message_after_success
test_inspect_reports_separate_nul_safe_state
test_commit_uses_existing_index_without_push
test_commit_requires_index_fingerprint
test_commit_rejects_unrelated_staged_paths
test_commit_stages_only_requested_paths
test_commit_requires_explicit_all_changes_scope
test_commit_dry_run_does_not_mutate_index_or_head
test_commit_path_dry_run_reports_diff_without_message_file
test_commit_rejects_changed_index_fingerprint
test_commit_allows_an_explicit_tree_identical_merge
test_tree_identical_merge_flag_rejects_unsafe_states
test_push_sends_only_existing_commits
test_push_dry_run_rechecks_without_publishing
test_push_rejects_remote_race_and_divergence
test_push_allows_validated_remote_branch_override
test_pr_create_returns_existing_pr_without_mutation
test_pr_create_requires_dirty_exclusion_confirmation_and_supports_dry_run
test_pr_create_pushes_commits_and_uses_body_file
test_pr_create_reports_github_error

printf 'PASS: git runner\n'

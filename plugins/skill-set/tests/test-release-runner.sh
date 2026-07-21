#!/usr/bin/env bash

set -euo pipefail

test_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=/dev/null
source "$test_dir/test-helper.sh"

plugin_dir=$(cd "$test_dir/.." && pwd)
runner="$plugin_dir/bin/skill-set-release"
fixture_root=$(mktemp -d "${TMPDIR:-/tmp}/skill-set-release-test.XXXXXX")

cleanup_fixture() {
  rm -rf "$fixture_root"
}
trap cleanup_fixture EXIT

mkdir -p "$fixture_root/bin" "$fixture_root/tmp"
cat >"$fixture_root/bin/gh" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$fixture_root/bin/gh"
export PATH="$fixture_root/bin:$PATH"
export TMPDIR="$fixture_root/tmp"

mkdir -p "$fixture_root/no-gh-bin"
ln -s "$(command -v git)" "$fixture_root/no-gh-bin/git"
ln -s "$(command -v sed)" "$fixture_root/no-gh-bin/sed"
set +e
missing_gh_error=$(PATH="$fixture_root/no-gh-bin" /bin/bash "$runner" inspect --repo . 2>&1 >/dev/null)
missing_gh_status=$?
set -e
[[ "$missing_gh_status" -ne 0 ]] || fail "preflight should require gh by contract"
assert_equals "MISSING_DEPENDENCY" "$(printf '%s' "$missing_gh_error" | jq -r '.error.code')" "missing gh code"
printf '%s' "$missing_gh_error" | jq -e '.error.message | contains("gh")' >/dev/null || fail "missing gh detail"

prepare_with_preview() {
  target_repo=$1
  target_base=$2
  target_level=$3
  shift 3
  preview=$(/bin/bash "$runner" prepare --repo "$target_repo" --base "$target_base" \
    --level "$target_level" "$@" --dry-run)
  /bin/bash "$runner" prepare --repo "$target_repo" --base "$target_base" \
    --level "$target_level" "$@" \
    --expected-base-sha "$(printf '%s' "$preview" | jq -r '.base_sha')" \
    --expected-input-digest "$(printf '%s' "$preview" | jq -r '.input_digest')"
}

set +e
invalid_repo_error=$(/bin/bash "$runner" inspect --repo "$fixture_root/not-a-repo" 2>&1 >/dev/null)
invalid_repo_status=$?
set -e
[[ "$invalid_repo_status" -ne 0 ]] || fail "inspect should reject a non-repository"
assert_equals "NOT_A_REPOSITORY" "$(printf '%s' "$invalid_repo_error" | jq -r '.error.code')" "invalid repository code"
assert_equals "1" "$(printf '%s\n' "$invalid_repo_error" | wc -l | tr -d ' ')" "single structured error"

repo="$fixture_root/repo"
git init -q "$repo"
git -C "$repo" checkout -q -b main
git -C "$repo" config user.name "Release Test"
git -C "$repo" config user.email "release-test@example.com"
mkdir -p "$repo/plugins/example/.claude-plugin"
printf '{"name":"example","version":"1.1.0"}\n' >"$repo/plugins/example/.claude-plugin/plugin.json"
printf '{"name":"example","version":"1.0.0"}\n' >"$repo/package.json"
printf '# Changelog\n\n## [1.0.0] - 2025-01-01\n' >"$repo/CHANGELOG.md"
git -C "$repo" add -- plugins/example/.claude-plugin/plugin.json package.json CHANGELOG.md
git -C "$repo" commit -q -m "initial release"

result=$(/bin/bash "$runner" inspect --repo "$repo" --base main)

assert_equals "false" "$(printf '%s' "$result" | jq -r '.consistent')" "manifest consistency"
assert_equals "2" "$(printf '%s' "$result" | jq -r '.manifests | length')" "manifest count"
assert_equals "2" "$(printf '%s' "$result" | jq -r '.mismatches | length')" "mismatch count"

set +e
mismatch_error=$(/bin/bash "$runner" prepare --repo "$repo" --base main --level patch 2>&1 >/dev/null)
mismatch_status=$?
set -e
[[ "$mismatch_status" -ne 0 ]] || fail "prepare should reject mismatched manifests"
assert_equals "VERSION_MISMATCH" "$(printf '%s' "$mismatch_error" | jq -r '.error.code')" "mismatch error code"

repo_missing_changelog="$fixture_root/repo-missing-changelog"
git init -q "$repo_missing_changelog"
git -C "$repo_missing_changelog" checkout -q -b main
git -C "$repo_missing_changelog" config user.name "Release Test"
git -C "$repo_missing_changelog" config user.email "release-test@example.com"
printf '{"name":"example","version":"1.0.0"}\n' >"$repo_missing_changelog/package.json"
git -C "$repo_missing_changelog" add -- package.json
git -C "$repo_missing_changelog" commit -q -m "initial release"

set +e
missing_error=$(/bin/bash "$runner" prepare --repo "$repo_missing_changelog" --base main --level patch 2>&1 >/dev/null)
missing_status=$?
set -e

[[ "$missing_status" -ne 0 ]] || fail "prepare should reject a missing changelog"
assert_equals "CHANGELOG_MISSING" "$(printf '%s' "$missing_error" | jq -r '.error.code')" "missing changelog code"

repo_local="$fixture_root/repo-local"
git init -q "$repo_local"
git -C "$repo_local" checkout -q -b main
git -C "$repo_local" config user.name "Release Test"
git -C "$repo_local" config user.email "release-test@example.com"
printf '{"name":"local","version":"0.4.0"}\n' >"$repo_local/package.json"
printf '# Changelog\n\n## [0.4.0] - 2025-01-01\n' >"$repo_local/CHANGELOG.md"
git -C "$repo_local" add -- package.json CHANGELOG.md
git -C "$repo_local" commit -q -m "chore: bump version to 0.4.0"
local_prepare=$(prepare_with_preview "$repo_local" main patch)
local_state=$(printf '%s' "$local_prepare" | jq -r '.state_file')
assert_equals "0.4.1" "$(printf '%s' "$local_prepare" | jq -r '.version')" "local-only fallback version"
/bin/bash "$runner" cleanup --state-file "$local_state" --mode declined >/dev/null

repo_ready="$fixture_root/repo-ready"
origin_ready="$fixture_root/origin-ready.git"
git init -q --bare "$origin_ready"
git init -q "$repo_ready"
git -C "$repo_ready" checkout -q -b main
git -C "$repo_ready" config user.name "Release Test"
git -C "$repo_ready" config user.email "release-test@example.com"
mkdir -p "$repo_ready/plugins/example/.claude-plugin" "$repo_ready/evals/example/fixtures/.claude-plugin" \
  "$repo_ready/src/example" "$repo_ready/lib/example" "$repo_ready/docs"
printf '{"name":"example","version":"1.0.0"}\n' >"$repo_ready/plugins/example/.claude-plugin/plugin.json"
printf '{"name":"fixture","version":"9.9.9"}\n' >"$repo_ready/evals/example/fixtures/.claude-plugin/plugin.json"
printf '{"name":"example","version":"1.0.0"}\n' >"$repo_ready/package.json"
cat >"$repo_ready/AGENTS.md" <<'EOF'
## Versioning

- **Base branch**: main
- **Commit message**: release: {version}
- **Extra version files**: docs/version-info.txt
- **Changelog categories**: Added, Improved, Fixed
EOF
cat >"$repo_ready/pyproject.toml" <<'EOF'
[project]
name = "example"
version = "1.0.0"
EOF
cat >"$repo_ready/Cargo.toml" <<'EOF'
[package]
name = "example"
version = "1.0.0"
EOF
printf '__version__ = "1.0.0"\n' >"$repo_ready/src/example/__init__.py"
printf 'Gem::Specification.new do |spec|\n  spec.version = "1.0.0"\nend\n' >"$repo_ready/example.gemspec"
printf 'module Example\n  VERSION = "1.0.0"\nend\n' >"$repo_ready/lib/example/version.rb"
printf '1.0.0\n' >"$repo_ready/VERSION"
printf '1.0.0\n' >"$repo_ready/version.txt"
printf 'release_version = "1.0.0"\n' >"$repo_ready/docs/version-info.txt"
printf '# Changelog\n\n## [1.0.0] - 2025-01-01\n\n- Initial release.\n' >"$repo_ready/CHANGELOG.md"
git -C "$repo_ready" add -- plugins/example/.claude-plugin/plugin.json evals/example/fixtures/.claude-plugin/plugin.json \
  package.json pyproject.toml Cargo.toml src/example/__init__.py example.gemspec lib/example/version.rb \
  VERSION version.txt docs/version-info.txt CHANGELOG.md AGENTS.md
git -C "$repo_ready" commit -q -m "release: 1.0.0"
git -C "$repo_ready" remote add origin "$origin_ready"
git -C "$repo_ready" push -q -u origin main

remote_updater="$fixture_root/remote-updater"
git clone -q --branch main "$origin_ready" "$remote_updater"
git -C "$remote_updater" config user.name "Release Test"
git -C "$remote_updater" config user.email "release-test@example.com"
git -C "$remote_updater" commit -q --allow-empty -m "feat: remote snapshot feature"
git -C "$remote_updater" commit -q --allow-empty -m "fix: remote snapshot bug"
git -C "$remote_updater" push -q origin main
latest_remote_sha=$(git -C "$remote_updater" rev-parse HEAD)
printf '{"name":"example","version":"9.9.9"}\n' >"$repo_ready/package.json"
snapshot_result=$(/bin/bash "$runner" inspect --repo "$repo_ready" --base main)
assert_equals "$latest_remote_sha" "$(printf '%s' "$snapshot_result" | jq -r '.base_sha')" "fresh remote snapshot"
assert_equals "1.0.0" "$(printf '%s' "$snapshot_result" | jq -r '.current_version')" "dirty caller ignored"
assert_equals "2" "$(printf '%s' "$snapshot_result" | jq -r '.recent_commits | length')" \
  "configured release commit range"
git -C "$repo_ready" checkout -q -- package.json
git -C "$repo_ready" fetch -q origin main
git -C "$repo_ready" merge -q --ff-only origin/main

branches_before=$(git -C "$repo_ready" for-each-ref --format='%(refname)' refs/heads/skill-set/release- | wc -l | tr -d ' ')
dry_result=$(/bin/bash "$runner" prepare --repo "$repo_ready" --base main --level minor --dry-run)
branches_after=$(git -C "$repo_ready" for-each-ref --format='%(refname)' refs/heads/skill-set/release- | wc -l | tr -d ' ')

assert_equals "true" "$(printf '%s' "$dry_result" | jq -r '.dry_run')" "prepare dry-run marker"
assert_equals "1.1.0" "$(printf '%s' "$dry_result" | jq -r '.version')" "minor version"
assert_equals "$branches_before" "$branches_after" "dry-run branch count"
assert_equals "11" "$(printf '%s' "$dry_result" | jq -r '.changed_paths | length')" "dry-run changed paths"
[[ -n "$(printf '%s' "$dry_result" | jq -r '.input_digest')" ]] || fail "preview input digest"
printf '%s' "$dry_result" | jq -e '.changelog_entry | contains("### Added") and contains("### Fixed")' >/dev/null || \
  fail "configured changelog categories"
set +e
missing_cas_error=$(/bin/bash "$runner" prepare --repo "$repo_ready" --base main --level minor 2>&1 >/dev/null)
missing_cas_status=$?
set -e
[[ "$missing_cas_status" -ne 0 ]] || fail "non-dry prepare should require preview CAS"
assert_equals "EXPECTED_BASE_SHA_REQUIRED" "$(printf '%s' "$missing_cas_error" | jq -r '.error.code')" \
  "missing preview CAS code"

prepare_result=$(/bin/bash "$runner" prepare --repo "$repo_ready" --base main --level minor \
  --expected-base-sha "$(printf '%s' "$dry_result" | jq -r '.base_sha')" \
  --expected-input-digest "$(printf '%s' "$dry_result" | jq -r '.input_digest')")
state_file=$(printf '%s' "$prepare_result" | jq -r '.state_file')
worktree=$(printf '%s' "$prepare_result" | jq -r '.worktree')
release_branch=$(printf '%s' "$prepare_result" | jq -r '.branch')
prepared_commit=$(printf '%s' "$prepare_result" | jq -r '.commit_sha')

assert_file "$state_file"
[[ "$worktree" != "$repo_ready"/* ]] || fail "release worktree must be outside the repository"
[[ -d "$worktree" ]] || fail "prepared worktree should exist"
assert_equals "$prepared_commit" "$(git -C "$worktree" rev-parse HEAD)" "prepared commit"
assert_equals "$prepared_commit" "$(git -C "$repo_ready" rev-parse "refs/heads/$release_branch")" "prepared branch"
assert_equals "release: 1.1.0" "$(git -C "$worktree" log -1 --format='%s')" "configured commit message"
assert_equals "1.1.0" "$(jq -r '.version' "$worktree/package.json")" "package version"
assert_equals "1.1.0" "$(jq -r '.version' "$worktree/plugins/example/.claude-plugin/plugin.json")" "plugin version"
assert_equals "1.1.0" "$(awk -F'"' '/^version =/{print $2; exit}' "$worktree/pyproject.toml")" "pyproject version"
assert_equals "1.1.0" "$(awk -F'"' '/^version =/{print $2; exit}' "$worktree/Cargo.toml")" "cargo version"
assert_equals "1.1.0" "$(awk -F'"' '/__version__/ {print $2}' "$worktree/src/example/__init__.py")" "python version"
assert_equals "1.1.0" "$(awk -F'"' '/spec.version/ {print $2}' "$worktree/example.gemspec")" "gemspec version"
assert_equals "1.1.0" "$(awk -F'"' '/VERSION/ {print $2}' "$worktree/lib/example/version.rb")" "ruby version"
assert_equals "1.1.0" "$(sed -n '1p' "$worktree/VERSION")" "VERSION file"
assert_equals "1.1.0" "$(sed -n '1p' "$worktree/version.txt")" "version.txt file"
assert_equals "1.1.0" "$(awk -F'"' '/release_version/ {print $2}' "$worktree/docs/version-info.txt")" "extra version file"
assert_equals "11" "$(printf '%s' "$prepare_result" | jq -r '.changed_paths | length')" "prepared changed paths"
assert_equals "prepared" "$(jq -r '.status' "$state_file")" "prepared state"
[[ -n "$(jq -r '.diff' "$state_file")" ]] || fail "prepared state should retain the diff"
assert_equals "" "$(git -C "$worktree" status --porcelain)" "prepared worktree cleanliness"
assert_equals "1.0.0" "$(jq -r '.version' "$repo_ready/package.json")" "original checkout version"

decline_state_before=$(git hash-object "$state_file")
decline_dry=$(/bin/bash "$runner" cleanup --state-file "$state_file" --mode declined --dry-run)
assert_equals "true" "$(printf '%s' "$decline_dry" | jq -r '.dry_run')" "declined cleanup dry-run"
[[ -d "$worktree" ]] || fail "cleanup dry-run must preserve the worktree"
assert_equals "$decline_state_before" "$(git hash-object "$state_file")" "cleanup dry-run state"

decline_result=$(/bin/bash "$runner" cleanup --state-file "$state_file" --mode declined)
assert_equals "declined" "$(printf '%s' "$decline_result" | jq -r '.status')" "declined cleanup status"
[[ ! -d "$worktree" ]] || fail "declined cleanup should remove the worktree"
assert_equals "$prepared_commit" "$(git -C "$repo_ready" rev-parse "refs/heads/$release_branch")" "declined branch commit"
assert_equals "declined" "$(jq -r '.status' "$state_file")" "declined durable state"

race_prepare=$(prepare_with_preview "$repo_ready" main patch)
race_state=$(printf '%s' "$race_prepare" | jq -r '.state_file')
race_worktree=$(printf '%s' "$race_prepare" | jq -r '.worktree')
race_branch=$(printf '%s' "$race_prepare" | jq -r '.branch')
race_commit=$(printf '%s' "$race_prepare" | jq -r '.commit_sha')

printf 'base advanced\n' >"$repo_ready/base.txt"
git -C "$repo_ready" add -- base.txt
git -C "$repo_ready" commit -q -m "advance base"
git -C "$repo_ready" push -q origin main

set +e
race_error=$(/bin/bash "$runner" publish --state-file "$race_state" --expected-commit "$race_commit" --approve 2>&1 >/dev/null)
race_status=$?
set -e

[[ "$race_status" -ne 0 ]] || fail "publish should reject a changed remote base"
assert_equals "BASE_RACE" "$(printf '%s' "$race_error" | jq -r '.error.code')" "base race code"
[[ -d "$race_worktree" ]] || fail "base race should preserve the worktree"
assert_equals "$race_commit" "$(git -C "$repo_ready" rev-parse "refs/heads/$race_branch")" "base race branch"
assert_equals "prepared" "$(jq -r '.status' "$race_state")" "base race durable state"

failure_cleanup=$(/bin/bash "$runner" cleanup --state-file "$race_state" --mode failure)
assert_equals "true" "$(printf '%s' "$failure_cleanup" | jq -r '.preserved')" "failure cleanup preservation"
[[ -d "$race_worktree" ]] || fail "failure cleanup should preserve the worktree"

protected_prepare=$(prepare_with_preview "$repo_ready" main patch)
protected_state=$(printf '%s' "$protected_prepare" | jq -r '.state_file')
protected_worktree=$(printf '%s' "$protected_prepare" | jq -r '.worktree')
protected_branch=$(printf '%s' "$protected_prepare" | jq -r '.branch')
protected_commit=$(printf '%s' "$protected_prepare" | jq -r '.commit_sha')
cat >"$origin_ready/hooks/pre-receive" <<'EOF'
#!/bin/sh
echo "protected branch policy" >&2
exit 1
EOF
chmod +x "$origin_ready/hooks/pre-receive"

set +e
protected_error=$(/bin/bash "$runner" publish --state-file "$protected_state" --expected-commit "$protected_commit" --approve 2>&1 >/dev/null)
protected_status=$?
set -e

[[ "$protected_status" -ne 0 ]] || fail "publish should report protected-branch rejection"
assert_equals "PUSH_PROTECTED" "$(printf '%s' "$protected_error" | jq -r '.error.code')" "protected branch code"
assert_equals "prepared" "$(jq -r '.status' "$protected_state")" "protected branch durable state"
[[ -d "$protected_worktree" ]] || fail "protected failure should preserve worktree"
assert_equals "$protected_commit" "$(git -C "$repo_ready" rev-parse "refs/heads/$protected_branch")" "protected branch recovery"

set +e
approval_error=$(/bin/bash "$runner" publish --state-file "$protected_state" --expected-commit "$protected_commit" 2>&1 >/dev/null)
approval_status=$?
set -e
[[ "$approval_status" -ne 0 ]] || fail "publish should require explicit approval"
assert_equals "APPROVAL_REQUIRED" "$(printf '%s' "$approval_error" | jq -r '.error.code')" "approval required code"

forged_state="$fixture_root/forged-release-state.json"
cp "$protected_state" "$forged_state"
set +e
forged_error=$(/bin/bash "$runner" publish --state-file "$forged_state" --expected-commit "$protected_commit" --approve 2>&1 >/dev/null)
forged_status=$?
set -e
[[ "$forged_status" -ne 0 ]] || fail "publish should reject state outside the durable state directory"
assert_equals "UNTRUSTED_STATE_PATH" "$(printf '%s' "$forged_error" | jq -r '.error.code')" "untrusted state code"

auth_prepare=$(prepare_with_preview "$repo_ready" main patch)
auth_state=$(printf '%s' "$auth_prepare" | jq -r '.state_file')
auth_worktree=$(printf '%s' "$auth_prepare" | jq -r '.worktree')
auth_branch=$(printf '%s' "$auth_prepare" | jq -r '.branch')
auth_commit=$(printf '%s' "$auth_prepare" | jq -r '.commit_sha')
cat >"$origin_ready/hooks/pre-receive" <<'EOF'
#!/bin/sh
echo "Authentication failed for release bot" >&2
exit 1
EOF
chmod +x "$origin_ready/hooks/pre-receive"

set +e
auth_error=$(/bin/bash "$runner" publish --state-file "$auth_state" --expected-commit "$auth_commit" --approve 2>&1 >/dev/null)
auth_status=$?
set -e

[[ "$auth_status" -ne 0 ]] || fail "publish should report authentication rejection"
assert_equals "PUSH_AUTH_FAILED" "$(printf '%s' "$auth_error" | jq -r '.error.code')" "auth failure code"
assert_equals "prepared" "$(jq -r '.status' "$auth_state")" "auth failure durable state"
[[ -d "$auth_worktree" ]] || fail "auth failure should preserve worktree"
assert_equals "$auth_commit" "$(git -C "$repo_ready" rev-parse "refs/heads/$auth_branch")" "auth branch recovery"

rm "$origin_ready/hooks/pre-receive"
success_prepare=$(prepare_with_preview "$repo_ready" main patch)
success_state=$(printf '%s' "$success_prepare" | jq -r '.state_file')
success_worktree=$(printf '%s' "$success_prepare" | jq -r '.worktree')
success_branch=$(printf '%s' "$success_prepare" | jq -r '.branch')
success_commit=$(printf '%s' "$success_prepare" | jq -r '.commit_sha')
remote_before=$(git -C "$repo_ready" ls-remote origin refs/heads/main | awk '{print $1}')

publish_state_before=$(git hash-object "$success_state")
publish_dry=$(/bin/bash "$runner" publish --state-file "$success_state" --expected-commit "$success_commit" --approve --dry-run)
assert_equals "true" "$(printf '%s' "$publish_dry" | jq -r '.dry_run')" "publish dry-run marker"
assert_equals "$remote_before" "$(git -C "$repo_ready" ls-remote origin refs/heads/main | awk '{print $1}')" "publish dry-run remote"
assert_equals "$publish_state_before" "$(git hash-object "$success_state")" "publish dry-run state"

publish_result=$(/bin/bash "$runner" publish --state-file "$success_state" --expected-commit "$success_commit" --approve)
assert_equals "published" "$(printf '%s' "$publish_result" | jq -r '.status')" "publish status"
assert_equals "$success_commit" "$(git -C "$repo_ready" ls-remote origin refs/heads/main | awk '{print $1}')" "published remote commit"
assert_equals "published" "$(jq -r '.status' "$success_state")" "published durable state"
[[ -d "$success_worktree" ]] || fail "publish should retain worktree until explicit cleanup"

success_cleanup_state_before=$(git hash-object "$success_state")
success_cleanup_dry=$(/bin/bash "$runner" cleanup --state-file "$success_state" --mode success --dry-run)
assert_equals "true" "$(printf '%s' "$success_cleanup_dry" | jq -r '.dry_run')" "success cleanup dry-run"
assert_equals "$success_cleanup_state_before" "$(git hash-object "$success_state")" "success cleanup dry-run state"
[[ -d "$success_worktree" ]] || fail "success cleanup dry-run should preserve worktree"
assert_equals "$success_commit" "$(git -C "$repo_ready" rev-parse "refs/heads/$success_branch")" "success cleanup dry-run branch"

success_cleanup=$(/bin/bash "$runner" cleanup --state-file "$success_state" --mode success)
assert_equals "success" "$(printf '%s' "$success_cleanup" | jq -r '.status')" "success cleanup status"
[[ ! -d "$success_worktree" ]] || fail "successful cleanup should remove worktree"
if git -C "$repo_ready" show-ref --verify --quiet "refs/heads/$success_branch"; then
  fail "successful cleanup should remove the local release branch"
fi
assert_equals "success" "$(jq -r '.status' "$success_state")" "successful durable cleanup state"

managed_dir="$fixture_root/managed inputs"
mkdir -p "$managed_dir"
managed_dir=$(cd "$managed_dir" && pwd -P)
printf 'release: managed input\n' >"$managed_dir/message target.txt"
ln -s "message target.txt" "$managed_dir/message link.txt"
next_preview=$(/bin/bash "$runner" prepare --repo "$repo_ready" --base main --level patch --dry-run)
next_version=$(printf '%s' "$next_preview" | jq -r '.version')
printf '## [%s] - 2026-07-20\n\n### Fixed\n\n- Managed input test.\n' "$next_version" \
  >"$managed_dir/changelog target.md"
ln -s "changelog target.md" "$managed_dir/changelog link.md"
managed_preview=$(cd "$fixture_root" && /bin/bash "$runner" prepare --repo "$repo_ready" --base main \
  --level patch --message-file "managed inputs/message link.txt" \
  --changelog-file "managed inputs/changelog link.md" --dry-run)
assert_equals "$managed_dir/message target.txt" \
  "$(printf '%s' "$managed_preview" | jq -r '.managed_inputs.message_file')" "canonical message symlink"
assert_equals "$managed_dir/changelog target.md" \
  "$(printf '%s' "$managed_preview" | jq -r '.managed_inputs.changelog_file')" "canonical changelog symlink"
printf 'release: changed after preview\n' >"$managed_dir/message target.txt"
set +e
managed_race_error=$(cd "$fixture_root" && /bin/bash "$runner" prepare --repo "$repo_ready" --base main \
  --level patch --message-file "managed inputs/message link.txt" \
  --changelog-file "managed inputs/changelog link.md" \
  --expected-base-sha "$(printf '%s' "$managed_preview" | jq -r '.base_sha')" \
  --expected-input-digest "$(printf '%s' "$managed_preview" | jq -r '.input_digest')" 2>&1 >/dev/null)
managed_race_status=$?
set -e
[[ "$managed_race_status" -ne 0 ]] || fail "managed input race should stop prepare"
assert_equals "INPUT_CHANGED" "$(printf '%s' "$managed_race_error" | jq -r '.error.code')" "managed input race code"

printf 'release: managed input\n' >"$managed_dir/message target.txt"
managed_preview=$(cd "$fixture_root" && /bin/bash "$runner" prepare --repo "$repo_ready" --base main \
  --level patch --message-file "managed inputs/message link.txt" \
  --changelog-file "managed inputs/changelog link.md" --dry-run)
managed_prepare=$(cd "$fixture_root" && /bin/bash "$runner" prepare --repo "$repo_ready" --base main \
  --level patch --message-file "managed inputs/message link.txt" \
  --changelog-file "managed inputs/changelog link.md" \
  --expected-base-sha "$(printf '%s' "$managed_preview" | jq -r '.base_sha')" \
  --expected-input-digest "$(printf '%s' "$managed_preview" | jq -r '.input_digest')")
managed_state=$(printf '%s' "$managed_prepare" | jq -r '.state_file')
managed_worktree=$(printf '%s' "$managed_prepare" | jq -r '.worktree')
assert_equals "release: managed input" "$(git -C "$managed_worktree" log -1 --format='%s')" "owned message input"
/bin/bash "$runner" cleanup --state-file "$managed_state" --mode declined >/dev/null

base_preview=$(/bin/bash "$runner" prepare --repo "$repo_ready" --base main --level patch --dry-run)
base_race_updater="$fixture_root/base-race-updater"
git clone -q --branch main "$origin_ready" "$base_race_updater"
git -C "$base_race_updater" config user.name "Release Test"
git -C "$base_race_updater" config user.email "release-test@example.com"
git -C "$base_race_updater" commit -q --allow-empty -m "fix: advance after preview"
git -C "$base_race_updater" push -q origin main
set +e
preview_race_error=$(/bin/bash "$runner" prepare --repo "$repo_ready" --base main --level patch \
  --expected-base-sha "$(printf '%s' "$base_preview" | jq -r '.base_sha')" \
  --expected-input-digest "$(printf '%s' "$base_preview" | jq -r '.input_digest')" 2>&1 >/dev/null)
preview_race_status=$?
set -e
[[ "$preview_race_status" -ne 0 ]] || fail "preview base race should stop prepare"
assert_equals "BASE_RACE" "$(printf '%s' "$preview_race_error" | jq -r '.error.code')" "preview base race code"

hook_path="$(git -C "$repo_ready" rev-parse --absolute-git-dir)/hooks/pre-commit"
cat >"$hook_path" <<'EOF'
#!/usr/bin/env bash
set -eu
hook_root=$(git rev-parse --show-toplevel)
printf 'hook widened scope\n' >"$hook_root/hook-extra.txt"
git add -- hook-extra.txt
EOF
chmod +x "$hook_path"
hook_preview=$(/bin/bash "$runner" prepare --repo "$repo_ready" --base main --level patch --dry-run)
set +e
hook_error=$(/bin/bash "$runner" prepare --repo "$repo_ready" --base main --level patch \
  --expected-base-sha "$(printf '%s' "$hook_preview" | jq -r '.base_sha')" \
  --expected-input-digest "$(printf '%s' "$hook_preview" | jq -r '.input_digest')" 2>&1 >/dev/null)
hook_status=$?
set -e
rm "$hook_path"
[[ "$hook_status" -ne 0 ]] || fail "hook scope widening should stop prepare"
assert_equals "COMMIT_SCOPE_MISMATCH" "$(printf '%s' "$hook_error" | jq -r '.error.code')" "hook scope code"

reconcile_prepare=$(prepare_with_preview "$repo_ready" main patch)
reconcile_state=$(printf '%s' "$reconcile_prepare" | jq -r '.state_file')
reconcile_worktree=$(printf '%s' "$reconcile_prepare" | jq -r '.worktree')
reconcile_branch=$(printf '%s' "$reconcile_prepare" | jq -r '.branch')
reconcile_commit=$(printf '%s' "$reconcile_prepare" | jq -r '.commit_sha')
cat >"$fixture_root/bin/mv" <<'EOF'
#!/usr/bin/env bash
set -eu
destination=
for argument in "$@"; do destination=$argument; done
if [[ -n "${SKILL_SET_FAIL_STATE_DEST:-}" && "$destination" == "$SKILL_SET_FAIL_STATE_DEST" ]]; then
  exit 73
fi
exec /bin/mv "$@"
EOF
chmod +x "$fixture_root/bin/mv"
set +e
state_write_error=$(SKILL_SET_FAIL_STATE_DEST="$reconcile_state" /bin/bash "$runner" publish --state-file "$reconcile_state" \
  --expected-commit "$reconcile_commit" --approve 2>&1 >/dev/null)
state_write_status=$?
set -e
[[ "$state_write_status" -ne 0 ]] || fail "publish state write fault should be reported"
assert_equals "STATE_WRITE_FAILED" "$(printf '%s' "$state_write_error" | jq -r '.error.code')" "publish state fault code"
assert_equals "$reconcile_commit" "$(git -C "$repo_ready" ls-remote origin refs/heads/main | awk '{print $1}')" \
  "remote commit after state fault"
reconciled_publish=$(/bin/bash "$runner" publish --state-file "$reconcile_state" \
  --expected-commit "$reconcile_commit" --approve)
assert_equals "true" "$(printf '%s' "$reconciled_publish" | jq -r '.reconciled')" "publish reconciliation"

set +e
cleanup_state_error=$(SKILL_SET_FAIL_STATE_DEST="$reconcile_state" /bin/bash "$runner" \
  cleanup --state-file "$reconcile_state" --mode success 2>&1 >/dev/null)
cleanup_state_status=$?
set -e
[[ "$cleanup_state_status" -ne 0 ]] || fail "cleanup state write fault should be reported"
assert_equals "STATE_WRITE_FAILED" "$(printf '%s' "$cleanup_state_error" | jq -r '.error.code')" "cleanup state fault code"
[[ ! -d "$reconcile_worktree" ]] || fail "faulted cleanup should already remove worktree"
if git -C "$repo_ready" show-ref --verify --quiet "refs/heads/$reconcile_branch"; then
  fail "faulted cleanup should already remove exact branch"
fi
reconciled_cleanup=$(/bin/bash "$runner" cleanup --state-file "$reconcile_state" --mode success)
assert_equals "true" "$(printf '%s' "$reconciled_cleanup" | jq -r '.reconciled')" "cleanup reconciliation"

skill_file="$plugin_dir/skills/bumping-version/SKILL.md"
runner_source="$plugin_dir/skills/bumping-version/scripts/skill-set-release"
assert_file "$skill_file"
assert_executable "$runner"
if grep -Fq 'CLAUDE.md' "$runner_source"; then
  fail "release policy discovery must not depend on CLAUDE.md"
fi
grep -Fq 'AGENTS.md' "$runner_source" || \
  fail "release policy discovery must use the portable AGENTS.md contract"
grep -Fq 'scripts/skill-set-release' "$skill_file" || \
  fail "bumping-version should resolve its skill-local release runner"
! grep -Fq 'CLAUDE_PLUGIN_ROOT' "$skill_file" || \
  fail "bumping-version should not depend on a host plugin root"
for subcommand in inspect prepare publish cleanup; do
  grep -Eq "<release-runner>[[:space:]]+$subcommand" "$skill_file" || \
    fail "bumping-version should document $subcommand"
done
if grep -Eq 'git (add|commit|push|pull|rebase)|gh .*pr create|automatic PR|PR fallback' "$skill_file"; then
  fail "bumping-version should not contain direct Git mutation or automatic PR fallback"
fi
skill_lines=$(wc -l <"$skill_file" | tr -d ' ')
((skill_lines < 200)) || fail "bumping-version SKILL.md should remain under 200 lines"

printf 'PASS: release runner safety scenarios and cleanup contracts\n'

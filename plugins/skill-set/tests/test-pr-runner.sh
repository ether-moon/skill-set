#!/usr/bin/env bash

set -euo pipefail

test_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
plugin_dir=$(cd -- "$test_dir/.." && pwd)
runner=$plugin_dir/bin/skill-set-pr
bash_bin=/bin/bash
# shellcheck source=plugins/skill-set/tests/test-helper.sh
source "$test_dir/test-helper.sh"

tmp_root=$(mktemp -d "${TMPDIR:-/tmp}/skill-set-pr-test.XXXXXX")
trap 'rm -rf "$tmp_root"' EXIT
trap 'printf "FAIL: unexpected command failure at test-pr-runner.sh:%s\n" "$LINENO" >&2' ERR

assert_executable "$runner"

make_fixture() {
  local name=$1
  unset resolution_worktree
  case_dir=$tmp_root/$name
  repo=$case_dir/repo
  mock_bin=$case_dir/mock-bin
  mkdir -p "$repo" "$mock_bin"
  git -C "$repo" init -q
  git -C "$repo" config user.email test@example.com
  git -C "$repo" config user.name Test
  printf 'fixture\n' >"$repo/fixture.txt"
  git -C "$repo" add fixture.txt
  git -C "$repo" commit -qm fixture
  git -C "$repo" remote add origin https://example.test/owner/repo.git
  head_sha=$(git -C "$repo" rev-parse HEAD)
  new_sha=1111111111111111111111111111111111111111

  export MOCK_GH_SCENARIO=pass
  export MOCK_GH_HEAD=$head_sha
  export MOCK_GH_NEW_HEAD=$new_sha
  export MOCK_GH_BASE_SHA=$head_sha
  export MOCK_GH_HEAD_REPO=owner/repo
  export MOCK_GH_HEAD_BRANCH=feature
  export MOCK_GH_HOST=example.test
  export MOCK_GH_DIR=$case_dir/mock-state
  export MOCK_GH_LOG=$case_dir/gh.log
  export MOCK_GH_HEAD_FILE=$MOCK_GH_DIR/remote-head
  mkdir -p "$MOCK_GH_DIR"
  printf '%s\n' "$head_sha" >"$MOCK_GH_HEAD_FILE"
  : >"$MOCK_GH_LOG"

  cp "$test_dir/fixtures/mock-gh-pr" "$mock_bin/gh"
  cp "$test_dir/fixtures/mock-gh-pr" "$mock_bin/skill-set-git"
  chmod +x "$mock_bin/gh" "$mock_bin/skill-set-git"
  export SKILL_SET_GIT_RUNNER=$mock_bin/skill-set-git
  test_path=$mock_bin:$PATH
}

run_ok() {
  local output stderr_file=$case_dir/run-ok.stderr
  if ! output=$(cd "$repo" && PATH=$test_path "$bash_bin" "$runner" "$@" 2>"$stderr_file"); then
    command cat "$stderr_file" >&2
    fail "expected command to succeed: $*"
  fi
  [[ ! -s $stderr_file ]] || { command cat "$stderr_file" >&2; fail "success wrote to stderr: $*"; }
  jq -e '.ok == true' >/dev/null <<<"$output"
  printf '%s\n' "$output"
}

run_fail() {
  local stdout_file=$case_dir/stdout.json
  local stderr_file=$case_dir/stderr.json
  if (cd "$repo" && PATH=$test_path "$bash_bin" "$runner" "$@") >"$stdout_file" 2>"$stderr_file"; then
    fail "expected command to fail: $*"
  fi
  [[ ! -s "$stdout_file" ]] || fail "failure wrote to stdout: $*"
  jq -e '.ok == false and (.error.code | length > 0) and (.error.message | length > 0) and (.error.recovery | length > 0)' \
    "$stderr_file" >/dev/null
  cat "$stderr_file"
}

init_case() {
  run_ok init --pr 17 --repo owner/repo --ci-timeout-seconds 30 \
    --review-timeout-seconds 30 --now 100 "$@"
}

snapshot_case() {
  local state_file current_run
  state_file=$(git -C "$repo" rev-parse --git-common-dir)/skill-set/shipping-pr/17.json
  current_run=$(jq -r .run_id "$repo/$state_file")
  run_ok snapshot --pr 17 --expected-run-id "$current_run" --now "${1:-101}"
}

start_resolution() {
  local run_id=$1
  shift
  local target=${resolution_worktree:-$repo}
  local branch
  branch=$(git -C "$target" branch --show-current)
  run_ok transition --pr 17 --from blocked --to resolving --expected-run-id "$run_id" \
    --increment-cycle --worktree "$target" --resolver-branch "$branch" --remote origin \
    --remote-branch feature --expected-remote-sha "$head_sha" --base-sha "$head_sha" \
    --base-branch main --workspace-mode current "$@"
}

write_single_result() {
  local path=$1
  local agent=$2
  local result=$3
  local input_head=$4
  local output_head=$5
  jq -cn --arg agent "$agent" --arg result "$result" --arg input "$input_head" \
    --arg output "$output_head" \
    '{results:[{agent:$agent,result:$result,input_head:$input,output_head:$output}]}' >"$path"
}

publish_single_result() {
  local run_id=$1
  local expected_head=$2
  local local_head=$3
  local results_file=$4
  shift 4
  run_ok publish --pr 17 --expected-run-id "$run_id" --expected-head-sha "$expected_head" \
    --expected-local-head-sha "$local_head" --results-file "$results_file" "$@"
}

count_log() {
  local pattern=$1
  { grep -E "$pattern" "$MOCK_GH_LOG" || true; } | wc -l | tr -d ' '
}

make_fixture delayed
export MOCK_GH_SCENARIO=delayed
init_case >/dev/null
first=$(snapshot_case 101)
assert_equals polling "$(jq -r .status <<<"$first")" "delayed check state"
jq -e '
  (.schema_version == 2) and
  (["schema_version","run_id","repo","github_host","head_repo","head_branch","pr","head_sha",
      "cycle","deadlines","blocker_fingerprint","status"]
    - (keys) | length == 0)
' <<<"$first" >/dev/null
second=$(snapshot_case 102)
assert_equals clean "$(jq -r .status <<<"$second")" "eventual check state"

for scenario in fail cancel pending; do
  make_fixture "$scenario"
  export MOCK_GH_SCENARIO=$scenario
  init_case >/dev/null
  result=$(snapshot_case 101)
  expected=blocked
  [[ $scenario == pending ]] && expected=polling
  assert_equals "$expected" "$(jq -r .status <<<"$result")" "$scenario state"
  jq -e --arg bucket "$scenario" '.checks[$bucket] == 1' <<<"$result" >/dev/null
done

make_fixture all-checks
export MOCK_GH_SCENARIO=fail
init_case --required-only false >/dev/null
all_checks=$(snapshot_case 101)
assert_equals blocked "$(jq -r .status <<<"$all_checks")" "all-check failure state"
if grep -Eq '^pr checks .* --required( |$)' "$MOCK_GH_LOG"; then
  fail "--required-only false still passed --required to gh pr checks"
fi

make_fixture skipping
export MOCK_GH_SCENARIO=skipping
init_case >/dev/null
skipping=$(snapshot_case 101)
assert_equals clean "$(jq -r .status <<<"$skipping")" "skipping check state"

make_fixture no-required
export MOCK_GH_SCENARIO=no-required
init_case >/dev/null
no_required_wait=$(snapshot_case 101)
jq -e '.status == "polling" and (.checks | add) == 0' <<<"$no_required_wait" >/dev/null
no_required=$(snapshot_case 160)
jq -e '.status == "clean" and (.checks | add) == 0' <<<"$no_required" >/dev/null

make_fixture registration-delay
export MOCK_GH_SCENARIO=registration-delay
init_case >/dev/null
not_registered=$(snapshot_case 101)
assert_equals polling "$(jq -r .status <<<"$not_registered")" "check registration grace"
registered_pending=$(snapshot_case 110)
assert_equals polling "$(jq -r .status <<<"$registered_pending")" "registered pending check"
registered_pass=$(snapshot_case 120)
assert_equals clean "$(jq -r .status <<<"$registered_pass")" "registered passing check"

make_fixture conflict
export MOCK_GH_SCENARIO=conflict
init_case >/dev/null
conflict=$(snapshot_case 101)
jq -e '.status == "blocked" and .last_snapshot.conflict == true' <<<"$conflict" >/dev/null

make_fixture closed
export MOCK_GH_SCENARIO=closed
closed=$(init_case)
assert_equals closed "$(jq -r .status <<<"$closed")" "closed PR initialization"

make_fixture default-timeouts
defaults=$(run_ok init --pr 17 --repo owner/repo --now 100)
jq -e '.options.review_timeout_seconds == 600 and .deadlines.review_epoch == 700' \
  <<<"$defaults" >/dev/null

make_fixture reviewer-override-rejected
reviewer_override=$(run_fail init --pr 17 --repo owner/repo --now 100 --coderabbit-required false)
assert_equals invalid_argument "$(jq -r .error.code <<<"$reviewer_override")" \
  "reviewer adapters are always auto-detected"

make_fixture timeout
export MOCK_GH_SCENARIO=pending
init_case --ci-timeout-seconds 5 >/dev/null
timed_out=$(snapshot_case 106)
assert_equals timed_out "$(jq -r .status <<<"$timed_out")" "pending timeout state"

make_fixture pagination
export MOCK_GH_SCENARIO=pagination
init_case >/dev/null
paginated=$(snapshot_case 101)
assert_equals blocked "$(jq -r .status <<<"$paginated")" "paginated review state"
assert_equals 1 "$(jq -r .unresolved_actionable_threads <<<"$paginated")" "page-two unresolved thread"
assert_equals 2 "$(count_log 'api graphql')" "GraphQL page count"

make_fixture head-change
export MOCK_GH_SCENARIO=head-change
init_case >/dev/null
changed=$(snapshot_case 120)
jq -e --arg sha "$new_sha" '.head_changed == true and .head_sha == $sha and .status == "clean"' \
  <<<"$changed" >/dev/null
state_file=$(git -C "$repo" rev-parse --git-common-dir)/skill-set/shipping-pr/17.json
jq -e --arg sha "$new_sha" '.head_sha == $sha and .deadlines.checks_epoch == 150 and .deadlines.review_epoch == 150' \
  "$repo/$state_file" >/dev/null

make_fixture head-race
export MOCK_GH_SCENARIO=head-race
init_case >/dev/null
raced=$(snapshot_case 120)
jq -e --arg sha "$new_sha" '.head_changed == true and .head_sha == $sha and .status == "polling" and .discarded == true' \
  <<<"$raced" >/dev/null

make_fixture close-race
export MOCK_GH_SCENARIO=close-race
init_case >/dev/null
closed_during_snapshot=$(snapshot_case 120)
assert_equals closed "$(jq -r .status <<<"$closed_during_snapshot")" "close-during-snapshot state"

make_fixture unresolved
export MOCK_GH_SCENARIO=unresolved
init_case >/dev/null
unresolved=$(snapshot_case 101)
jq -e '.status == "blocked" and .unresolved_actionable_threads == 1' <<<"$unresolved" >/dev/null

make_fixture praise-only
export MOCK_GH_SCENARIO=praise-only
init_case >/dev/null
praise_only=$(snapshot_case 101)
jq -e '.status == "clean" and .unresolved_actionable_threads == 0 and
  (.review_threads | length) == 0' <<<"$praise_only" >/dev/null

make_fixture praise-with-request
export MOCK_GH_SCENARIO=praise-with-request
init_case >/dev/null
praise_request=$(snapshot_case 101)
jq -e '.status == "blocked" and .unresolved_actionable_threads == 1 and
  .review_threads[0].latest_comment.body == "LGTM, but please fix this"' \
  <<<"$praise_request" >/dev/null

make_fixture wrong-remote-binding
export MOCK_GH_SCENARIO=fail
initialized=$(init_case)
run_id=$(jq -r .run_id <<<"$initialized")
snapshot_case 101 >/dev/null
git -C "$repo" remote add wrong https://example.test/attacker/repo.git
resolver_branch=$(git -C "$repo" branch --show-current)
: >"$MOCK_GH_LOG"
wrong_remote=$(run_fail transition --pr 17 --from blocked --to resolving \
  --expected-run-id "$run_id" --increment-cycle --worktree "$repo" \
  --resolver-branch "$resolver_branch" --remote wrong --remote-branch feature \
  --expected-remote-sha "$head_sha" --base-sha "$head_sha" --base-branch main \
  --workspace-mode current \
  --resolver-agent ci-failure-resolver)
assert_equals remote_binding_mismatch "$(jq -r .error.code <<<"$wrong_remote")" \
  "wrong remote repository binding"
assert_equals 0 "$(count_log '^push ')" "wrong remote push count"
assert_equals 0 "$(count_log '^pr comment ')" "wrong remote comment count"

make_fixture workspace-mode-required
export MOCK_GH_SCENARIO=fail
initialized=$(init_case)
run_id=$(jq -r .run_id <<<"$initialized")
snapshot_case 101 >/dev/null
resolver_branch=$(git -C "$repo" branch --show-current)
missing_workspace_mode=$(run_fail transition --pr 17 --from blocked --to resolving \
  --expected-run-id "$run_id" --increment-cycle --worktree "$repo" \
  --resolver-branch "$resolver_branch" --remote origin --remote-branch feature \
  --expected-remote-sha "$head_sha" --base-sha "$head_sha" --base-branch main \
  --resolver-agent ci-failure-resolver)
assert_equals resolution_metadata_required "$(jq -r .error.code <<<"$missing_workspace_mode")" \
  "workspace mode requirement"

invalid_workspace_mode=$(run_fail transition --pr 17 --from blocked --to resolving \
  --expected-run-id "$run_id" --increment-cycle --worktree "$repo" \
  --resolver-branch "$resolver_branch" --remote origin --remote-branch feature \
  --expected-remote-sha "$head_sha" --base-sha "$head_sha" --base-branch main \
  --workspace-mode temporary \
  --resolver-agent ci-failure-resolver)
assert_equals invalid_workspace_mode "$(jq -r .error.code <<<"$invalid_workspace_mode")" \
  "workspace mode validation"

workspace_resolution=$(run_ok transition --pr 17 --from blocked --to resolving \
  --expected-run-id "$run_id" --increment-cycle --worktree "$repo" \
  --resolver-branch "$resolver_branch" --remote origin --remote-branch feature \
  --expected-remote-sha "$head_sha" --base-sha "$head_sha" --base-branch main \
  --workspace-mode current \
  --resolver-agent ci-failure-resolver)
assert_equals current "$(jq -r .resolution.workspace_mode <<<"$workspace_resolution")" \
  "persisted workspace mode"

state_file=$(git -C "$repo" rev-parse --git-common-dir)/skill-set/shipping-pr/17.json
jq 'del(.resolution.workspace_mode)' "$repo/$state_file" >"$repo/$state_file.tmp"
mv "$repo/$state_file.tmp" "$repo/$state_file"
legacy_workspace_resume=$(run_ok init --pr 17 --repo owner/repo --resume)
assert_equals current "$(jq -r .resolution.workspace_mode <<<"$legacy_workspace_resume")" \
  "legacy current-worktree recovery"

jq '.resolution.workspace_mode = "temporary"' "$repo/$state_file" >"$repo/$state_file.tmp"
mv "$repo/$state_file.tmp" "$repo/$state_file"
invalid_workspace_resume=$(run_fail init --pr 17 --repo owner/repo --resume)
assert_equals invalid_state "$(jq -r .error.code <<<"$invalid_workspace_resume")" \
  "recovery workspace mode enforcement"

make_fixture wrong-branch-binding
export MOCK_GH_SCENARIO=fail
initialized=$(init_case)
run_id=$(jq -r .run_id <<<"$initialized")
snapshot_case 101 >/dev/null
resolver_branch=$(git -C "$repo" branch --show-current)
: >"$MOCK_GH_LOG"
wrong_branch=$(run_fail transition --pr 17 --from blocked --to resolving \
  --expected-run-id "$run_id" --increment-cycle --worktree "$repo" \
  --resolver-branch "$resolver_branch" --remote origin --remote-branch different-feature \
  --expected-remote-sha "$head_sha" --base-sha "$head_sha" --base-branch main \
  --workspace-mode current \
  --resolver-agent ci-failure-resolver)
assert_equals head_branch_mismatch "$(jq -r .error.code <<<"$wrong_branch")" \
  "wrong PR head branch binding"
assert_equals 0 "$(count_log '^push ')" "wrong branch push count"
assert_equals 0 "$(count_log '^pr comment ')" "wrong branch comment count"

make_fixture live-head-branch-drift
export MOCK_GH_SCENARIO=fail
initialized=$(init_case)
run_id=$(jq -r .run_id <<<"$initialized")
snapshot_case 101 >/dev/null
export MOCK_GH_HEAD_BRANCH=renamed-feature
resolver_branch=$(git -C "$repo" branch --show-current)
: >"$MOCK_GH_LOG"
live_branch_drift=$(run_fail transition --pr 17 --from blocked --to resolving \
  --expected-run-id "$run_id" --increment-cycle --worktree "$repo" \
  --resolver-branch "$resolver_branch" --remote origin --remote-branch feature \
  --expected-remote-sha "$head_sha" --base-sha "$head_sha" --base-branch main \
  --workspace-mode current \
  --resolver-agent ci-failure-resolver)
assert_equals pr_head_binding_changed "$(jq -r .error.code <<<"$live_branch_drift")" \
  "live PR head branch revalidation"
assert_equals 0 "$(count_log '^push ')" "live branch drift push count"
assert_equals 0 "$(count_log '^pr comment ')" "live branch drift comment count"

make_fixture fork-head-binding
export MOCK_GH_SCENARIO=fail
export MOCK_GH_HEAD_REPO=contributor/repo
git -C "$repo" remote add fork https://example.test/contributor/repo.git
initialized=$(init_case)
run_id=$(jq -r .run_id <<<"$initialized")
snapshot_case 101 >/dev/null
resolver_branch=$(git -C "$repo" branch --show-current)
fork_resolution=$(run_ok transition --pr 17 --from blocked --to resolving \
  --expected-run-id "$run_id" --increment-cycle --worktree "$repo" \
  --resolver-branch "$resolver_branch" --remote fork --remote-branch feature \
  --expected-remote-sha "$head_sha" --base-sha "$head_sha" --base-branch main \
  --workspace-mode current \
  --resolver-agent ci-failure-resolver)
jq -e '.head_repo == "contributor/repo" and .head_branch == "feature" and
  .resolution.head_repo == "contributor/repo" and .resolution.remote == "fork" and
  .resolution.remote_branch == "feature"' <<<"$fork_resolution" >/dev/null

make_fixture coderabbit
export MOCK_GH_SCENARIO=coderabbit-delay
init_case >/dev/null
cr_pending=$(snapshot_case 101)
jq -e '.status == "clean" and .reviewers.states.coderabbit == "pending" and
  .reviewers.required.coderabbit == false' <<<"$cr_pending" >/dev/null

make_fixture coderabbit-timeout
export MOCK_GH_SCENARIO=coderabbit-delay
init_case --review-timeout-seconds 5 >/dev/null
cr_timeout=$(snapshot_case 106)
jq -e '.status == "clean" and .reviewers.states.coderabbit == "pending" and
  .reviewers.required.coderabbit == false' <<<"$cr_timeout" >/dev/null

make_fixture coderabbit-auto
export MOCK_GH_SCENARIO=coderabbit-active
auto_init=$(init_case)
assert_equals true "$(jq -r '.reviewers.active | index("coderabbit") != null' <<<"$auto_init")" \
  "CodeRabbit auto-detection"
auto_run_id=$(jq -r .run_id <<<"$auto_init")
auto_snapshot=$(run_ok snapshot --pr 17 --expected-run-id "$auto_run_id" --now 101)
jq -e '
  .status == "clean" and
  .checks.pass == 1 and
  .unresolved_actionable_threads == 0 and
  .reviewers.states.coderabbit == "not_expected" and
  .reviewers.required.coderabbit == false
' <<<"$auto_snapshot" >/dev/null

make_fixture reviewers-auto
export MOCK_GH_SCENARIO=reviewers-active
reviewers_init=$(init_case)
jq -e '
  .options.reviewer_detection == "auto" and
  .reviewers.active == ["claude","coderabbit","codex"]
' <<<"$reviewers_init" >/dev/null
reviewers_run_id=$(jq -r .run_id <<<"$reviewers_init")
reviewers_snapshot=$(run_ok snapshot --pr 17 --expected-run-id "$reviewers_run_id" --now 101)
jq -e '
  .status == "clean" and
  .reviewers.states.claude == "success" and
  .reviewers.states.coderabbit == "success" and
  .reviewers.states.codex == "success"
' <<<"$reviewers_snapshot" >/dev/null

make_fixture codex-reaction
export MOCK_GH_SCENARIO=codex-reaction
codex_reaction_init=$(init_case)
codex_reaction_run_id=$(jq -r .run_id <<<"$codex_reaction_init")
codex_reaction_snapshot=$(run_ok snapshot --pr 17 --expected-run-id "$codex_reaction_run_id" --now 101)
jq -e '.status == "clean" and .reviewers.states.codex == "success"' \
  <<<"$codex_reaction_snapshot" >/dev/null

make_fixture claude-review
export MOCK_GH_SCENARIO=claude-review
claude_review_init=$(init_case)
claude_review_run_id=$(jq -r .run_id <<<"$claude_review_init")
claude_review_snapshot=$(run_ok snapshot --pr 17 --expected-run-id "$claude_review_run_id" --now 101)
jq -e '.status == "clean" and .reviewers.states.claude == "success"' \
  <<<"$claude_review_snapshot" >/dev/null

make_fixture coderabbit-check
export MOCK_GH_SCENARIO=coderabbit-check-delay
init_case >/dev/null
cr_check_pending=$(snapshot_case 101)
jq -e '.status == "clean" and .reviewers.states.coderabbit == "pending" and
  .reviewers.required.coderabbit == false' <<<"$cr_check_pending" >/dev/null

make_fixture coderabbit-failure
export MOCK_GH_SCENARIO=coderabbit-failure
init_case >/dev/null
cr_failed=$(snapshot_case 101)
jq -e '.status == "clean" and .reviewers.states.coderabbit == "failed" and
  .reviewers.required.coderabbit == false' <<<"$cr_failed" >/dev/null

make_fixture no-progress
export MOCK_GH_SCENARIO=fail
initialized=$(init_case)
run_id=$(jq -r .run_id <<<"$initialized")
blocked=$(snapshot_case 101)
fingerprint=$(jq -r .blocker_fingerprint <<<"$blocked")
start_resolution "$run_id" --resolver-agent ci-failure-resolver >/dev/null
results_file=$repo/resolver-results.json
write_single_result "$results_file" ci-failure-resolver no-op "$head_sha" "$head_sha"
publish_single_result "$run_id" "$head_sha" "$head_sha" "$results_file" >/dev/null
run_ok transition --pr 17 --from resolving --to polling --expected-run-id "$run_id" \
  --resolver-attempt --resolver-result no-op >/dev/null
stalled=$(snapshot_case 102)
assert_equals stalled "$(jq -r .status <<<"$stalled")" "post-resolver no-progress state"
assert_equals "$fingerprint" "$(jq -r .blocker_fingerprint <<<"$stalled")" "no-progress fingerprint"

make_fixture progress-guard
export MOCK_GH_SCENARIO=thread-change
initialized=$(init_case)
run_id=$(jq -r .run_id <<<"$initialized")
blocked=$(snapshot_case 101)
fingerprint=$(jq -r .blocker_fingerprint <<<"$blocked")
start_resolution "$run_id" --resolver-agent pr-review-feedback >/dev/null
results_file=$repo/resolver-results.json
thread_feedback_file=$repo/thread-feedback.json
write_single_result "$results_file" pr-review-feedback no-op "$head_sha" "$head_sha"
jq -cn '{threads:[{id:"thread-1",outcome:"unresolved",body:"This request remains unresolved."}]}' \
  >"$thread_feedback_file"
publish_single_result "$run_id" "$head_sha" "$head_sha" "$results_file" \
  --thread-feedback-file "$thread_feedback_file" >/dev/null
run_ok transition --pr 17 --from resolving --to polling --expected-run-id "$run_id" \
  --resolver-attempt --resolver-result no-op >/dev/null
review_progress=$(snapshot_case 102)
assert_equals blocked "$(jq -r .status <<<"$review_progress")" "changed review remains actionable"
[[ $(jq -r .blocker_fingerprint <<<"$review_progress") != "$fingerprint" ]] || \
  fail "changed review content did not change fingerprint"

make_fixture check-identity
export MOCK_GH_SCENARIO=fail-a
initialized=$(init_case)
run_id=$(jq -r .run_id <<<"$initialized")
first_failure=$(snapshot_case 101)
first_fingerprint=$(jq -r .blocker_fingerprint <<<"$first_failure")
run_ok transition --pr 17 --from blocked --to polling --expected-run-id "$run_id" >/dev/null
export MOCK_GH_SCENARIO=fail-b
second_failure=$(snapshot_case 102)
[[ $(jq -r .blocker_fingerprint <<<"$second_failure") != "$first_fingerprint" ]] || \
  fail "swapped check identity did not change fingerprint"

make_fixture partial-resolver
export MOCK_GH_SCENARIO=fail
initialized=$(init_case)
run_id=$(jq -r .run_id <<<"$initialized")
snapshot_case 101 >/dev/null
start_resolution "$run_id" --resolver-agent ci-failure-resolver >/dev/null
partial=$(run_fail transition --pr 17 --from resolving --to polling --expected-run-id "$run_id" \
  --resolver-attempt --resolver-result partial-failure)
assert_equals unsafe_publication "$(jq -r .error.code <<<"$partial")" "partial resolver publication guard"

missing_result=$(run_fail transition --pr 17 --from resolving --to polling --expected-run-id "$run_id" \
  --resolver-attempt)
assert_equals resolver_result_required "$(jq -r .error.code <<<"$missing_result")" "resolver result requirement"

results_file=$repo/resolver-results.json
write_single_result "$results_file" ci-failure-resolver partial-failure "$head_sha" "$head_sha"
: >"$MOCK_GH_LOG"
unsafe_gate=$(run_fail publish --pr 17 --expected-run-id "$run_id" --expected-head-sha "$head_sha" \
  --expected-local-head-sha "$head_sha" --results-file "$results_file")
assert_equals unsafe_publication "$(jq -r .error.code <<<"$unsafe_gate")" "partial resolver executable gate"
assert_equals 0 "$(count_log '^push ')" "partial resolver push count"
assert_equals 0 "$(count_log '^pr comment ')" "partial resolver comment count"
awaiting=$(run_ok transition --pr 17 --from resolving --to awaiting_user --expected-run-id "$run_id" \
  --resolver-attempt --resolver-result partial-failure)
jq -e --arg path "$repo" '
  .status == "awaiting_user" and .resolution.worktree == $path and
  .resolution.branch != "" and .resolution.result == "partial-failure"
' <<<"$awaiting" >/dev/null
resumed_awaiting=$(run_ok init --pr 17 --repo owner/repo --resume)
jq -e --arg path "$repo" '.resumed == true and .status == "awaiting_user" and .resolution.worktree == $path' \
  <<<"$resumed_awaiting" >/dev/null

make_fixture stale-resolver-retry
export MOCK_GH_SCENARIO=fail
initialized=$(init_case)
run_id=$(jq -r .run_id <<<"$initialized")
snapshot_case 101 >/dev/null
start_resolution "$run_id" --resolver-agent ci-failure-resolver >/dev/null
stale_retry=$(run_ok transition --pr 17 --from resolving --to polling \
  --expected-run-id "$run_id" --resolver-attempt --resolver-result stale)
jq -e '.status == "polling" and .resolver_attempt.result == "stale" and
  .resolution.result == "stale" and .resolution.publication.phase == "pending"' \
  <<<"$stale_retry" >/dev/null

for dirty_kind in untracked unstaged staged metachar; do
  make_fixture "publication-dirty-$dirty_kind"
  export MOCK_GH_SCENARIO=fail
  initialized=$(init_case)
  run_id=$(jq -r .run_id <<<"$initialized")
  snapshot_case 101 >/dev/null
  start_resolution "$run_id" --resolver-agent ci-failure-resolver >/dev/null
  results_file=$repo/resolver-results.json
  [[ $dirty_kind != metachar ]] || results_file=$repo/'*'
  write_single_result "$results_file" ci-failure-resolver no-op "$head_sha" "$head_sha"
  case "$dirty_kind" in
    untracked) printf 'leftover\n' >"$repo/leftover.txt" ;;
    unstaged) printf 'leftover\n' >>"$repo/fixture.txt" ;;
    staged)
      printf 'leftover\n' >>"$repo/fixture.txt"
      git -C "$repo" add fixture.txt
      ;;
    metachar) printf 'leftover\n' >"$repo/must-not-be-excluded.txt" ;;
  esac
  : >"$MOCK_GH_LOG"
  dirty_gate=$(run_fail publish --pr 17 --expected-run-id "$run_id" \
    --expected-head-sha "$head_sha" --expected-local-head-sha "$head_sha" \
    --results-file "$results_file")
  assert_equals incomplete_resolver_worktree "$(jq -r .error.code <<<"$dirty_gate")" \
    "$dirty_kind publication boundary"
  assert_equals 0 "$(count_log '^push ')" "$dirty_kind publication push count"
  assert_equals 0 "$(count_log '^pr comment ')" "$dirty_kind publication comment count"
  state_file=$(git -C "$repo" rev-parse --git-common-dir)/skill-set/shipping-pr/17.json
  jq -e '.status == "resolving" and .resolution.publication.phase == "pending"' \
    "$repo/$state_file" >/dev/null
done

make_fixture publication-remote-drift
export MOCK_GH_SCENARIO=fail
initialized=$(init_case)
run_id=$(jq -r .run_id <<<"$initialized")
snapshot_case 101 >/dev/null
resolution_worktree=$case_dir/resolver-worktree
git -C "$repo" worktree add -q -b resolver-remote-drift "$resolution_worktree" "$head_sha"
printf 'resolved\n' >>"$resolution_worktree/fixture.txt"
git -C "$resolution_worktree" add fixture.txt
git -C "$resolution_worktree" commit -qm 'fix: resolver remote drift'
local_head=$(git -C "$resolution_worktree" rev-parse HEAD)
start_resolution "$run_id" --resolver-agent ci-failure-resolver >/dev/null
results_file=$resolution_worktree/resolver-results.json
write_single_result "$results_file" ci-failure-resolver success "$head_sha" "$local_head"
git -C "$repo" remote set-url origin https://example.test/attacker/repo.git
: >"$MOCK_GH_LOG"
remote_drift=$(run_fail publish --pr 17 --expected-run-id "$run_id" \
  --expected-head-sha "$head_sha" --expected-local-head-sha "$local_head" \
  --results-file "$results_file")
assert_equals remote_binding_mismatch "$(jq -r .error.code <<<"$remote_drift")" \
  "publication remote revalidation"
assert_equals 0 "$(count_log '^push ')" "remote drift push count"
assert_equals 0 "$(count_log '^pr comment ')" "remote drift comment count"
state_file=$(git -C "$repo" rev-parse --git-common-dir)/skill-set/shipping-pr/17.json
jq -e '.status == "resolving" and .resolution.publication.phase == "pending"' \
  "$repo/$state_file" >/dev/null

make_fixture publication-remote-race
export MOCK_GH_SCENARIO=fail
initialized=$(init_case)
run_id=$(jq -r .run_id <<<"$initialized")
snapshot_case 101 >/dev/null
resolution_worktree=$case_dir/resolver-worktree
git -C "$repo" worktree add -q -b resolver-remote-race "$resolution_worktree" "$head_sha"
printf 'resolved\n' >>"$resolution_worktree/fixture.txt"
git -C "$resolution_worktree" add fixture.txt
git -C "$resolution_worktree" commit -qm 'fix: resolver remote race'
local_head=$(git -C "$resolution_worktree" rev-parse HEAD)
start_resolution "$run_id" --resolver-agent ci-failure-resolver >/dev/null
results_file=$resolution_worktree/resolver-results.json
write_single_result "$results_file" ci-failure-resolver success "$head_sha" "$local_head"
export MOCK_GH_SCENARIO=publication-remote-race
: >"$MOCK_GH_LOG"
remote_race=$(run_fail publish --pr 17 --expected-run-id "$run_id" \
  --expected-head-sha "$head_sha" --expected-local-head-sha "$local_head" \
  --results-file "$results_file")
assert_equals remote_binding_mismatch "$(jq -r .error.code <<<"$remote_race")" \
  "immediate pre-push remote revalidation"
assert_equals 0 "$(count_log '^push ')" "remote race push count"
assert_equals 0 "$(count_log '^pr comment ')" "remote race comment count"
state_file=$(git -C "$repo" rev-parse --git-common-dir)/skill-set/shipping-pr/17.json
jq -e '.status == "resolving" and .resolution.publication.phase == "prepared"' \
  "$repo/$state_file" >/dev/null

make_fixture publication-success
export MOCK_GH_SCENARIO=fail
initialized=$(init_case)
run_id=$(jq -r .run_id <<<"$initialized")
snapshot_case 101 >/dev/null
resolution_worktree=$case_dir/resolver-worktree
git -C "$repo" worktree add -q -b resolver-publication "$resolution_worktree" "$head_sha"
printf 'resolved\n' >>"$resolution_worktree/fixture.txt"
git -C "$resolution_worktree" add fixture.txt
git -C "$resolution_worktree" commit -qm 'fix: resolve check'
local_head=$(git -C "$resolution_worktree" rev-parse HEAD)
start_resolution "$run_id" --resolver-agent ci-failure-resolver >/dev/null
resumed_resolving=$(run_ok init --pr 17 --repo owner/repo --resume)
jq -e --arg path "$resolution_worktree" --arg base "$head_sha" '
  .resumed == true and .status == "resolving" and .resolution.worktree == $path and
  .resolution.base_sha == $base and .resolution.publication.phase == "pending"
' <<<"$resumed_resolving" >/dev/null
results_file=$resolution_worktree/resolver-results.json
summary_file=$resolution_worktree/summary.md
write_single_result "$results_file" ci-failure-resolver success "$head_sha" "$local_head"
printf 'Resolved the failing check.\n' >"$summary_file"
publication_required=$(run_fail transition --pr 17 --from resolving --to polling \
  --expected-run-id "$run_id" --resolver-attempt --resolver-result success)
assert_equals publication_required "$(jq -r .error.code <<<"$publication_required")" "publication gate requirement"
export MOCK_GH_SCENARIO=publication
: >"$MOCK_GH_LOG"
published=$(publish_single_result "$run_id" "$head_sha" "$local_head" "$results_file" \
  --summary-file "$summary_file")
jq -e --arg sha "$local_head" '
  .resolution.publication.phase == "complete" and
  .resolution.publication.pushed == true and
  .resolution.publication.comments_published == 1 and
  .resolution.publication.final_remote_sha == $sha
' <<<"$published" >/dev/null
assert_equals 1 "$(count_log '^push --remote origin --remote-branch feature --expected-remote-sha ')" \
  "single expected-SHA push"
assert_equals 1 "$(count_log '^pr comment ')" "single post-push comment"
push_line=$(grep -En '^push ' "$MOCK_GH_LOG" | cut -d: -f1)
comment_line=$(grep -En '^pr comment ' "$MOCK_GH_LOG" | cut -d: -f1)
[[ $push_line -lt $comment_line ]] || fail "comment was published before the expected-SHA push"
grep -Eq '^<!-- skill-set-pr:' "$MOCK_GH_DIR/comment.body"
log_lines=$(wc -l <"$MOCK_GH_LOG" | tr -d ' ')
publish_single_result "$run_id" "$head_sha" "$local_head" "$results_file" \
  --summary-file "$summary_file" >/dev/null
assert_equals "$log_lines" "$(wc -l <"$MOCK_GH_LOG" | tr -d ' ')" "completed publication idempotency"
state_file=$(git -C "$repo" rev-parse --git-common-dir)/skill-set/shipping-pr/17.json
jq '.resolution.publication.phase = "commenting"' "$repo/$state_file" >"$repo/$state_file.tmp"
mv "$repo/$state_file.tmp" "$repo/$state_file"
push_count=$(count_log '^push ')
comment_count=$(count_log '^pr comment ')
publish_single_result "$run_id" "$head_sha" "$local_head" "$results_file" \
  --summary-file "$summary_file" >/dev/null
assert_equals "$push_count" "$(count_log '^push ')" "crash recovery duplicate push"
assert_equals "$comment_count" "$(count_log '^pr comment ')" "crash recovery duplicate comment"
run_ok transition --pr 17 --from resolving --to polling --expected-run-id "$run_id" \
  --resolver-attempt --resolver-result success >/dev/null

make_fixture publication-no-code
export MOCK_GH_SCENARIO=unresolved
initialized=$(init_case)
run_id=$(jq -r .run_id <<<"$initialized")
snapshot_case 101 >/dev/null
start_resolution "$run_id" --resolver-agent pr-review-feedback >/dev/null
results_file=$repo/resolver-results.json
summary_file=$repo/summary.md
thread_feedback_file=$repo/thread-feedback.json
write_single_result "$results_file" pr-review-feedback no-op "$head_sha" "$head_sha"
printf 'Reviewed with no code change.\n' >"$summary_file"
jq -cn '{threads:[{id:"thread-1",outcome:"accepted_as_is",body:"Reviewed and accepted as-is."}]}' \
  >"$thread_feedback_file"
export MOCK_GH_SCENARIO=publication
: >"$MOCK_GH_LOG"
publish_dry=$(run_ok publish --pr 17 --expected-run-id "$run_id" --expected-head-sha "$head_sha" \
  --expected-local-head-sha "$head_sha" --results-file "$results_file" \
  --summary-file "$summary_file" --thread-feedback-file "$thread_feedback_file" --dry-run)
jq -e '.dry_run == true and .would_push == false and .comment_requested == true' <<<"$publish_dry" >/dev/null
state_file=$(git -C "$repo" rev-parse --git-common-dir)/skill-set/shipping-pr/17.json
jq -e '.resolution.publication.phase == "pending"' "$repo/$state_file" >/dev/null
assert_equals 0 "$(count_log '^push |^pr comment ')" "publication dry-run mutation count"
: >"$MOCK_GH_LOG"
publish_single_result "$run_id" "$head_sha" "$head_sha" "$results_file" \
  --summary-file "$summary_file" --thread-feedback-file "$thread_feedback_file" >/dev/null
assert_equals 0 "$(count_log '^push ')" "no-code push count"
assert_equals 1 "$(count_log '^pr comment ')" "no-code comment count"
last_view_line=$(grep -En '^pr view ' "$MOCK_GH_LOG" | tail -1 | cut -d: -f1)
comment_line=$(grep -En '^pr comment ' "$MOCK_GH_LOG" | cut -d: -f1)
[[ $last_view_line -lt $comment_line ]] || fail "no-code comment did not follow a fresh remote HEAD check"

make_fixture publication-codex-feedback
export MOCK_GH_SCENARIO=codex-unresolved
initialized=$(init_case)
run_id=$(jq -r .run_id <<<"$initialized")
snapshot_case 101 >/dev/null
start_resolution "$run_id" --resolver-agent pr-review-feedback >/dev/null
results_file=$repo/resolver-results.json
summary_file=$repo/summary.md
thread_feedback_file=$repo/thread-feedback.json
write_single_result "$results_file" pr-review-feedback no-op "$head_sha" "$head_sha"
printf 'Resolved automated review feedback.\n' >"$summary_file"
jq -cn '{threads:[{id:"thread-codex",outcome:"fixed",body:"Resolved in the current publication."}]}' \
  >"$thread_feedback_file"
export MOCK_GH_SCENARIO=publication
: >"$MOCK_GH_LOG"
publish_single_result "$run_id" "$head_sha" "$head_sha" "$results_file" \
  --summary-file "$summary_file" --thread-feedback-file "$thread_feedback_file" >/dev/null
assert_equals 1 "$(count_log 'addPullRequestReviewThreadReply')" "Codex resolution reply count"
assert_equals 1 "$(count_log 'resolveReviewThread')" "Codex thread resolve count"
if grep -Eiq '@codex|@claude|review once|address that feedback' "$MOCK_GH_DIR/comment.body"; then
  fail "resolution summary triggered a new automated review or delegated edit"
fi

make_fixture publication-coderabbit-feedback
export MOCK_GH_SCENARIO=coderabbit-unresolved
initialized=$(init_case)
run_id=$(jq -r .run_id <<<"$initialized")
snapshot_case 101 >/dev/null
start_resolution "$run_id" --resolver-agent pr-review-feedback >/dev/null
results_file=$repo/resolver-results.json
summary_file=$repo/summary.md
thread_feedback_file=$repo/thread-feedback.json
write_single_result "$results_file" pr-review-feedback no-op "$head_sha" "$head_sha"
printf 'Resolved CodeRabbit feedback.\n' >"$summary_file"
jq -cn '{threads:[{id:"thread-coderabbit",provider:"other",outcome:"fixed",body:"Resolved in the current publication."}]}' \
  >"$thread_feedback_file"
explicit_adapter=$(run_fail publish --pr 17 --expected-run-id "$run_id" --expected-head-sha "$head_sha" \
  --expected-local-head-sha "$head_sha" --results-file "$results_file" \
  --summary-file "$summary_file" --thread-feedback-file "$thread_feedback_file")
assert_equals invalid_publication_input "$(jq -r .error.code <<<"$explicit_adapter")" \
  "explicit reviewer adapter rejection"
jq -cn '{threads:[{id:"thread-coderabbit",outcome:"fixed",body:"Resolved in the current publication."}]}' \
  >"$thread_feedback_file"
export MOCK_GH_SCENARIO=publication
: >"$MOCK_GH_LOG"
publish_single_result "$run_id" "$head_sha" "$head_sha" "$results_file" \
  --summary-file "$summary_file" --thread-feedback-file "$thread_feedback_file" >/dev/null
grep -Eq '^@coderabbitai resolve$' "$MOCK_GH_DIR/comment.body" || \
  fail "resolved CodeRabbit feedback did not emit the explicit resolve command"
if grep -Eiq '@coderabbitai (review|full review|autofix)' "$MOCK_GH_DIR/comment.body"; then
  fail "CodeRabbit resolution feedback triggered a new review or edit"
fi

make_fixture publication-coderabbit-unresolved
export MOCK_GH_SCENARIO=coderabbit-unresolved
initialized=$(init_case)
run_id=$(jq -r .run_id <<<"$initialized")
snapshot_case 101 >/dev/null
start_resolution "$run_id" --resolver-agent pr-review-feedback >/dev/null
results_file=$repo/resolver-results.json
summary_file=$repo/summary.md
thread_feedback_file=$repo/thread-feedback.json
write_single_result "$results_file" pr-review-feedback no-op "$head_sha" "$head_sha"
printf '@coderabbitai this item still needs follow-up.\n' >"$summary_file"
jq -cn '{threads:[{id:"thread-coderabbit",outcome:"unresolved",body:"This item still needs follow-up."}]}' \
  >"$thread_feedback_file"
unsafe_summary=$(run_fail publish --pr 17 --expected-run-id "$run_id" --expected-head-sha "$head_sha" \
  --expected-local-head-sha "$head_sha" --results-file "$results_file" \
  --summary-file "$summary_file" --thread-feedback-file "$thread_feedback_file")
assert_equals invalid_publication_input "$(jq -r .error.code <<<"$unsafe_summary")" \
  "free-form CodeRabbit mention rejection"
printf 'This item still needs follow-up.\n' >"$summary_file"
export MOCK_GH_SCENARIO=publication
: >"$MOCK_GH_LOG"
publish_single_result "$run_id" "$head_sha" "$head_sha" "$results_file" \
  --summary-file "$summary_file" --thread-feedback-file "$thread_feedback_file" >/dev/null
assert_equals 1 "$(count_log 'addPullRequestReviewThreadReply')" "unresolved CodeRabbit reply count"
assert_equals 0 "$(count_log 'resolveReviewThread')" "unresolved CodeRabbit resolve count"
if grep -Eiq '@coderabbitai resolve' "$MOCK_GH_DIR/comment.body"; then
  fail "unresolved CodeRabbit feedback emitted the resolve command"
fi

make_fixture publication-push-failure
export MOCK_GH_SCENARIO=fail
initialized=$(init_case)
run_id=$(jq -r .run_id <<<"$initialized")
snapshot_case 101 >/dev/null
resolution_worktree=$case_dir/resolver-worktree
git -C "$repo" worktree add -q -b resolver-push-failure "$resolution_worktree" "$head_sha"
printf 'resolved\n' >>"$resolution_worktree/fixture.txt"
git -C "$resolution_worktree" add fixture.txt
git -C "$resolution_worktree" commit -qm 'fix: resolver push failure'
local_head=$(git -C "$resolution_worktree" rev-parse HEAD)
start_resolution "$run_id" --resolver-agent ci-failure-resolver >/dev/null
results_file=$resolution_worktree/resolver-results.json
summary_file=$resolution_worktree/summary.md
write_single_result "$results_file" ci-failure-resolver success "$head_sha" "$local_head"
printf 'Queued only after push.\n' >"$summary_file"
export MOCK_GH_SCENARIO=publication-push-fail
: >"$MOCK_GH_LOG"
push_failed=$(run_fail publish --pr 17 --expected-run-id "$run_id" --expected-head-sha "$head_sha" \
  --expected-local-head-sha "$local_head" --results-file "$results_file" --summary-file "$summary_file")
assert_equals publication_push_failed "$(jq -r .error.code <<<"$push_failed")" "failed publication push"
assert_equals 1 "$(count_log '^push ')" "failed push attempt count"
assert_equals 0 "$(count_log '^pr comment ')" "comment after failed push"
state_file=$(git -C "$repo" rev-parse --git-common-dir)/skill-set/shipping-pr/17.json
jq -e '.status == "resolving" and .resolution.publication.phase == "prepared"' \
  "$repo/$state_file" >/dev/null

make_fixture concurrent-init
common_dir=$(git -C "$repo" rev-parse --git-common-dir)
mkdir -p "$repo/$common_dir/skill-set/shipping-pr/17.json.lock"
lock_error=$(run_fail init --pr 17 --repo owner/repo)
assert_equals lock_busy "$(jq -r .error.code <<<"$lock_error")" "concurrent init"

make_fixture illegal-transition
initialized=$(init_case)
run_id=$(jq -r .run_id <<<"$initialized")
illegal=$(run_fail transition --pr 17 --from polling --to resolving --expected-run-id "$run_id")
assert_equals illegal_transition "$(jq -r .error.code <<<"$illegal")" "illegal transition"

stale_snapshot=$(run_fail snapshot --pr 17 --expected-run-id stale-run --now 101)
assert_equals stale_run "$(jq -r .error.code <<<"$stale_snapshot")" "snapshot run-id CAS"

make_fixture snapshot-state-guard
export MOCK_GH_SCENARIO=fail
initialized=$(init_case)
run_id=$(jq -r .run_id <<<"$initialized")
snapshot_case 101 >/dev/null
blocked_snapshot=$(run_fail snapshot --pr 17 --expected-run-id "$run_id" --now 102)
assert_equals invalid_snapshot_state "$(jq -r .error.code <<<"$blocked_snapshot")" "blocked snapshot guard"

make_fixture active-run
init_case >/dev/null
active=$(run_fail init --pr 17 --repo owner/repo)
assert_equals active_run "$(jq -r .error.code <<<"$active")" "active run rejection"
resumed=$(run_ok init --pr 17 --repo owner/repo --resume)
assert_equals true "$(jq -r .resumed <<<"$resumed")" "active run resume"

make_fixture dry-run
dry=$(run_ok init --pr 17 --repo owner/repo --dry-run)
assert_equals true "$(jq -r .dry_run <<<"$dry")" "dry-run marker"
dry_state=$(git -C "$repo" rev-parse --git-common-dir)/skill-set/shipping-pr/17.json
[[ ! -e "$repo/$dry_state" ]] || fail "dry-run created state"

make_fixture snapshot-dry-run
initialized=$(init_case)
run_id=$(jq -r .run_id <<<"$initialized")
snapshot_dry=$(run_ok snapshot --pr 17 --expected-run-id "$run_id" --now 101 --dry-run)
assert_equals clean "$(jq -r .status <<<"$snapshot_dry")" "snapshot dry-run projection"
snapshot_dry_state=$(git -C "$repo" rev-parse --git-common-dir)/skill-set/shipping-pr/17.json
assert_equals polling "$(jq -r .status "$repo/$snapshot_dry_state")" "snapshot dry-run persisted state"

make_fixture transition-dry-run
initialized=$(init_case)
run_id=$(jq -r .run_id <<<"$initialized")
transition_dry=$(run_ok transition --pr 17 --from polling --to failed \
  --expected-run-id "$run_id" --dry-run)
assert_equals failed "$(jq -r .status <<<"$transition_dry")" "transition dry-run projection"
transition_dry_state=$(git -C "$repo" rev-parse --git-common-dir)/skill-set/shipping-pr/17.json
assert_equals polling "$(jq -r .status "$repo/$transition_dry_state")" "transition dry-run persisted state"

make_fixture finish
initialized=$(init_case)
run_id=$(jq -r .run_id <<<"$initialized")
finished=$(run_ok finish --pr 17 --from polling --status failed --expected-run-id "$run_id")
assert_equals failed "$(jq -r .status <<<"$finished")" "finish state"

make_fixture expected-head
wrong_head=2222222222222222222222222222222222222222
head_error=$(run_fail init --pr 17 --repo owner/repo --head-sha "$wrong_head")
assert_equals head_changed "$(jq -r .error.code <<<"$head_error")" "init expected HEAD CAS"

make_fixture stale-finish
initialized=$(init_case)
run_id=$(jq -r .run_id <<<"$initialized")
snapshot_case 101 >/dev/null
stale_finish=$(run_fail finish --pr 17 --from polling --status failed --expected-run-id "$run_id")
assert_equals stale_state "$(jq -r .error.code <<<"$stale_finish")" "finish compare-and-swap"

make_fixture dependency-preflight
dep_bin=$case_dir/dependencies
mkdir -p "$dep_bin"
ln -s "$(command -v bash)" "$dep_bin/bash"
ln -s "$(command -v git)" "$dep_bin/git"
ln -s "$(command -v jq)" "$dep_bin/jq"
if (cd "$repo" && PATH=$dep_bin "$bash_bin" "$runner" init --pr 17 --repo owner/repo) \
  >"$case_dir/preflight.stdout" 2>"$case_dir/preflight.stderr"; then
  fail "missing gh dependency passed preflight"
fi
[[ ! -s $case_dir/preflight.stdout ]] || fail "preflight failure wrote stdout"
jq -e '.error.code == "dependency_missing"' "$case_dir/preflight.stderr" >/dev/null

make_fixture malformed-response
export MOCK_GH_SCENARIO=malformed
malformed=$(run_fail init --pr 17 --repo owner/repo)
assert_equals invalid_github_response "$(jq -r .error.code <<<"$malformed")" "malformed response"

make_fixture malformed-pr-list
export MOCK_GH_SCENARIO=malformed-pr-list
malformed_list=$(run_fail init --pr 17 --repo owner/repo)
assert_equals invalid_github_response "$(jq -r .error.code <<<"$malformed_list")" "nested PR list response"

for scenario in malformed-checks malformed-threads; do
  make_fixture "$scenario"
  export MOCK_GH_SCENARIO=$scenario
  initialized=$(init_case)
  run_id=$(jq -r .run_id <<<"$initialized")
  malformed_nested=$(run_fail snapshot --pr 17 --expected-run-id "$run_id" --now 101)
  assert_equals invalid_github_response "$(jq -r .error.code <<<"$malformed_nested")" "$scenario response"
done

make_fixture malformed-coderabbit
export MOCK_GH_SCENARIO=malformed-coderabbit
initialized=$(init_case)
run_id=$(jq -r .run_id <<<"$initialized")
malformed_cr=$(run_fail snapshot --pr 17 --expected-run-id "$run_id" --now 101)
assert_equals invalid_github_response "$(jq -r .error.code <<<"$malformed_cr")" "nested CodeRabbit response"

# The command-log cases above exercise publication safety. Keep agent and command
# contracts wired to that executable gate rather than a second mutation path.
resolver=$plugin_dir/agents/resolving-pr-blockers.md
grep -Eq 'current worktree' "$resolver"
grep -Fq 'workspace_mode=current' "$resolver"
if grep -Eq 'Create the recorded temporary local branch|Clean up the isolated worktree' "$resolver"; then
  fail "resolver still requires temporary worktree lifecycle management"
fi
grep -Eq 'conflict.*sole cycle|sole cycle.*conflict' "$resolver"
grep -Eq 'CI.*then.*review|CI.*review.*sequential' "$resolver"
grep -Eq 'expected-SHA push' "$resolver"
grep -Eq 'skill-set-pr.*publish' "$resolver"
grep -Eq 'partial failure.*must not invoke publication|must not invoke publication.*partial failure' "$resolver"
grep -Eq 'exact base SHA|base SHA.*exact' "$resolver"
grep -Eq 'preserve.*worktree.*branch|worktree.*branch.*preserve' "$resolver"
if grep -Eq 'parallel with' "$resolver"; then
  fail "resolver dispatch must not be parallel"
fi
fix_command=$plugin_dir/commands/pr/fix.md
grep -Eq 'headRefOid.*baseRefOid|baseRefOid.*headRefOid' "$fix_command"
grep -Eq 'headRepository' "$fix_command"
grep -Eq 'Re-read.*metadata|re-read.*metadata' "$fix_command"
grep -Eq 'If the HEAD changed.*fresh snapshot|fresh snapshot.*If the HEAD changed' "$fix_command"
grep -Fq 'workspace_mode=current' "$fix_command"
grep -Eq 'canonical.*push URL|canonical host' "$plugin_dir/skills/shipping-pr/SKILL.md" \
  "$plugin_dir/skills/shipping-pr/reference/blocker-resolution.md"
grep -Eq 'praise phrase followed by any request remains actionable' \
  "$plugin_dir/skills/shipping-pr/reference/polling.md"

for file in "$plugin_dir"/agents/*.md "$plugin_dir"/skills/shipping-pr/*.md \
  "$plugin_dir"/skills/shipping-pr/reference/*.md; do
  if grep -Eq 'gh pr view.*--json.*reviewThreads|IssueComment\.replies' "$file"; then
    fail "unsupported review API in $file"
  fi
done

grep -Fq 'Bash(sleep:*)' "$plugin_dir/skills/shipping-pr/SKILL.md"
grep -Eq '30-second|30 seconds' "$plugin_dir/skills/shipping-pr/SKILL.md" \
  "$plugin_dir/skills/shipping-pr/reference/polling.md"

printf 'PASS: PR state runner\n'

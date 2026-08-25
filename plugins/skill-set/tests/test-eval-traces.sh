#!/usr/bin/env bash

set -euo pipefail

test_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
plugin_dir=$(cd -- "$test_dir/.." && pwd)
# shellcheck source=plugins/skill-set/tests/test-helper.sh
source "$test_dir/test-helper.sh"

retainer=$plugin_dir/scripts/retain-eval-traces
assert_executable "$retainer"

test_root=$(mktemp -d "${TMPDIR:-/tmp}/skill-set-eval-traces.XXXXXX")
candidate_sandbox=$(mktemp -d "${TMPDIR:-/tmp}/claude-eval-candidate.XXXXXX")
no_plugin_sandbox=$(mktemp -d "${TMPDIR:-/tmp}/claude-eval-no-plugin.XXXXXX")
duplicate_source_sandbox=
duplicate_identity_sandbox_a=
duplicate_identity_sandbox_b=
dirty_worktree_sandbox=
clean_worktree_sandbox=
test_root=$(cd -- "$test_root" && pwd -P)
candidate_sandbox=$(cd -- "$candidate_sandbox" && pwd -P)
no_plugin_sandbox=$(cd -- "$no_plugin_sandbox" && pwd -P)
trap 'rm -rf -- "$test_root" "$candidate_sandbox" "$no_plugin_sandbox" "$duplicate_source_sandbox" "$duplicate_identity_sandbox_a" "$duplicate_identity_sandbox_b" "$dirty_worktree_sandbox" "$clean_worktree_sandbox"' EXIT
mkdir -p -- "$candidate_sandbox/out" "$no_plugin_sandbox/out"

jq -nc '{type:"result", usage:{input_tokens:11, output_tokens:3}}' \
  >"$candidate_sandbox/out/trace.jsonl"
jq -nc '{type:"result", usage:{input_tokens:9, output_tokens:2}}' \
  >"$no_plugin_sandbox/out/trace.jsonl"

jq -n \
  --arg candidate_trace "$candidate_sandbox/out/trace.jsonl" \
  --arg no_plugin_trace "$no_plugin_sandbox/out/trace.jsonl" '{
  schemaVersion: 1,
  cases: [{
    name: "sample-case",
    arms: {
      with: [{tracePath:$candidate_trace}],
      without: [{tracePath:$no_plugin_trace}]
    }
  }]
}' >"$test_root/result.json"

"$retainer" \
  --result "$test_root/result.json" \
  --trace-dir "$test_root/traces" \
  --with-arm candidate \
  --without-arm no-plugin

[[ ! -e $candidate_sandbox ]] || fail 'candidate sandbox was not cleaned'
[[ ! -e $no_plugin_sandbox ]] || fail 'no-plugin sandbox was not cleaned'
candidate_sandbox=$test_root/already-cleaned-candidate
no_plugin_sandbox=$test_root/already-cleaned-no-plugin

candidate_copy=$test_root/traces/candidate/sample-case/run-1.jsonl
no_plugin_copy=$test_root/traces/no-plugin/sample-case/run-1.jsonl
[[ -s $candidate_copy && -s $no_plugin_copy ]] || fail 'durable traces were not copied'
jq -e '
  .cases[0].arms.with[0].tracePath == "traces/candidate/sample-case/run-1.jsonl" and
  .cases[0].arms.without[0].tracePath == "traces/no-plugin/sample-case/run-1.jsonl"
' "$test_root/result.json" >/dev/null
jq -e '.usage.input_tokens == 11 and .usage.output_tokens == 3' \
  "$candidate_copy" >/dev/null

dirty_worktree_sandbox=$(mktemp -d "${TMPDIR:-/tmp}/claude-eval-dirty-worktree.XXXXXX")
dirty_worktree_sandbox=$(cd -- "$dirty_worktree_sandbox" && pwd -P)
mkdir -p -- "$dirty_worktree_sandbox/out" "$dirty_worktree_sandbox/worktree"
jq -nc '{type:"result", usage:{input_tokens:1}}' \
  >"$dirty_worktree_sandbox/out/trace.jsonl"
git -C "$dirty_worktree_sandbox/worktree" init -q -b main
git -C "$dirty_worktree_sandbox/worktree" config user.name 'Skill Eval'
git -C "$dirty_worktree_sandbox/worktree" config user.email 'skill-eval@example.com'
git -C "$dirty_worktree_sandbox/worktree" config commit.gpgsign false
printf 'fixture\n' >"$dirty_worktree_sandbox/worktree/fixture.txt"
git -C "$dirty_worktree_sandbox/worktree" add fixture.txt
git -C "$dirty_worktree_sandbox/worktree" commit -q -m fixture
printf 'mutated\n' | tee -a "$dirty_worktree_sandbox/worktree/fixture.txt" >/dev/null
jq -n --arg trace "$dirty_worktree_sandbox/out/trace.jsonl" '{
  schemaVersion:1,
  cases:[{name:"reviewing-with-peer-agents-review-only", arms:{with:[{tracePath:$trace}]}}]
}' >"$test_root/dirty-worktree-result.json"
if "$retainer" \
  --result "$test_root/dirty-worktree-result.json" \
  --trace-dir "$test_root/dirty-worktree-traces" \
  --with-arm candidate \
  --require-clean-case reviewing-with-peer-agents-review-only \
  >"$test_root/dirty-worktree.stdout" 2>"$test_root/dirty-worktree.stderr"; then
  fail 'retainer accepted a tee-mutated eval worktree'
fi
grep -Fq 'Eval sandbox has unstaged changes' "$test_root/dirty-worktree.stderr" || \
  fail 'dirty eval worktree diagnostic is missing'
[[ -d $dirty_worktree_sandbox ]] || fail 'dirty eval sandbox was not preserved'
if find "$test_root/dirty-worktree-traces" -type f -print -quit 2>/dev/null | grep -q .; then
  fail 'dirty eval worktree produced partial trace evidence'
fi
git -C "$dirty_worktree_sandbox/worktree" add fixture.txt
if "$retainer" \
  --result "$test_root/dirty-worktree-result.json" \
  --trace-dir "$test_root/staged-worktree-traces" \
  --with-arm candidate \
  --require-clean-case reviewing-with-peer-agents-review-only \
  >"$test_root/staged-worktree.stdout" 2>"$test_root/staged-worktree.stderr"; then
  fail 'retainer accepted a staged eval worktree change'
fi
grep -Fq 'Eval sandbox has staged changes' "$test_root/staged-worktree.stderr" || \
  fail 'staged eval worktree diagnostic is missing'
git -C "$dirty_worktree_sandbox/worktree" restore --staged --worktree fixture.txt
printf 'untracked\n' >"$dirty_worktree_sandbox/worktree/untracked.txt"
if "$retainer" \
  --result "$test_root/dirty-worktree-result.json" \
  --trace-dir "$test_root/untracked-worktree-traces" \
  --with-arm candidate \
  --require-clean-case reviewing-with-peer-agents-review-only \
  >"$test_root/untracked-worktree.stdout" 2>"$test_root/untracked-worktree.stderr"; then
  fail 'retainer accepted an untracked eval worktree file'
fi
grep -Fq 'Eval sandbox has untracked files' "$test_root/untracked-worktree.stderr" || \
  fail 'untracked eval worktree diagnostic is missing'

clean_worktree_sandbox=$(mktemp -d "${TMPDIR:-/tmp}/claude-eval-clean-worktree.XXXXXX")
clean_worktree_sandbox=$(cd -- "$clean_worktree_sandbox" && pwd -P)
mkdir -p -- "$clean_worktree_sandbox/out" "$clean_worktree_sandbox/worktree"
jq -nc '{type:"result", usage:{input_tokens:1}}' \
  >"$clean_worktree_sandbox/out/trace.jsonl"
git -C "$clean_worktree_sandbox/worktree" init -q -b main
git -C "$clean_worktree_sandbox/worktree" config user.name 'Skill Eval'
git -C "$clean_worktree_sandbox/worktree" config user.email 'skill-eval@example.com'
git -C "$clean_worktree_sandbox/worktree" config commit.gpgsign false
printf 'fixture\n' >"$clean_worktree_sandbox/worktree/fixture.txt"
git -C "$clean_worktree_sandbox/worktree" add fixture.txt
git -C "$clean_worktree_sandbox/worktree" commit -q -m fixture
jq -n --arg trace "$clean_worktree_sandbox/out/trace.jsonl" '{
  schemaVersion:1,
  cases:[{name:"reviewing-with-peer-agents-review-only", arms:{with:[{tracePath:$trace}]}}]
}' >"$test_root/clean-worktree-result.json"
"$retainer" \
  --result "$test_root/clean-worktree-result.json" \
  --trace-dir "$test_root/clean-worktree-traces" \
  --with-arm candidate \
  --require-clean-case reviewing-with-peer-agents-review-only
[[ ! -e $clean_worktree_sandbox ]] || fail 'clean eval sandbox was not removed'
clean_worktree_sandbox=$test_root/already-cleaned-worktree
[[ -s $test_root/clean-worktree-traces/candidate/reviewing-with-peer-agents-review-only/run-1.jsonl ]] || \
  fail 'clean eval worktree trace was not retained'

untrusted_root=$test_root/not-a-claude-eval
mkdir -p -- "$untrusted_root/out"
jq -nc '{type:"result", usage:{input_tokens:1}}' >"$untrusted_root/out/trace.jsonl"
jq -n --arg trace "$untrusted_root/out/trace.jsonl" '{
  schemaVersion:1,
  cases:[{name:"unsafe-case", arms:{with:[{tracePath:$trace}]}}]
}' >"$test_root/untrusted-result.json"
if "$retainer" \
  --result "$test_root/untrusted-result.json" \
  --trace-dir "$test_root/untrusted-traces" \
  --with-arm candidate >/dev/null 2>&1; then
  fail 'retainer accepted an untrusted cleanup root'
fi
[[ -s $untrusted_root/out/trace.jsonl ]] || fail 'retainer removed an untrusted trace root'

candidate_sandbox=$(mktemp -d "${TMPDIR:-/tmp}/claude-eval-traversal.XXXXXX")
candidate_sandbox=$(cd -- "$candidate_sandbox" && pwd -P)
mkdir -p -- "$candidate_sandbox/out"
jq -nc '{type:"result", usage:{input_tokens:1}}' >"$candidate_sandbox/out/trace.jsonl"
jq -n --arg trace "$candidate_sandbox/out/trace.jsonl" '{
  schemaVersion:1,
  cases:[{name:"safe-case", arms:{with:[{tracePath:$trace}]}}]
}' >"$test_root/traversal-result.json"
if "$retainer" \
  --result "$test_root/traversal-result.json" \
  --trace-dir "$test_root/traversal-traces" \
  --with-arm ../escape >/dev/null 2>&1; then
  fail 'retainer accepted a traversal arm name'
fi
[[ ! -e $test_root/escape ]] || fail 'traversal arm escaped the trace directory'
[[ -s $candidate_sandbox/out/trace.jsonl ]] || fail 'rejected traversal deleted its source trace'

duplicate_source_sandbox=$(mktemp -d "${TMPDIR:-/tmp}/claude-eval-duplicate-source.XXXXXX")
duplicate_source_sandbox=$(cd -- "$duplicate_source_sandbox" && pwd -P)
mkdir -p -- "$duplicate_source_sandbox/out"
jq -nc '{type:"result", usage:{input_tokens:1}}' \
  >"$duplicate_source_sandbox/out/trace.jsonl"
jq -n --arg trace "$duplicate_source_sandbox/out/trace.jsonl" '{
  schemaVersion:1,
  cases:[{name:"duplicate-source", arms:{
    with:[{tracePath:$trace}], without:[{tracePath:$trace}]
  }}]
}' >"$test_root/duplicate-source-result.json"
if "$retainer" \
  --result "$test_root/duplicate-source-result.json" \
  --trace-dir "$test_root/duplicate-source-traces" \
  --with-arm candidate \
  --without-arm no-plugin >/dev/null 2>&1; then
  fail 'retainer accepted one source trace for two arm/run records'
fi
[[ -s $duplicate_source_sandbox/out/trace.jsonl ]] || \
  fail 'duplicate source rejection deleted its source trace'
if find "$test_root/duplicate-source-traces" -type f -print -quit | grep -q .; then
  fail 'duplicate source rejection copied partial trace evidence'
fi

duplicate_identity_sandbox_a=$(mktemp -d "${TMPDIR:-/tmp}/claude-eval-duplicate-identity-a.XXXXXX")
duplicate_identity_sandbox_b=$(mktemp -d "${TMPDIR:-/tmp}/claude-eval-duplicate-identity-b.XXXXXX")
duplicate_identity_sandbox_a=$(cd -- "$duplicate_identity_sandbox_a" && pwd -P)
duplicate_identity_sandbox_b=$(cd -- "$duplicate_identity_sandbox_b" && pwd -P)
mkdir -p -- "$duplicate_identity_sandbox_a/out" "$duplicate_identity_sandbox_b/out"
jq -nc '{type:"result", usage:{input_tokens:1}}' \
  >"$duplicate_identity_sandbox_a/out/trace.jsonl"
jq -nc '{type:"result", usage:{input_tokens:2}}' \
  >"$duplicate_identity_sandbox_b/out/trace.jsonl"
jq -n \
  --arg trace_a "$duplicate_identity_sandbox_a/out/trace.jsonl" \
  --arg trace_b "$duplicate_identity_sandbox_b/out/trace.jsonl" '{
  schemaVersion:1,
  cases:[
    {name:"duplicate-identity", arms:{with:[{tracePath:$trace_a}]}},
    {name:"duplicate-identity", arms:{with:[{tracePath:$trace_b}]}}
  ]
}' >"$test_root/duplicate-identity-result.json"
if "$retainer" \
  --result "$test_root/duplicate-identity-result.json" \
  --trace-dir "$test_root/duplicate-identity-traces" \
  --with-arm candidate >/dev/null 2>&1; then
  fail 'retainer accepted duplicate case/arm/run identities'
fi
[[ -s $duplicate_identity_sandbox_a/out/trace.jsonl ]] || \
  fail 'duplicate identity rejection deleted its first source trace'
[[ -s $duplicate_identity_sandbox_b/out/trace.jsonl ]] || \
  fail 'duplicate identity rejection deleted its second source trace'
if find "$test_root/duplicate-identity-traces" -type f -print -quit | grep -q .; then
  fail 'duplicate identity rejection copied partial trace evidence'
fi

printf 'PASS: eval traces retained before verified sandbox cleanup\n'

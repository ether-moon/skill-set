#!/usr/bin/env bash

set -euo pipefail

fixture_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
workspace=$(pwd -P)
if [[ $fixture_dir != "$workspace" ]]; then
  cp -R -- "$fixture_dir/." "$workspace/"
fi
rm -f -- "$workspace/scaffold.sh"

mkdir -p -- "$workspace/.eval-bin" "$workspace/.eval-state" "$workspace/outputs"
mv -- "$workspace/mock-gh" "$workspace/.eval-bin/gh"
cp -- "$workspace/.eval-bin/gh" "$workspace/.eval-bin/skill-set-git"
chmod +x "$workspace/run-shipping-eval" "$workspace/.eval-bin/gh" \
  "$workspace/.eval-bin/skill-set-git"

printf '%s\n' \
  '.eval-bin/' \
  '.eval-state/' \
  'outputs/' \
  'run-shipping-eval' \
  'resolver-results.json' \
  'summary.md' \
  'thread-feedback.json' \
  >"$workspace/.gitignore"
printf 'shipping eval fixture\n' >"$workspace/fixture.txt"

git -C "$workspace" init -q
git -C "$workspace" checkout -q -b main
git -C "$workspace" config user.name 'Shipping Eval'
git -C "$workspace" config user.email 'shipping-eval@example.com'
git -C "$workspace" add -- .gitignore fixture.txt
git -C "$workspace" commit -q -m 'test: initialize shipping eval fixture'
git -C "$workspace" remote add origin https://example.test/owner/repo.git

head_sha=$(git -C "$workspace" rev-parse HEAD)
printf '%s\n' "$head_sha" >"$workspace/.eval-state/remote-head"
printf 'start\n' >"$workspace/.eval-state/workflow-phase"
: >"$workspace/outputs/mock-gh.log"
: >"$workspace/outputs/runner-invocations.log"

jq -cn --arg head "$head_sha" \
  '{results:[{agent:"pr-review-feedback",result:"no-op",input_head:$head,output_head:$head}]}' \
  >"$workspace/resolver-results.json"
printf 'Resolved the review request without a code change.\n' >"$workspace/summary.md"
jq -cn '{threads:[{id:"thread-1",outcome:"accepted_as_is",body:"Reviewed and accepted as-is."}]}' \
  >"$workspace/thread-feedback.json"

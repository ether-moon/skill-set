#!/usr/bin/env bash

set -euo pipefail

test_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
plugin_dir=$(cd -- "$test_dir/.." && pwd)
# shellcheck source=plugins/skill-set/tests/test-helper.sh
source "$test_dir/test-helper.sh"

skill=$plugin_dir/skills/autofixing-and-escalating/SKILL.md
resolution=$plugin_dir/skills/autofixing-and-escalating/reference/resolution.md
agent_dir=$plugin_dir/agents
shipping=$plugin_dir/skills/shipping-pr/SKILL.md
lint_case=$plugin_dir/evals/autofixing-and-escalating/mixed-lint-output/case.yaml
review_case=$plugin_dir/evals/autofixing-and-escalating/mixed-pr-review-comments/case.yaml

grep -Eq 'resolve-authorized' "$skill"
if grep -Eq 'review-only' "$skill" "$resolution"; then
  fail 'review-only mode must not exist'
fi
grep -Fq "Default to \`edit: true\`" "$skill"
grep -Eq 'pause before any mutation' "$skill"
grep -Eq 'after every required decision is complete, automatically apply all queued OBVIOUS fixes' "$skill"
grep -Eq 'without another confirmation' "$skill"
grep -Eq 'without another confirmation' "$resolution"
for capability in edit commit push comment; do
  grep -Eq "${capability}" "$skill" || fail "missing capability: $capability"
done
for boundary in 'public API' 'data or schema' 'dependencies' 'security policy' 'destructive' 'multiple valid'; do
  grep -Eqi "$boundary" "$skill" || fail "missing ALWAYS AMBIGUOUS boundary: $boundary"
done
if grep -Eq 'more than ~?[0-9]+ lines|parallel (via )?subagents|publication decision|decides? (whether|when) to publish' "$skill" "$resolution"; then
  fail 'classification skill must not use line thresholds, dispatch subagents, or own publication'
fi
grep -Eq 'caller owns orchestration' "$resolution"
grep -Eq 'caller owns publication' "$resolution"

for agent in ci-failure-resolver merge-conflict-resolver pr-review-feedback; do
  agent_file=$agent_dir/$agent.md
  grep -Fiq 'before any mutation' "$agent_file" || fail "$agent does not honor the decision gate"
  grep -Fq 'selected AMBIGUOUS resolutions' "$agent_file" || \
    fail "$agent does not apply selected resolutions after the decision gate"
done
grep -Fq -- '--decision-request' "$shipping" || fail 'shipping-pr does not record unresolved decisions'
grep -Fq -- '--resolver-decision' "$shipping" || fail 'shipping-pr does not persist selected resolutions'

ruby -ryaml -e '
  eval_case = YAML.safe_load(File.read(ARGV.fetch(0)), aliases: false)
  grader = eval_case.fetch("graders").find { |item| item["name"] == "ambiguous-refactor-not-applied" }
  abort "lint eval does not inspect the output copy" unless
    grader&.dig("target", "path") == "outputs/src/order.js"
' "$lint_case"
ruby -ryaml -e '
  eval_case = YAML.safe_load(File.read(ARGV.fetch(0)), aliases: false)
  graders = eval_case.fetch("graders").to_h { |item| [item.fetch("name"), item] }
  invoked = graders["password-validation-invoked"]
  removed = graders["inline-password-validation-removed"]
  abort "review eval does not verify the extracted helper call" unless invoked&.fetch("pattern", "").include?("validatePassword")
  abort "review eval does not verify removal of the inline implementation" unless removed&.fetch("match", nil) == "not_contains"
' "$review_case"

printf 'PASS: autofixing capability contract\n'

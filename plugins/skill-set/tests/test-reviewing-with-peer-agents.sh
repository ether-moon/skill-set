#!/usr/bin/env bash

set -euo pipefail

test_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
plugin_dir=$(cd -- "$test_dir/.." && pwd)
# shellcheck source=plugins/skill-set/tests/test-helper.sh
source "$test_dir/test-helper.sh"

skill_dir=$plugin_dir/skills/reviewing-with-peer-agents
skill_file=$skill_dir/SKILL.md
obvious_case=$plugin_dir/evals/reviewing-with-peer-agents/independent-code-review/case.yaml
ambiguous_case=$plugin_dir/evals/reviewing-with-peer-agents/authorization-decision/case.yaml
review_only_case=$plugin_dir/evals/reviewing-with-peer-agents/review-only/case.yaml
obvious_prompt=${obvious_case%/case.yaml}/prompt.md
ambiguous_prompt=${ambiguous_case%/case.yaml}/prompt.md
review_only_prompt=${review_only_case%/case.yaml}/prompt.md
safety_contract=$plugin_dir/evals/safety-contract.json

assert_file "$skill_file"
assert_file "$obvious_case"
assert_file "$ambiguous_case"
assert_file "$review_only_case"
assert_file "$safety_contract"
grep -Fq 'Choose the available review mechanism at runtime' "$skill_file" || \
  fail 'peer review must choose its mechanism at runtime'
grep -Fq 'natural-language review request' "$skill_file" || \
  fail 'peer review must delegate with a natural-language request'
grep -Fq 'Reviewers are read-only' "$skill_file" || \
  fail 'peer reviewers must remain read-only'
grep -Fq 'decision record' "$skill_file" || \
  fail 'peer review must pass the decision record as context'
grep -Fq 'alternatives explicitly considered or rejected' "$skill_file" || \
  fail 'decision context must preserve considered alternatives'
grep -Fq 'private chain-of-thought' "$skill_file" || \
  fail 'decision context must not request private reasoning'
grep -Fq 'intersection of the established review boundary and verified finding targets' "$skill_file" || \
  fail 'autofixing scope must stay inside the review boundary'
grep -Fq 'review-only or no edits' "$skill_file" || \
  fail 'an explicit no-edit request must stop before autofixing'
grep -Fq 'invoke `autofixing-and-escalating`' "$skill_file" || \
  fail 'verified peer findings must enter the resolution workflow'
grep -Fq 'mode: resolve-authorized' "$skill_file" || \
  fail 'resolution workflow must declare its mode'
grep -Fq 'edit: true' "$skill_file" || \
  fail 'resolution workflow must authorize bounded edits'
grep -Fq 'commit: false' "$skill_file" || \
  fail 'peer review must not authorize commits'
grep -Fq 'push: false' "$skill_file" || \
  fail 'peer review must not authorize pushes'
grep -Fq 'comment: false' "$skill_file" || \
  fail 'peer review must not authorize public comments'

[[ ! -e $skill_dir/scripts/peer-review.sh ]] || \
  fail 'legacy vendor CLI runner must not be restored'
[[ ! -e $skill_dir/reference/cli-commands.md ]] || \
  fail 'legacy vendor CLI command reference must not be restored'
if grep -Eiq '(^|[^[:alnum:]_-])(orca|spawn_agent|Agent tool|Task tool|codex[[:space:]]+exec|claude[[:space:]]+-p|gemini[[:space:]]+-p|peer-review\.sh)([^[:alnum:]_-]|$)' "$skill_file"; then
  fail 'skill must not prescribe a review tool or command'
fi

for prompt_file in "$obvious_prompt" "$ambiguous_prompt" "$review_only_prompt"; do
  assert_file "$prompt_file"
  grep -Fq 'Intent:' "$prompt_file" || fail "review eval lacks work intent: $prompt_file"
  grep -Fq 'Decision record:' "$prompt_file" || fail "review eval lacks decision context: $prompt_file"
done

ruby -rjson -ryaml -e '
  obvious = YAML.safe_load(File.read(ARGV.fetch(0)), aliases: false)
  ambiguous = YAML.safe_load(File.read(ARGV.fetch(1)), aliases: false)
  review_only = YAML.safe_load(File.read(ARGV.fetch(2)), aliases: false)
  contract = JSON.parse(File.read(ARGV.fetch(3)))

  [obvious, ambiguous, review_only].each do |eval_case|
    forced_mechanism = eval_case.fetch("graders").find do |grader|
      (grader["type"] == "tool_used" && grader["tool"] == "Agent") ||
        (grader["type"] == "tool_order" &&
          [grader.dig("before", "tool"), grader.dig("after", "tool")].include?("Agent"))
    end
    abort "eval forces a specific review mechanism" if forced_mechanism
  end

  no_resolution = review_only.fetch("graders").find do |grader|
    grader["name"] == "selected-autofixing-and-escalating"
  end
  abort "review-only case may invoke autofixing" unless
    no_resolution && no_resolution["type"] == "tool_used" &&
    no_resolution["tool"] == "Skill" &&
    no_resolution["input_match"] == "autofixing-and-escalating" &&
    no_resolution["min"] == 0 && no_resolution["max"] == 0 &&
    no_resolution["arm"] == "both"

  abort "reviewing-with-peer-agents missing from mutation safety contract" unless
    contract.fetch("required_mutation_skills").include?("reviewing-with-peer-agents")
  checks = contract.fetch("checks").select { |check| check["skill"] == "reviewing-with-peer-agents" }
  covered_cases = checks.map { |check| check.fetch("case") }.uniq
  required_cases = [obvious, ambiguous, review_only].map { |eval_case| eval_case.fetch("name") }
  abort "consulting safety checks miss functional cases" unless
    (required_cases - covered_cases).empty?
' "$obvious_case" "$ambiguous_case" "$review_only_case" "$safety_contract"

printf 'PASS: natural-language peer-agent review\n'

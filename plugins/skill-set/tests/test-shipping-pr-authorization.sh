#!/usr/bin/env bash

set -euo pipefail

test_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
plugin_dir=$(cd -- "$test_dir/.." && pwd)
skill_file=$plugin_dir/skills/shipping-pr/SKILL.md
resolver_file=$plugin_dir/agents/resolving-pr-blockers.md
merge_resolver_file=$plugin_dir/agents/merge-conflict-resolver.md
base_lag_case=$plugin_dir/evals/shipping-pr/behind-base-current-branch-publication
current_worktree_case=$plugin_dir/evals/shipping-pr/current-worktree-resolution
partial_publication_prompt=$plugin_dir/evals/shipping-pr/partial-resolver-publication-stop/prompt.md
# shellcheck source=plugins/skill-set/tests/test-helper.sh
source "$test_dir/test-helper.sh"

assert_file "$skill_file"
assert_file "$resolver_file"
assert_file "$merge_resolver_file"
assert_file "$base_lag_case/case.yaml"
assert_file "$base_lag_case/prompt.md"
assert_file "$base_lag_case/graders/functional-contract.md"
assert_file "$current_worktree_case/case.yaml"
assert_file "$current_worktree_case/prompt.md"
assert_file "$current_worktree_case/graders/functional-contract.md"

grep -Fq 'A shipping request authorizes the initial branch commit and push' "$skill_file" || \
  fail 'shipping request must authorize the initial commit and push'
grep -Fq 'Do not ask for separate confirmation before committing or pushing.' "$skill_file" || \
  fail 'shipping must not request redundant commit or push confirmation'
grep -Fq 'commit --all' "$skill_file" || \
  fail 'shipping must define the automatic all-change commit operation'
grep -Fq 'push --expected-remote-sha' "$skill_file" || \
  fail 'shipping must define automatic publication of existing commits'
grep -Fq 'Being behind or diverged from the base branch is not a preparation blocker.' \
  "$skill_file" || \
  fail 'shipping must allow current-branch publication independently of base history'
grep -Fq 'Commit and publish the current branch state first' "$skill_file" || \
  fail 'shipping must publish before resolving a base conflict'
grep -Fq 'Use the currently checked-out PR worktree and branch' "$skill_file" || \
  fail 'shipping resolution must stay in the current PR worktree'
grep -Fq 'Do not create a temporary worktree or resolver branch.' "$skill_file" || \
  fail 'shipping must forbid temporary resolver worktrees and branches'
grep -Fq 'reconcile it in place and continue' "$skill_file" || \
  fail 'shipping must repair current/remote drift without an automatic stop'
grep -Fq 'Edit(//**/.git/skill-set/inputs/commit-message.*/content)' "$skill_file" || \
  fail 'shipping must allow writing a managed commit message without a new permission prompt'
grep -Fq 'Edit(//**/.git/skill-set/inputs/pr-body.*/content)' "$skill_file" || \
  fail 'shipping must allow writing a managed PR body without a new permission prompt'
grep -Fq 'Bash(*skill-set-pr:*)' "$skill_file" || \
  fail 'shipping must authorize its portable PR runner invocation'
grep -Fq 'Bash(*skill-set-pr:*)' "$plugin_dir/commands/pr/fix.md" || \
  fail 'PR fix must authorize its portable PR runner invocation'

if grep -Fq 'Never auto-commit working-tree changes for shipping.' "$skill_file"; then
  fail 'shipping still forbids the requested automatic initial commit'
fi
if grep -Fq 'require explicit exclusion confirmation' "$skill_file"; then
  fail 'shipping still requires a redundant dirty-file confirmation'
fi
if grep -Fq 'or behind/diverged history' "$skill_file"; then
  fail 'shipping still treats base history as an initial publication blocker'
fi
if grep -Fq 'Bash(git worktree:*)' "$skill_file"; then
  fail 'shipping still grants temporary worktree creation'
fi
if grep -Fq 'one isolated remote-HEAD worktree' "$skill_file"; then
  fail 'shipping still delegates resolution to an isolated worktree'
fi

ruby -ryaml -e '
  parsed = YAML.safe_load(File.read(ARGV.fetch(0)), aliases: false)
  abort "wrong case name" unless
    parsed["name"] == "shipping-pr-behind-base-current-branch-publication"
  abort "missing functional tag" unless parsed.fetch("tags").include?("functional")
  abort "missing publication-boundary tag" unless
    parsed.fetch("tags").include?("publication-boundary")
  mutation = parsed.fetch("graders").find { |grader| grader["name"] == "no-mutation-tool" }
  abort "missing read-only mutation guard" unless
    mutation == {"type" => "tool_used", "name" => "no-mutation-tool",
      "tool" => "Bash", "min" => 0, "max" => 0, "arm" => "both"}
' "$base_lag_case/case.yaml"

grep -Fq 'normal fast-forward push' "$base_lag_case/prompt.md" || \
  fail 'base-lag eval must distinguish base history from remote-branch safety'
grep -Fq 'base-branch lag or divergence is not a preparation blocker' \
  "$base_lag_case/graders/functional-contract.md" || \
  fail 'base-lag eval must grade the requested publication policy'

ruby -ryaml -e '
  parsed = YAML.safe_load(File.read(ARGV.fetch(0)), aliases: false)
  abort "wrong case name" unless parsed["name"] == "shipping-pr-current-worktree-resolution"
  abort "missing functional tag" unless parsed.fetch("tags").include?("functional")
  abort "missing workspace-policy tag" unless
    parsed.fetch("tags").include?("workspace-policy")
  guarded_tools = parsed.fetch("graders").map do |grader|
    next unless grader["type"] == "tool_used" && grader["min"] == 0 &&
      grader["max"] == 0 && grader["arm"] == "both"
    grader["tool"]
  end.compact
  abort "missing Bash, Write, and Edit mutation guards" unless
    %w[Bash Write Edit].all? { |tool| guarded_tools.include?(tool) }
' "$current_worktree_case/case.yaml"

grep -Fq 'same checked-out branch and worktree' "$current_worktree_case/prompt.md" || \
  fail 'current-worktree eval must exercise in-place reconciliation'
grep -Fq 'does not create a temporary worktree or resolver branch' \
  "$current_worktree_case/graders/functional-contract.md" || \
  fail 'current-worktree eval must grade the requested workspace policy'

grep -Fq "returned \`AMBIGUOUS\` after finding an ambiguous public-API request" \
  "$partial_publication_prompt" || \
  fail 'partial-publication fixture must use the resolver AMBIGUOUS result'
if grep -Fq "returned \`failed\` after finding an ambiguous public-API request" \
  "$partial_publication_prompt"; then
  fail 'partial-publication fixture still conflates AMBIGUOUS with failed'
fi

grep -Fq 'Do not request separate user approval for those commits or for runner publication.' \
  "$resolver_file" || \
  fail 'resolver must treat the shipping capability contract as sufficient authorization'
grep -Fq 'workspace_mode=current' "$resolver_file" || \
  fail 'resolver must support the shipping current-worktree mode'
grep -Fq -- '--allow-tree-identical-merge' "$merge_resolver_file" || \
  fail 'merge resolver must use the constrained ancestry-only merge path'

printf 'PASS: shipping-pr authorization contract\n'

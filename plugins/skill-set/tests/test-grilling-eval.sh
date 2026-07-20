#!/usr/bin/env bash

set -euo pipefail

test_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
plugin_dir=$(cd -- "$test_dir/.." && pwd)
# shellcheck source=plugins/skill-set/tests/test-helper.sh
source "$test_dir/test-helper.sh"

case_dir=$plugin_dir/evals/grilling-plans/early-stop-ledger
case_file=$case_dir/case.yaml
prompt_file=$case_dir/prompt.md
grader_dir=$case_dir/graders

assert_file "$case_file"
assert_file "$prompt_file"

ruby -ryaml -e '
  case_file = ARGV.fetch(0)
  grader_dir = ARGV.fetch(1)
  parsed = YAML.safe_load(File.read(case_file), aliases: false)
  abort "early-stop eval must be functional" unless Array(parsed["tags"]).include?("functional")
  abort "early-stop eval must run at least three times" unless parsed["runs"].is_a?(Integer) && parsed["runs"] >= 3
  abort "early-stop eval must grant only Skill" unless parsed.dig("execution", "allowed_tools") == ["Skill"]

  inline_graders = parsed.fetch("graders").to_h { |grader| [grader.fetch("name"), grader] }
  selected = inline_graders.fetch("selected-grilling-plans")
  abort "early-stop eval does not require the target skill" unless
    selected["type"] == "tool_used" && selected["tool"] == "Skill" &&
    selected["input_match"] == "grilling-plans" && selected["min"] == 1

  required_regex = %w[
    one-confirmed-heading
    one-rejected-heading
    one-unresolved-heading
    ledger-section-order
    confirmed-decisions-retained
    rejected-alternatives-retained
    unresolved-branch-retained
    no-follow-up-question
    no-sixth-question
  ]

  regex_graders = Dir.glob(File.join(grader_dir, "*.md")).to_h do |file|
    contents = File.read(file)
    match = contents.match(/\A---\n(.*?)\n---\n(.*)\z/m)
    abort "invalid grader frontmatter: #{file}" unless match
    metadata = YAML.safe_load(match[1], aliases: false)
    metadata["pattern"] = match[2].strip
    [File.basename(file, ".md"), metadata]
  end
  required_regex.each do |name|
    grader = regex_graders.fetch(name)
    abort "#{name} must deterministically grade the last message" unless
      grader["type"] == "regex" && grader["target"] == "last_message"
  end
  abort "early-stop eval must not depend on an LLM grader" if
    (inline_graders.values + regex_graders.values).any? { |grader| grader["type"] == "llm" }

  passing_ledger = <<~LEDGER
    ## Confirmed
    - Cache keys are per-tenant.
    - The TTL is 60-second.

    ## Rejected
    - A global cache could violate tenant isolation.
    - A 5-minute TTL could leave stale results.

    ## Unresolved
    - The invalidation signal remains undecided.
  LEDGER

  flags_for = lambda do |grader|
    flags = grader.fetch("flags", "")
    options = 0
    options |= Regexp::IGNORECASE if flags.include?("i")
    options |= Regexp::MULTILINE if flags.include?("s")
    options
  end
  regex_for = lambda do |grader|
    Regexp.new(grader.fetch("pattern"), flags_for.call(grader))
  end

  positive_names = required_regex - %w[no-follow-up-question no-sixth-question]
  positive_names.each do |name|
    grader = regex_graders.fetch(name)
    matches = passing_ledger.scan(regex_for.call(grader)).length
    expected = grader.fetch("match", "contains")
    passed = expected.start_with?("count:") ? matches == expected.split(":", 2).last.to_i : matches.positive?
    abort "#{name} rejects a valid ledger fixture" unless passed
  end

  %w[no-follow-up-question no-sixth-question].each do |name|
    grader = regex_graders.fetch(name)
    abort "#{name} rejects a valid stopped ledger" if regex_for.call(grader).match?(passing_ledger)
    abort "#{name} must use not_contains" unless grader["match"] == "not_contains"
  end

  sixth_question = "Question 6/5 — cache warming\n"
  abort "no-sixth-question misses a sixth question" unless
    regex_for.call(regex_graders.fetch("no-sixth-question")).match?(sixth_question)
  fourth_question = "Question 4/5 — cache warming\n"
  abort "no-follow-up-question misses a post-stop question" unless
    regex_for.call(regex_graders.fetch("no-follow-up-question")).match?(fourth_question)
' "$case_file" "$grader_dir" || fail "grilling early-stop eval contract is invalid"

grep -Eq 'explicit early stop' "$prompt_file"
grep -Eq 'return the final decision ledger' "$prompt_file"
grep -Eq 'do not ask another question' "$prompt_file"

printf 'PASS: grilling early-stop eval\n'

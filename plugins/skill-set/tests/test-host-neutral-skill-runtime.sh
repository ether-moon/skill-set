#!/usr/bin/env bash

set -euo pipefail

test_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
plugin_dir=$(cd -- "$test_dir/.." && pwd)
skills_dir=$plugin_dir/skills
# shellcheck source=plugins/skill-set/tests/test-helper.sh
source "$test_dir/test-helper.sh"

if grep -R -Fq 'CLAUDE_PLUGIN_ROOT' "$skills_dir"; then
  fail 'skill runtime documentation must not depend on CLAUDE_PLUGIN_ROOT'
fi
if grep -R -Eq '^[[:space:]]*claude[[:space:]]+(plugin|--version)' "$skills_dir"; then
  fail 'skill runtime documentation must not invoke the Claude CLI directly'
fi
if grep -R -Fq '.claude/skills' "$skills_dir"; then
  fail 'skill runtime documentation must not require Claude-specific skill discovery'
fi

while IFS= read -r runtime_script; do
  if grep -Eq 'CLAUDE_[A-Z_]+|CLAUDE\.md|(^|[[:space:]])claude[[:space:]]+(plugin|--version)' \
    "$runtime_script"; then
    fail "skill runtime script has a Claude execution dependency: $runtime_script"
  fi
done < <(find "$skills_dir" -type f -path '*/scripts/*' | sort)

structure_reference=$skills_dir/creating-skills/reference/structure.md
grep -Fq 'Use them only when the user explicitly targets that host' "$structure_reference" || \
  fail 'host-specific extension documentation lacks an explicit target boundary'
grep -Fq 'Do not use these variables for a portable execution path' "$structure_reference" || \
  fail 'host-specific variable documentation lacks a portable execution boundary'

printf 'PASS: host-neutral skill runtime\n'

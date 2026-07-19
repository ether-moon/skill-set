#!/usr/bin/env bash

set -euo pipefail

test_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
plugin_dir=$(cd -- "$test_dir/.." && pwd)
# shellcheck source=plugins/skill-set/tests/test-helper.sh
source "$test_dir/test-helper.sh"

validator=$plugin_dir/scripts/validate-references
assert_executable "$validator"
rg -q 'nested reference chain' "$validator"

while IFS= read -r reference_file; do
  line_count=$(wc -l <"$reference_file" | tr -d ' ')
  if ((line_count > 100)); then
    sed -n '1,50p' "$reference_file" | rg -q '^## (Table of )?Contents$' ||
      fail "reference over 100 lines lacks a top-level contents section: $reference_file"
    sed -n '1,50p' "$reference_file" | rg -q '^- \[[^]]+\]\(#[^)]+\)' ||
      fail "reference over 100 lines lacks linked contents entries: $reference_file"
  fi

  reference_dir=$(dirname "$reference_file")
  while IFS= read -r referenced_markdown; do
    [[ -n $referenced_markdown ]] || continue
    if [[ -f "$reference_dir/$referenced_markdown" ]]; then
      fail "reference routes to sibling reference instead of remaining self-contained: $reference_file -> $referenced_markdown"
    fi
  done < <(perl -ne '
    if (/^\s*```/) { $fenced = !$fenced; next }
    next if $fenced;
    while (/`([^`]+\.md)(?:#[^`]*)?`/g) { print "$1\n" }
  ' "$reference_file")
done < <(find "$plugin_dir/skills" -path '*/reference/*.md' -type f | sort)

"$validator"
printf 'PASS: local references\n'

#!/usr/bin/env bash

set -euo pipefail

test_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
plugin_dir=$(cd -- "$test_dir/.." && pwd)
# shellcheck source=plugins/skill-set/tests/test-helper.sh
source "$test_dir/test-helper.sh"

manifest=$plugin_dir/.claude-plugin/plugin.json
assert_file "$manifest"

assert_equals "null" "$(jq -r '.commands // "null"' "$manifest")" "manifest commands override"
assert_equals "null" "$(jq -r '.agents // "null"' "$manifest")" "manifest agents override"
[[ ! -e "$plugin_dir/.mcp.json" ]] || fail "unused .mcp.json must be removed"

claude plugin validate --strict "$plugin_dir" >/dev/null
claude plugin validate --strict "$plugin_dir/../.." >/dev/null

hook_count=$(find "$plugin_dir/hooks" -type f 2>/dev/null | wc -l | tr -d ' ' || true)
mcp_count=0
[[ -f "$plugin_dir/.mcp.json" ]] && mcp_count=$(jq '.mcpServers // {} | length' "$plugin_dir/.mcp.json")
assert_equals "0" "$hook_count" "hook count"
assert_equals "0" "$mcp_count" "MCP server count"
printf 'PASS: packaging\n'

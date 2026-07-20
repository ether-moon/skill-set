#!/usr/bin/env bash

set -euo pipefail

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  return 1
}

assert_file() {
  local path=$1
  [[ -f "$path" ]] || fail "expected file: $path"
}

assert_executable() {
  local path=$1
  [[ -x "$path" ]] || fail "expected executable: $path"
}

assert_equals() {
  local expected=$1
  local actual=$2
  local label=$3
  [[ "$actual" == "$expected" ]] || fail "$label: expected '$expected', got '$actual'"
}

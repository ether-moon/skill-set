#!/usr/bin/env bash

set -euo pipefail

fixture_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cp -R "$fixture_dir/." .
rm -f scaffold.sh

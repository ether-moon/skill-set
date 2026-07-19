#!/usr/bin/env bash

set -euo pipefail

mkdir -p outputs/skills/deploying-safely

cat >outputs/skills/deploying-safely/SKILL.md <<'SKILL'
---
name: deploying-safely
description: Manages deployments. Use when the user asks about releases, deployment status, or production rollout.
---

# Deploying Safely

Inspect the current release, prepare a reversible rollout, verify health checks, and stop on ambiguous production state.
SKILL

cat >validate-skill.sh <<'VALIDATOR'
#!/usr/bin/env bash
set -euo pipefail

skill_dir=${1:-outputs/skills/deploying-safely}
skill_file=$skill_dir/SKILL.md
eval_root=outputs/evals/deploying-safely

[[ -f $skill_file ]] || { printf 'missing %s\n' "$skill_file" >&2; exit 1; }
rg -q '^name: deploying-safely$' "$skill_file"
rg -qi '^description:.*rollback' "$skill_file"
rg -qi '^description:.*Do not use.*general release' "$skill_file"
if rg -qi '^description:.*deployment status' "$skill_file"; then
  printf 'description still includes the broad deployment-status near miss\n' >&2
  exit 1
fi
for case_file in \
  "$eval_root/trigger-positive-rollback/case.yaml" \
  "$eval_root/trigger-negative-general-release/case.yaml"; do
  [[ -f $case_file ]] || { printf 'missing %s\n' "$case_file" >&2; exit 1; }
  rg -q '^schema_version: "1\.1"$' "$case_file"
  rg -q '^graders:$' "$case_file"
done
rg -q 'selected-deploying-safely' "$eval_root/trigger-positive-rollback/case.yaml"
rg -q 'did-not-select-deploying-safely' "$eval_root/trigger-negative-general-release/case.yaml"
printf 'valid deploying-safely revision\n'
VALIDATOR

chmod +x validate-skill.sh

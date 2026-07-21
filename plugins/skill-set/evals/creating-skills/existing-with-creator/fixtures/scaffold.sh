#!/usr/bin/env bash

set -euo pipefail

mkdir -p outputs/skills/deploying-safely optional-creator

cat >outputs/skills/deploying-safely/SKILL.md <<'SKILL'
---
name: deploying-safely
description: Manages deployments. Use when the user asks about releases, deployment status, or production rollout.
---

# Deploying Safely

Inspect the current release, prepare a reversible rollout, verify health checks, and stop on ambiguous production state.
SKILL

cat >optional-creator/SKILL.md <<'CREATOR'
---
name: mock-skill-creator
description: Offers optional second-opinion advice for a skill artifact. Use only when explicitly told this helper is available while authoring a skill.
---

# Mock Skill Creator

Suggest one discriminating positive trigger and one plausible near miss. Return advice only; the calling workflow owns files, validation, and acceptance.
CREATOR

cat >validate-skill.sh <<'VALIDATOR'
#!/usr/bin/env bash
set -euo pipefail

skill_dir=${1:-outputs/skills/deploying-safely}
skill_file=$skill_dir/SKILL.md
eval_root=outputs/evals/deploying-safely

[[ -f $skill_file ]] || { printf 'missing %s\n' "$skill_file" >&2; exit 1; }
grep -Eq '^name: deploying-safely$' "$skill_file"
grep -Eqi '^description:.*rollback' "$skill_file"
grep -Eqi '^description:.*Do not use.*general release' "$skill_file"
if grep -Eqi '^description:.*deployment status' "$skill_file"; then
  printf 'description still includes the broad deployment-status near miss\n' >&2
  exit 1
fi
for case_file in \
  "$eval_root/trigger-positive-rollback/case.yaml" \
  "$eval_root/trigger-negative-general-release/case.yaml"; do
  [[ -f $case_file ]] || { printf 'missing %s\n' "$case_file" >&2; exit 1; }
  grep -Eq '^schema_version: "1\.1"$' "$case_file"
  grep -Eq '^graders:$' "$case_file"
done
grep -Eq 'selected-deploying-safely' "$eval_root/trigger-positive-rollback/case.yaml"
grep -Eq 'did-not-select-deploying-safely' "$eval_root/trigger-negative-general-release/case.yaml"
printf 'valid deploying-safely revision\n'
VALIDATOR

chmod +x validate-skill.sh

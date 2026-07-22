#!/usr/bin/env bash

set -euo pipefail

mkdir -p outputs optional-creator

cat >optional-creator/SKILL.md <<'CREATOR'
---
name: mock-skill-creator
description: Executes a delegated end-to-end skill authoring and evaluation-preparation loop. Use when an orchestration skill supplies a bounded skill contract.
---

# Mock Skill Creator

Own the artifact-producing work in the delegated contract: draft or revise the skill, create its positive and near-miss negative evaluation cases, and return the artifacts for policy review. Do not make the final acceptance decision.
CREATOR

cat >validate-skill.sh <<'VALIDATOR'
#!/usr/bin/env bash
set -euo pipefail

skill_dir=${1:-outputs/incident-triage}
skill_file=$skill_dir/SKILL.md
eval_root=outputs/evals/incident-triage

[[ -f $skill_file ]] || { printf 'missing %s\n' "$skill_file" >&2; exit 1; }
[[ $(sed -n '1p' "$skill_file") == '---' ]] || { printf 'missing frontmatter\n' >&2; exit 1; }
grep -Eq '^name: incident-triage$' "$skill_file"
description=$(sed -n '/^description:/p' "$skill_file")
grep -Eq '^description: .+Use when.+' <<<"$description"
grep -Eqi 'active|ongoing|production alert' <<<"$description"
grep -Eqi 'Do not use.*post-incident.*status summar' <<<"$description"
for case_file in \
  "$eval_root/trigger-positive-01/case.yaml" \
  "$eval_root/trigger-negative-01/case.yaml"; do
  [[ -f $case_file ]] || { printf 'missing %s\n' "$case_file" >&2; exit 1; }
  grep -Eq '^schema_version: "1\.1"$' "$case_file"
  grep -Eq '^graders:$' "$case_file"
done
grep -Eq 'selected-incident-triage' "$eval_root/trigger-positive-01/case.yaml"
grep -Eq 'did-not-select-incident-triage' "$eval_root/trigger-negative-01/case.yaml"
printf 'valid incident-triage skill\n'
VALIDATOR

chmod +x validate-skill.sh

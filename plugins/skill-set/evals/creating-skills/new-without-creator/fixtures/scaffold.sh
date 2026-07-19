#!/usr/bin/env bash

set -euo pipefail

mkdir -p outputs

cat >validate-skill.sh <<'VALIDATOR'
#!/usr/bin/env bash
set -euo pipefail

skill_dir=${1:-outputs/incident-triage}
skill_file=$skill_dir/SKILL.md
eval_root=outputs/evals/incident-triage

[[ -f $skill_file ]] || { printf 'missing %s\n' "$skill_file" >&2; exit 1; }
[[ $(sed -n '1p' "$skill_file") == '---' ]] || { printf 'missing frontmatter\n' >&2; exit 1; }
rg -q '^name: incident-triage$' "$skill_file"
rg -q '^description: .+Use when.+' "$skill_file"
rg -qi 'active|ongoing|production alert' "$skill_file"
rg -qi 'post-incident|retrospective|status summar' "$skill_file"
for case_file in \
  "$eval_root/trigger-positive-01/case.yaml" \
  "$eval_root/trigger-negative-01/case.yaml"; do
  [[ -f $case_file ]] || { printf 'missing %s\n' "$case_file" >&2; exit 1; }
  rg -q '^schema_version: "1\.1"$' "$case_file"
  rg -q '^graders:$' "$case_file"
done
rg -q 'selected-incident-triage' "$eval_root/trigger-positive-01/case.yaml"
rg -q 'did-not-select-incident-triage' "$eval_root/trigger-negative-01/case.yaml"
printf 'valid incident-triage skill\n'
VALIDATOR

chmod +x validate-skill.sh

#!/usr/bin/env bash

set -euo pipefail

mkdir -p outputs .claude/skills/mock-skill-creator

cat >.claude/skills/mock-skill-creator/SKILL.md <<'CREATOR'
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

skill_dir=${1:-outputs/incident-triage}
skill_file=$skill_dir/SKILL.md
eval_root=outputs/evals/incident-triage

[[ -f $skill_file ]] || { printf 'missing %s\n' "$skill_file" >&2; exit 1; }
[[ $(sed -n '1p' "$skill_file") == '---' ]] || { printf 'missing frontmatter\n' >&2; exit 1; }
grep -Eq '^name: incident-triage$' "$skill_file"
grep -Eq '^description: .+Use when.+' "$skill_file"
grep -Eqi 'active|ongoing|production alert' "$skill_file"
grep -Eqi 'post-incident|retrospective|status summar' "$skill_file"
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

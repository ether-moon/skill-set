#!/usr/bin/env bash
set -euo pipefail

mkdir -p outputs/skills/deploying-safely optional-creator
cat >expected-skill.md <<'SKILL'
---
name: deploying-safely
description: Performs production deployments. Use when a deployed version must change.
---

# Deployment

Prepare a reversible rollout. Production mutation requires explicit user approval.
SKILL
sed 's/^# Deployment$/# Deploymant/' expected-skill.md >outputs/skills/deploying-safely/SKILL.md
cat >optional-creator/SKILL.md <<'CREATOR'
---
name: skill-creator
description: Creates and revises agent skills with supporting evaluations.
---

When delegated work, produce only the artifacts requested and respect the caller's model-evaluation budget.
CREATOR
cat >validate-skill.sh <<'VALIDATOR'
#!/usr/bin/env bash
set -euo pipefail
cmp expected-skill.md outputs/skills/deploying-safely/SKILL.md
printf 'valid heading correction; remaining content preserved\n'
VALIDATOR
chmod +x validate-skill.sh

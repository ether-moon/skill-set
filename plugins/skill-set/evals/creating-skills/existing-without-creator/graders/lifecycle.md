---
type: llm
focus: trace
---

Pass only if the trace shows `creating-skills` selected, the existing deployment skill inspected and minimally edited, both discriminating trigger cases added, and `./validate-skill.sh outputs/skills/deploying-safely` succeeding after the edits. The revised behavior must include rollback requests and reject general release-information questions without replacing the deployment workflow. Fail if the response only explains a plan, asks for an external creator, or skips/falsifies validation.

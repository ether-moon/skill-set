# Skill audit: 2026-09-16

## Scope and acceptance

Audited all 13 repository-owned skills under `plugins/skill-set/skills`, including their entrypoints and linked reference documents, against this branch's [creating-skills policy](../plugins/skill-set/skills/creating-skills/SKILL.md). The starting revision was `60e1573`. Installed global skills and the externally maintained `release-workflow` dependency are outside this repository-owned scope.

The work covers local instruction corrections, relevant fixtures and graders, and deterministic validation. It preserves names, selection descriptions, tool grants, publication authority, user-required output formats, and the existing batch-decision policies. No model evaluation, capability-retirement decision, commit, push, or PR publication is included.

Accept local changes when source contradictions are resolved, relevant contracts remain intact, repository and host validators pass, and added executable fixtures work. This acceptance does not establish improved model behavior or lower token usage. Capability guidance needs behavioral evidence for retirement; explicit preferences remain valid without a capability comparison.

## Complete inventory and decisions

| Skill | Guidance type | Decision and evidence |
|---|---|---|
| [autofixing-and-escalating](../plugins/skill-set/skills/autofixing-and-escalating/SKILL.md) | Capability and decision policy | Revise classification examples: nullability and a failing assertion did not establish a unique correct fix. Require the existing behavioral contract before treating a correction as OBVIOUS. Preserve the batch gate and separate publication capabilities. |
| [creating-skills](../plugins/skill-set/skills/creating-skills/SKILL.md) | Capability and authoring policy | Keep the branch's recently revised entrypoint and references. Conditional delegation, stage authorization, evidence dimensions, and bounded reruns already supply the audit criteria. |
| [driving-with-tests](../plugins/skill-set/skills/driving-with-tests/SKILL.md) | Capability and testing preference | Revise automatic full-suite expansion, unconditional probing, and service-only testing advice. Select checks for affected behavior and required policy, preserve strict-TDD overrides, and stop when sufficient evidence exists. Remove the generic language-to-command table in favor of project manifests. |
| [grilling-plans](../plugins/skill-set/skills/grilling-plans/SKILL.md) | Preference | Revise the cross-reference guide's instruction to stop and ask one question: queue missing-evidence questions in the existing full batch. Preserve the ledger and read-only scope. |
| [guarding-agent-directives](../plugins/skill-set/skills/guarding-agent-directives/SKILL.md) | Capability and authority policy | Keep. The current branch already distinguishes explicit policy from capability guidance, audits the requested chain, and honors authorized scoped revisions. |
| [improving-architecture](../plugins/skill-set/skills/improving-architecture/SKILL.md) | Capability and report preference | Revise caller/adapter thresholds that contradicted invariant-based depth. A single implementation can own a useful safety or protocol boundary. Keep the ranked read-only report and its required fields. |
| [managing-git-workflow](../plugins/skill-set/skills/managing-git-workflow/SKILL.md) | Capability and authority policy | Revise artifact-language precedence, unmanaged temporary-path examples, and the stale isolated-worktree description. Keep runner-only mutation, scope checks, managed inputs, and expected-SHA publication. |
| [re-explain-clearly](../plugins/skill-set/skills/re-explain-clearly/SKILL.md) | Preference | Keep. The short self-contained skill already preserves meaning, uncertainty, audience choices, and language while excluding drafting, translation-only, and original tutorials. |
| [reviewing-with-peer-agents](../plugins/skill-set/skills/reviewing-with-peer-agents/SKILL.md) | Capability and review policy | Keep. Explicit peer-review intent, reviewer identity, read-only independence, source verification, and the separate resolution boundary remain meaningful contracts. |
| [shipping-pr](../plugins/skill-set/skills/shipping-pr/SKILL.md) | Capability and authority policy | Revise stale troubleshooting that waited for CodeRabbit's review deadline or preserved an isolated resolver checkout. The current runner and entrypoint use reporting-only reviewer telemetry and the recorded current worktree. |
| [writing-clear-prose](../plugins/skill-set/skills/writing-clear-prose/SKILL.md) | Capability and prose preference | Revise examples that converted unsupported measurements into unsupported qualitative gains. Make references and revision passes conditional, respect the stated audience, remove an arbitrary word-reduction target, and keep source fidelity above style. |
| [writing-korean-clearly](../plugins/skill-set/skills/writing-korean-clearly/SKILL.md) | Preference | Keep. The overlay explicitly leaves task ownership, evidence, authority, and governed artifact language to the owning workflow. Its language-specific examples have a project-policy exception. |
| [zooming-out-on-code](../plugins/skill-set/skills/zooming-out-on-code/SKILL.md) | Capability and report preference | Keep. The five-field map, bounded direct dependencies, read-only behavior, and distinction between evidence and inference are deliberate scope constraints. |

Seven skills were revised; six were retained. No skill was retired, renamed, or given a broader trigger. Retention means no supported local correction was identified in this audit, not that behavioral value has been measured.

## Evidence and regression scope

- `managing-git-workflow/scripts/skill-set-git`, `validate_managed_input`: arbitrary `/tmp` files cannot satisfy managed allocation checks. The commit and PR examples now use the returned managed paths.
- `shipping-pr/scripts/skill-set-pr`, reviewer telemetry normalization and snapshot classification: reviewer-required flags are false independently of selected GitHub checks. Troubleshooting now follows that contract.
- The main autofix, grilling, architecture, and prose contracts already contradicted the revised reference examples. Corrections align the examples without changing publication or decision policy.
- Extended existing cases rather than increasing the suite: `driving-with-tests/config-change`, `improving-architecture/deletion-test-on-thin-wrapper`, `managing-git-workflow/pr-title-and-body-generation`, `shipping-pr/stable-clean-after-head-reset`, and `writing-clear-prose/unsupported-specificity`.
- The architecture fixture now pairs a removable string pass-through with a tenant-checking boundary. The prose fixture distinguishes a supplied qualitative observation from a change with no observed outcome.
- Removed the PR grader's incidental heading/checkbox requirement. Its trace grader checks artifact language, committed scope, evidence fidelity, and absence of publication. User-required architecture report fields and shipping state transitions remain acceptance conditions.

## Validation and limits

Completed local checks:

- Plugin and marketplace manifests: `claude plugin validate --strict` passed for both targets.
- All 13 skills passed the available host's `quick_validate.py`.
- Generated inventory and trigger matrix checks passed without regeneration; selection metadata did not change.
- `validate-evals --require-trigger-matrix` validated 253 cases; `validate-references` passed.
- The new architecture fixture passed direct Bun assertions for same-tenant access, missing records, cross-tenant rejection, and the existing string behavior.
- `mise exec -- plugins/skill-set/tests/run.sh` passed the complete deterministic integration suite, including Git/PR runner, authority, evaluation-budget, packaging, and trigger-matrix checks.
- ShellCheck 0.11.0 passed for 63 shell files discovered through fff; `git diff --check` and the audit report's relative-link check passed.

Model execution, qualitative grading, baseline comparisons, portability campaigns, and token/latency measurements were not run. The five amended cases are ready for a separately scoped model evaluation, not reported as behavioral passes.

Accepted the seven local instruction corrections under the deterministic scope above. All 13 skills remain in the collection; no capability-value or performance conclusion is inferred from these checks.

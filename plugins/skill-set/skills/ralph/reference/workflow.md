# Loop Execution Details

## Step 7: Execute Loop — Pseudocode

Report loop start to user, then run:

```
iteration = 0
stuck_count = 0
max_iterations = 100

while iteration < max_iterations:
  1. iteration += 1
     Report: "Iteration {iteration}"

  2. Save: prev_head = `git rev-parse HEAD`
     Save: prev_spec_hash = hash of spec file

  3. Spawn Task subagent:
     - subagent_type: "general-purpose"
     - prompt: the constructed prompt from Step 5 + DONE condition from Step 6
     - description: "Ralph iteration {iteration}"

  4. Wait for subagent completion

  5. Check progress:
     curr_head = `git rev-parse HEAD`
     curr_spec_hash = hash of spec file

     progress = (curr_head != prev_head) OR (curr_spec_hash != prev_spec_hash)

     If NOT progress:
       stuck_count += 1
       Report: "Warning: No progress ({stuck_count} consecutive)"
       If stuck_count >= 3:
         Ask user: "No progress for {stuck_count} iterations. Continue or stop?"
         If continue → stuck_count = 0
         If stop → break
     Else:
       stuck_count = 0

  6. Completion check:
     Evaluate the DONE condition from Step 6.
     If met → break
```

## Subagent Configuration

- **Model:** `sonnet` (default). Sufficient for well-defined tasks. User can request different model.
- **No isolation** (worktree) — subagent works in same repo.
- **Access:** All tools (general-purpose agent).

## PLANNING → BUILDING Transition

When PLANNING completes within `/skill-set:ralph:execute`, report the generated spec to user, ask for confirmation, then propose DONE condition and transition to BUILDING mode.

## Spec File Structure

The spec is a **single self-contained file** describing the desired end state. No separate task lists.

Required structure:

```markdown
## Context

[Goals, constraints, technical background — concise but sufficient
 for a fresh-context agent to understand the project]

## Acceptance Criteria

- Criterion describing a desired outcome (observable, testable)
- Another criterion...

## Progress Log

(populated by build iterations)
```

**Key properties:**
- Declarative. Acceptance criteria describe outcomes, not implementation steps.
- Context section gives fresh agents full project understanding.
- Progress Log tracks what was done — build iterations append here.
- Acceptance Criteria section is immutable during BUILDING — only PLANNING modifies it.
- Disposable — re-run PLANNING to regenerate from scratch.

See `spec-quality.md` for Ralph-ready spec criteria.

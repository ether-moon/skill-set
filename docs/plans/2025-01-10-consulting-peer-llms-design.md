# Consulting Peer LLMs Skill Design

## Overview

A skill that enables Claude to request feedback from other LLM CLI tools (Gemini, Codex) on current work, executing requests in parallel and synthesizing their responses into actionable insights.

## Skill Name

**`consulting-peer-llms`**

The name emphasizes:
- Consulting: Seeking expert advice
- Peer: Other LLMs as equals/colleagues
- LLMs: Explicitly identifying what the peers are

## Use Cases

- User explicitly requests review from specific LLMs: "codex로 검증해줘", "gemini 피드백 받아줘"
- Getting external validation on implementation approach
- Cross-checking Claude's work with different model perspectives
- Gathering diverse insights before major decisions

## Architecture

```
skill-set/skills/consulting-peer-llms/
├── SKILL.md              # Main skill file (<500 lines)
└── reference/
    ├── cli-commands.md   # CLI execution details
    ├── prompt-template.md # Full prompt structure
    └── report-format.md  # Report examples
```

## Workflow

### 1. Request Detection

Trigger patterns:
- "codex로 검증해줘"
- "gemini 피드백 받아줘"
- "다른 LLM들한테 리뷰 받고 싶어"
- "peer review 해줘"

### 2. Context Collection

Gather comprehensive context:

**Work Summary:**
- What was implemented (from conversation)
- Purpose and requirements
- Constraints mentioned in discussion

**Code Changes:**
- Base SHA and current HEAD SHA
- Modified files list (git diff --name-only)
- Key changes summary (analyzed from git diff)

**Project Context:**
- Programming language and frameworks
- Architecture patterns (from memory)

### 3. Prompt Construction

Based on superpowers:code-reviewer structure:

```markdown
# Code Review Request

## What Was Implemented
{Extracted from conversation context}

## Requirements/Plan
{User's requested functionality or problem to solve}

## Changes
Base SHA: {base_sha}
Current SHA: {current_sha}

Modified files:
{git diff --name-only output}

Key changes:
{Summary of major changes}

## Review Focus Areas

Please evaluate this work across these dimensions:

1. **Code Quality**
   - Separation of concerns
   - Error handling completeness
   - Edge cases and validation
   - Code clarity and maintainability

2. **Architecture & Design**
   - Design soundness for the requirements
   - Scalability considerations
   - Potential performance issues
   - Security implications

3. **Testing & Reliability**
   - Test coverage adequacy
   - Edge case handling
   - Integration considerations

4. **Requirements Alignment**
   - All requirements met?
   - Scope creep or missing features?
   - Breaking changes documented?

## Please Provide

1. **Critical Issues**: Bugs, security risks, broken functionality
2. **Important Issues**: Design problems, incomplete features, error handling gaps
3. **Minor Issues**: Style improvements, optimization opportunities
4. **Strengths**: What was done well

Be specific with file references (file:line) and explain impact.
```

### 4. Parallel Execution

Execute both CLI commands in background:

```bash
# Collect git info
BASE_SHA=$(git rev-parse HEAD~1 2>/dev/null || echo "N/A")
CURRENT_SHA=$(git rev-parse HEAD)

# Generate prompt
PROMPT=$(cat <<EOF
{Structured prompt from above}
EOF
)

# Execute in parallel
gemini exec "$PROMPT" > /tmp/gemini-review.txt 2>&1 &
GEMINI_PID=$!

codex exec "$PROMPT" > /tmp/codex-review.txt 2>&1 &
CODEX_PID=$!

# Wait for completion
wait $GEMINI_PID
GEMINI_EXIT=$?

wait $CODEX_PID
CODEX_EXIT=$?

# Read results (continue with successful ones)
if [ $GEMINI_EXIT -eq 0 ] && [ -s /tmp/gemini-review.txt ]; then
  GEMINI_RESULT=$(cat /tmp/gemini-review.txt)
else
  GEMINI_RESULT="[Gemini CLI failed or returned empty response]"
fi

if [ $CODEX_EXIT -eq 0 ] && [ -s /tmp/codex-review.txt ]; then
  CODEX_RESULT=$(cat /tmp/codex-review.txt)
else
  CODEX_RESULT="[Codex CLI failed or returned empty response]"
fi
```

### 5. Output Generation (3-Stage)

**Stage 1: Raw Gemini Response**
```markdown
# Gemini Review
{Original response as-is}
```

**Stage 2: Raw Codex Response**
```markdown
# Codex Review
{Original response as-is}
```

**Stage 3: Synthesized Final Report**

Claude analyzes both responses and generates a synthesized report focusing on actionable insights:

```markdown
# Final Assessment

## Critical Issues Requiring Immediate Attention
{Synthesized critical issues from both LLM feedbacks}
- Issue: {Description}
- Impact: {Why it's serious}
- Location: {file:line}
- Recommendation: {Specific solution}

## Architecture & Design Concerns
{Synthesized architectural improvements needed}

## Code Quality Issues
{Synthesized code quality improvements}
- Error handling: {Improvements needed}
- Edge cases: {Missing edge cases}
- Maintainability: {Maintainability improvements}

## Testing Gaps
{Test coverage or strategy issues}

## Security & Performance Considerations
{Security and performance review items}

## What's Working Well
{Positive feedback on well-implemented parts}

## Actionable Recommendations
1. **Immediate**: {Fix now}
2. **Before Merge**: {Handle before merging}
3. **Future Enhancement**: {Improve later}

## Summary
{Overall code quality assessment and next steps}
```

### Report Generation Logic

Claude processes the raw responses:
1. Consolidate duplicate points
2. Filter for actually valid issues
3. Reclassify by priority and impact
4. Convert to specific, actionable recommendations
5. Remove unnecessary details, extract essentials

**Key principle:** Focus on information synthesis, not comparison. The goal is to produce one authoritative assessment, not to compare which LLM said what.

## Error Handling

- If one CLI fails: Continue with successful one(s) only
- If both fail: Report failure and suggest checking CLI availability
- No retries: Keep it simple and fast

## Integration with Other Skills

- Often follows major implementation work
- Can be used before `managing-git-workflow` (before commit/PR)
- Complements internal code review processes

## Design Patterns Used

- **Progressive disclosure**: Main SKILL.md stays concise, details in reference files
- **Gerund naming**: `consulting-peer-llms` follows project convention
- **Token efficiency**: Parallel execution, single synthesis pass
- **Graceful degradation**: Works with partial results

## Implementation Notes

### CLI Command Format

Both CLIs support direct argument passing:
```bash
gemini exec "your prompt text here"
codex exec "your prompt text here"
```

### Temporary Files

Use `/tmp/` for intermediate results:
- `/tmp/gemini-review.txt`
- `/tmp/codex-review.txt`

Clean up after report generation.

### Context Window Management

Keep prompt focused on:
- Recent conversation turns (last 5-10 exchanges)
- Git diff summary (not full diff)
- Key files only (not entire codebase)

## Success Criteria

1. User can request peer LLM feedback with natural language
2. Both CLIs execute in parallel (faster than sequential)
3. Raw responses are preserved and shown first
4. Final report is actionable and synthesized (not just comparison)
5. Gracefully handles CLI failures
6. Total execution time < 30 seconds typical

## Future Enhancements (Not in Initial Version)

- Support for additional LLM CLIs
- Configurable prompt templates
- Selective context inclusion (user specifies files)
- Conversation history for follow-up reviews

## References

- superpowers:code-reviewer skill structure
- superpowers:requesting-code-review workflow patterns
- skill-set project design patterns (AGENTS.md)

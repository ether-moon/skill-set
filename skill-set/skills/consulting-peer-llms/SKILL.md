---
name: consulting-peer-llms
description: Use when user explicitly requests feedback from other LLM tools (Gemini, Codex) on current work - executes peer reviews in parallel and synthesizes responses into actionable insights
---

# Consulting Peer LLMs

## Overview

Get feedback from other LLM CLI tools (Gemini, Codex) on your current work. This skill executes multiple LLM reviews in parallel and synthesizes their responses into one actionable report.

**Core principle**: Use peer LLMs for external validation and diverse perspectives on implementation quality.

## When to Use

Use this skill when the user explicitly requests:
- "codex로 검증해줘"
- "gemini 피드백 받아줘"
- "다른 LLM들한테 리뷰 받고 싶어"
- "peer review 해줘"

**Do NOT use this skill:**
- Automatically without user request
- For every piece of code (it's heavyweight)
- When quick internal review is sufficient

## Prerequisites

Required CLI tools must be installed:
- `gemini` - Google Gemini CLI tool
- `codex` - OpenAI Codex CLI tool

Verify availability:
```bash
which gemini codex
```

## Quick Start

**Minimal invocation:**
```
User: "gemini랑 codex로 이 코드 리뷰해줘"

You:
1. Collect context (conversation + git changes)
2. Generate review prompt
3. Execute both CLIs in parallel
4. Show raw Gemini response
5. Show raw Codex response
6. Synthesize final assessment
```

## Workflow

### Step 1: Collect Context

Gather comprehensive context from current session:

**Work Summary:**
- What was implemented (extract from recent conversation)
- User's stated purpose and requirements
- Any mentioned constraints or design decisions

**Code Changes:**
```bash
# Get git information
BASE_SHA=$(git rev-parse HEAD~1 2>/dev/null || git rev-parse origin/main 2>/dev/null || echo "N/A")
CURRENT_SHA=$(git rev-parse HEAD)

# Get changed files
CHANGED_FILES=$(git diff --name-only $BASE_SHA..$CURRENT_SHA)

# Get diff summary (not full diff - too verbose)
DIFF_SUMMARY=$(git diff --stat $BASE_SHA..$CURRENT_SHA)
```

**Project Context:**
- Programming language and frameworks (from files)
- Key architecture patterns (from memory if available)

### Step 2: Generate Review Prompt

Use structured prompt based on code-reviewer patterns.

**Full template**: See [reference/prompt-template.md](reference/prompt-template.md)

**Key sections:**
1. Output language (if project/conversation uses non-English)
2. What was implemented
3. Requirements/plan
4. Changes (SHAs + file list + summary)
5. Review focus areas (quality, architecture, testing, requirements)
6. Expected output format (critical/important/minor issues + strengths)

**Language detection:**
- Automatically detect conversation language (Korean, Japanese, etc.)
- Add "Output Language" section if non-English detected
- Omit if English or no clear preference
- See template for detection logic

### Step 3: Execute in Parallel

Run both CLIs simultaneously using bash background execution:

```bash
# Generate full prompt
PROMPT=$(cat <<'EOF'
{Your structured review prompt}
EOF
)

# Execute in parallel
gemini "$PROMPT" > /tmp/gemini-review.txt 2>&1 &
GEMINI_PID=$!

codex exec "$PROMPT" > /tmp/codex-review.txt 2>&1 &
CODEX_PID=$!

# Wait for completion
wait $GEMINI_PID
GEMINI_EXIT=$?

wait $CODEX_PID
CODEX_EXIT=$?

# Read results
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

# Cleanup
rm -f /tmp/gemini-review.txt /tmp/codex-review.txt
```

**Detailed CLI usage**: See [reference/cli-commands.md](reference/cli-commands.md)

### Step 4: Present Raw Responses

Show original responses first for transparency:

```markdown
# Gemini Review

{GEMINI_RESULT}

---

# Codex Review

{CODEX_RESULT}

---
```

### Step 5: Synthesize Final Report

Analyze both responses and generate synthesized assessment.

**Report structure:**

```markdown
# Final Assessment

## Critical Issues Requiring Immediate Attention
{Synthesized critical issues - bugs, security, data loss}
- Issue: {Clear description}
- Impact: {Why it's critical}
- Location: {file:line references}
- Recommendation: {Specific fix}

## Architecture & Design Concerns
{Architectural improvements needed}

## Code Quality Issues
{Code quality improvements}
- Error handling
- Edge cases
- Maintainability

## Testing Gaps
{Test coverage or strategy problems}

## Security & Performance Considerations
{Security and performance items}

## What's Working Well
{Positive feedback}

## Actionable Recommendations
1. **Immediate**: {Fix right now}
2. **Before Merge**: {Must handle before merging}
3. **Future Enhancement**: {Consider for later}

## Summary
{Overall assessment and next steps}
```

**Synthesis principles:**
1. **Consolidate duplicates**: Same issue mentioned twice = one entry
2. **Filter for validity**: Only include legitimate concerns
3. **Prioritize by impact**: Not by which LLM said it
4. **Make actionable**: Concrete recommendations, not vague advice
5. **Remove noise**: Focus on essentials

**Example reports**: See [reference/report-format.md](reference/report-format.md)

## Error Handling

**One CLI fails:**
- Continue with successful CLI only
- Note failure in final report
- Still provide value from available feedback

**Both CLIs fail:**
- Report failure clearly
- Suggest checking CLI installation:
  ```bash
  which gemini codex
  gemini --version
  codex --version
  ```

**Timeout issues (exit code 124):**
- Use 300s (5 minutes) timeout: `timeout 300s`
- This allows time for complex reviews
- Reduce prompt size if still timing out: Focus on key changes only
- Check CLI responsiveness: `time gemini "test"`

**No retries**: Keep execution fast and simple.

## Context Window Management

Keep prompts focused to avoid token bloat:

**Include:**
- Last 5-10 conversation exchanges (recent context)
- Git diff summary (--stat output)
- List of changed files
- Key implementation details from conversation

**Exclude:**
- Full git diff (too verbose)
- Entire file contents (unless critical)
- Historical conversation (only recent)
- Unrelated project files

## Integration with Other Skills

**Typical workflow:**
1. Implement feature with Claude
2. User requests: "gemini로 검증해줘"
3. **Use this skill** → Get peer feedback
4. Address critical/important issues
5. Use `managing-git-workflow` to commit/push/PR

**Complements:**
- Internal code review processes
- Test-driven development
- Systematic debugging

## Common Patterns

**Before major commit:**
```
User: "커밋하기 전에 codex한테 리뷰받고 싶어"
→ Run peer review
→ Address issues
→ Then commit
```

**Second opinion:**
```
User: "이 아키텍처 괜찮은지 gemini한테 물어봐줘"
→ Run peer review focusing on architecture
→ Evaluate feedback
→ Refine if needed
```

**Cross-validation:**
```
User: "다른 LLM들도 같은 생각인지 확인해줘"
→ Run peer review
→ Check consensus in final report
```

## Red Flags - STOP Immediately

If you catch yourself doing these, STOP:

- ❌ Running peer review without explicit user request
- ❌ Skipping raw response output (always show originals first)
- ❌ Just comparing responses instead of synthesizing
- ❌ Including full git diff in prompt (use summary)
- ❌ Forgetting to check CLI exit codes
- ❌ Not cleaning up temp files

## Limitations

**This skill does NOT:**
- Automatically trigger on every code change
- Replace internal review processes
- Guarantee 100% correct feedback (LLMs can be wrong)
- Handle interactive CLI prompts (only single-shot commands)

**Remember:**
- Peer LLM feedback is additional perspective, not absolute truth
- Critical issues from LLMs should still be validated
- Different models have different strengths/weaknesses

## Troubleshooting

**"gemini: command not found"**
- Check installation: `which gemini`
- Verify PATH includes CLI location
- Install if missing

**"Empty response from CLI"**
- Check CLI can run: `gemini "test"`
- Verify API keys/auth if required
- Check prompt isn't too long

**"Both CLIs failed"**
- Run diagnostics: `gemini --version && codex --version`
- Check system logs for errors
- Verify network connectivity if cloud-based

**"Response is truncated"**
- CLIs may have output limits
- Try reducing prompt length
- Focus on specific concerns in prompt

## Quick Reference

**Typical execution time:** 10-30 seconds (parallel)

**Output stages:**
1. Raw Gemini response
2. Raw Codex response
3. Synthesized final report

**Temp files used:**
- `/tmp/gemini-review.txt`
- `/tmp/codex-review.txt`

**Git commands:**
```bash
git rev-parse HEAD~1           # Base SHA
git rev-parse HEAD             # Current SHA
git diff --name-only $BASE..$HEAD   # Changed files
git diff --stat $BASE..$HEAD        # Change summary
```

## See Also

- [reference/prompt-template.md](reference/prompt-template.md) - Full prompt structure
- [reference/cli-commands.md](reference/cli-commands.md) - CLI execution details
- [reference/report-format.md](reference/report-format.md) - Report examples

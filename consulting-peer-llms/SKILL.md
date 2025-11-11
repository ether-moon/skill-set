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
- "Validate this with codex"
- "Get feedback from gemini"
- "I want a review from other LLMs"
- "Do a peer review"

**Do NOT use this skill:**
- Automatically without user request
- For every piece of code (it's heavyweight)
- When quick internal review is sufficient

## Prerequisites

**Supported CLI tools:**
- `gemini` - Google Gemini CLI tool
- `codex` - OpenAI Codex CLI tool
- `claude` - Anthropic Claude CLI tool
- (Add more as needed)

**Detection and usage:**
- With arguments: Use only specified CLIs (e.g., `/review gemini codex`)
- Without arguments: Auto-detect all installed CLIs and use them

Verify availability:
```bash
which gemini codex claude
```

## Quick Start

**Minimal invocation:**
```
User: "Review this code with gemini and codex"

You:
1. Collect context (conversation + git changes)
2. Generate review prompt
3. Execute both CLIs in parallel
4. Show raw Gemini response
5. Show raw Codex response
6. Synthesize final assessment
```

## Workflow

### Step 0: Determine Target CLIs

**Parse command arguments:**

```bash
# Arguments passed to /review command
REQUESTED_CLIS=("$@")

if [ ${#REQUESTED_CLIS[@]} -eq 0 ]; then
  # No arguments - auto-detect installed CLIs
  AVAILABLE_CLIS=()

  for cli in gemini codex claude; do
    if command -v "$cli" &>/dev/null; then
      AVAILABLE_CLIS+=("$cli")
    fi
  done

  if [ ${#AVAILABLE_CLIS[@]} -eq 0 ]; then
    echo "Error: No supported CLI tools found. Install at least one of: gemini, codex, claude"
    exit 1
  fi

  TARGET_CLIS=("${AVAILABLE_CLIS[@]}")
  echo "Auto-detected CLIs: ${TARGET_CLIS[*]}"
else
  # Arguments provided - validate they exist
  TARGET_CLIS=()

  for cli in "${REQUESTED_CLIS[@]}"; do
    if command -v "$cli" &>/dev/null; then
      TARGET_CLIS+=("$cli")
    else
      echo "Warning: $cli not found, skipping"
    fi
  done

  if [ ${#TARGET_CLIS[@]} -eq 0 ]; then
    echo "Error: None of the requested CLIs are installed"
    exit 1
  fi

  echo "Using specified CLIs: ${TARGET_CLIS[*]}"
fi
```

**Key behaviors:**
- No arguments → Use all installed CLIs
- With arguments → Use only specified CLIs (skip if not installed)
- Always synthesize report (even for single CLI)

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

Run target CLIs simultaneously using bash background execution:

```bash
# Generate full prompt
PROMPT=$(cat <<'EOF'
{Your structured review prompt}
EOF
)

# Prepare result storage
declare -A CLI_RESULTS
declare -A CLI_PIDS
declare -A CLI_FILES

# Launch all target CLIs in parallel
for cli in "${TARGET_CLIS[@]}"; do
  OUTPUT_FILE="/tmp/${cli}-review.txt"
  CLI_FILES[$cli]="$OUTPUT_FILE"

  # Execute based on CLI type (each has different command syntax)
  case "$cli" in
    gemini)
      gemini "$PROMPT" > "$OUTPUT_FILE" 2>&1 &
      ;;
    codex)
      codex exec "$PROMPT" > "$OUTPUT_FILE" 2>&1 &
      ;;
    claude)
      claude "$PROMPT" > "$OUTPUT_FILE" 2>&1 &
      ;;
    *)
      echo "Warning: Unknown CLI $cli, attempting generic execution"
      "$cli" "$PROMPT" > "$OUTPUT_FILE" 2>&1 &
      ;;
  esac

  CLI_PIDS[$cli]=$!
done

# Wait for all CLIs to complete and collect results
for cli in "${TARGET_CLIS[@]}"; do
  wait ${CLI_PIDS[$cli]}
  EXIT_CODE=$?
  OUTPUT_FILE="${CLI_FILES[$cli]}"

  if [ $EXIT_CODE -eq 0 ] && [ -s "$OUTPUT_FILE" ]; then
    CLI_RESULTS[$cli]=$(cat "$OUTPUT_FILE")
  else
    CLI_RESULTS[$cli]="[${cli} CLI failed or returned empty response]"
  fi
done

# Cleanup temp files
for cli in "${TARGET_CLIS[@]}"; do
  rm -f "${CLI_FILES[$cli]}"
done
```

**Key points:**
- Dynamic execution based on `TARGET_CLIS` array
- Each CLI may have different command syntax (handle in case statement)
- Parallel execution for efficiency
- Graceful handling of failures

**Detailed CLI usage**: See [reference/cli-commands.md](reference/cli-commands.md)

### Step 4: Present Raw Responses

Show original responses first for transparency:

```bash
# Display each CLI result
for cli in "${TARGET_CLIS[@]}"; do
  echo "# ${cli^} Review"
  echo ""
  echo "${CLI_RESULTS[$cli]}"
  echo ""
  echo "---"
  echo ""
done
```

**Output format example:**
```markdown
# Gemini Review

{Gemini response content}

---

# Codex Review

{Codex response content}

---

# Claude Review

{Claude response content}

---
```

### Step 5: Synthesize Final Report

Analyze all CLI responses and generate synthesized assessment.

**IMPORTANT**: Always create a synthesized report, even for a single CLI. The session should analyze and structure the feedback regardless of how many CLIs were executed.

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
1. **Always synthesize**: Even single CLI responses get analyzed and structured
2. **Consolidate duplicates**: Same issue mentioned by multiple CLIs = one entry
3. **Filter for validity**: Only include legitimate concerns
4. **Prioritize by impact**: Not by which/how many LLMs mentioned it
5. **Make actionable**: Concrete recommendations, not vague advice
6. **Remove noise**: Focus on essentials
7. **Add context**: Session analyzes and adds insights beyond raw responses

**Example reports**: See [reference/report-format.md](reference/report-format.md)

## Error Handling

**Some CLIs fail:**
- Continue with successful CLIs
- Note failures in final report
- Still provide synthesized assessment from available feedback

**All CLIs fail:**
- Report failure clearly
- Show which CLIs were attempted
- Suggest checking CLI installation:
  ```bash
  # Check which CLIs are available
  for cli in gemini codex claude; do
    if command -v "$cli" &>/dev/null; then
      echo "$cli: installed"
      "$cli" --version 2>&1 || echo "$cli: version check failed"
    else
      echo "$cli: not found"
    fi
  done
  ```

**No CLIs installed (auto-detect mode):**
- Report clear error message
- List supported CLI tools
- Provide installation guidance

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
2. User requests: "Validate with gemini"
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
User: "I want a review from codex before committing"
→ Run: /consulting-peer-llms:review codex
→ Analyze synthesized feedback
→ Address issues
→ Then commit
```

**Second opinion:**
```
User: "Ask gemini if this architecture is okay"
→ Run: /consulting-peer-llms:review gemini
→ Evaluate synthesized feedback
→ Refine if needed
```

**Cross-validation:**
```
User: "Check if other LLMs agree"
→ Run: /consulting-peer-llms:review (auto-detect all)
→ Check consensus in synthesized report
```

**Specific multi-model review:**
```
User: "Get feedback from both gemini and claude"
→ Run: /consulting-peer-llms:review gemini claude
→ Compare perspectives in synthesized report
```

## Red Flags - STOP Immediately

If you catch yourself doing these, STOP:

- ❌ Running peer review without explicit user request
- ❌ Skipping raw response output (always show originals first)
- ❌ Just showing raw responses without synthesis
- ❌ Skipping synthesis for single CLI (always synthesize!)
- ❌ Including full git diff in prompt (use summary)
- ❌ Forgetting to check CLI exit codes
- ❌ Not cleaning up temp files
- ❌ Hardcoding CLI list instead of using dynamic TARGET_CLIS

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

**Command usage:**
- `/consulting-peer-llms:review` - Auto-detect all installed CLIs
- `/consulting-peer-llms:review gemini` - Use Gemini only
- `/consulting-peer-llms:review gemini codex` - Use Gemini and Codex
- `/consulting-peer-llms:review gemini codex claude` - Use all three

**Output stages:**
1. Raw responses from each executed CLI
2. Synthesized final report (always, even for single CLI)

**Temp files used:**
- `/tmp/{cli-name}-review.txt` (one per CLI)

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

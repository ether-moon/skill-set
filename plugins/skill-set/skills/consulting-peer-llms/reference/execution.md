# Execution Details

This document covers the detailed execution steps for parallel CLI execution and result synthesis.

## Step 3: Execute in Parallel

Run target CLIs simultaneously using the helper script or bash background execution.

### Using Helper Script

```bash
# Check available CLIs
$SKILL_DIR/scripts/peer-review.sh check

# Get git context
$SKILL_DIR/scripts/peer-review.sh context

# Execute with specific CLIs
$SKILL_DIR/scripts/peer-review.sh execute "$PROMPT" gemini codex
```

### Manual Parallel Execution

If you need more control, execute directly:

```bash
# Generate full prompt (replace placeholders with actual content)
PROMPT=$(cat <<EOF
# Code Review Request

## Context
- **Implemented**: {Extract from conversation context}
- **Requirements**: {User's stated requirements}

## Changes
Please check the changes between **$BASE_SHA** and **$CURRENT_SHA** using your git tools.

## Review Focus
Please evaluate:
1. **Critical Issues**: Bugs, Security, Data Loss.
2. **Code Quality**: Maintainability, Error Handling.
3. **Architecture**: Design soundness, Scalability.

## Output Constraints
- **NO Thinking Process**: Do not include internal thinking or logs.
- **Concise**: Focus on actionable feedback.
EOF
)

# Prepare result storage
declare -A CLI_RESULTS
declare -A CLI_PIDS
declare -A CLI_FILES

TIMEOUT="600s"  # 10 minutes

# Launch all target CLIs in parallel
for cli in "${TARGET_CLIS[@]}"; do
    OUTPUT_FILE="/tmp/${cli}-review.txt"
    CLI_FILES[$cli]="$OUTPUT_FILE"

    case "$cli" in
        gemini)
            timeout "$TIMEOUT" gemini "$PROMPT" > "$OUTPUT_FILE" 2>/dev/null &
            ;;
        codex)
            timeout "$TIMEOUT" codex exec "$PROMPT" > "$OUTPUT_FILE" 2>/dev/null &
            ;;
        claude)
            timeout "$TIMEOUT" claude "$PROMPT" > "$OUTPUT_FILE" 2>/dev/null &
            ;;
        *)
            timeout "$TIMEOUT" "$cli" "$PROMPT" > "$OUTPUT_FILE" 2>/dev/null &
            ;;
    esac
    CLI_PIDS[$cli]=$!
done

# Wait and collect results
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

---

## Step 4: Present Raw Responses

Show original responses first for transparency:

```bash
for cli in "${TARGET_CLIS[@]}"; do
    echo "# ${cli^} Review"
    echo ""
    echo "${CLI_RESULTS[$cli]}"
    echo ""
    echo "---"
    echo ""
done
```

**Output format:**

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

---

## Step 5: Synthesize Final Report

Analyze all CLI responses and generate synthesized assessment.

**IMPORTANT**: Always create a synthesized report, even for a single CLI.

### Report Structure

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

### Synthesis Principles

1. **Always synthesize**: Even single CLI responses get analyzed and structured
2. **Consolidate duplicates**: Same issue from multiple CLIs = one entry
3. **Filter for validity**: Only include legitimate concerns
4. **Prioritize by impact**: Not by which/how many LLMs mentioned it
5. **Make actionable**: Concrete recommendations, not vague advice
6. **Remove noise**: Focus on essentials
7. **Add context**: Session analyzes and adds insights beyond raw responses

---

## CLI-Specific Commands

| CLI | Command | Notes |
|-----|---------|-------|
| gemini | `gemini "$PROMPT"` | Google Gemini CLI |
| codex | `codex exec "$PROMPT"` | OpenAI Codex CLI (uses `exec` subcommand) |
| claude | `claude "$PROMPT"` | Anthropic Claude CLI |

---

## Timeout Handling

**Exit code 124** indicates timeout:
- Default timeout: 600s (10 minutes)
- Reduce prompt size if timing out frequently
- Check CLI responsiveness: `time gemini "test"`

**No retries**: Keep execution fast and simple. If a CLI fails, proceed with others.

---

## Context Window Management

Keep prompts focused to avoid token bloat:

**Include:**
- Last 5-10 conversation exchanges (recent context)
- Git diff summary (`--stat` output)
- List of changed files
- Key implementation details from conversation

**Exclude:**
- Full git diff (too verbose)
- Entire file contents (unless critical)
- Historical conversation (only recent)
- Unrelated project files

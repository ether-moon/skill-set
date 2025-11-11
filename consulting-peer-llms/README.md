# Consulting Peer LLMs

Get feedback from other LLM CLI tools on your code through parallel execution and synthesized reports.

## Quick Start

### Basic Usage

```bash
# Auto-detect and use all installed CLIs
/consulting-peer-llms:review

# Use specific CLI
/consulting-peer-llms:review gemini

# Use multiple CLIs
/consulting-peer-llms:review gemini codex

# Use all supported CLIs
/consulting-peer-llms:review gemini codex claude
```

### What It Does

1. **Collects context** from your current work session
2. **Executes peer reviews** in parallel from specified LLM CLIs
3. **Shows raw responses** from each CLI for transparency
4. **Synthesizes final report** with actionable insights (always, even for single CLI)

### Prerequisites

Install at least one of these CLI tools:

- `gemini` - Google Gemini CLI
- `codex` - OpenAI Codex CLI
- `claude` - Anthropic Claude CLI

Verify installation:
```bash
which gemini codex claude
```

## Examples

### Before Committing

```
User: "Review this with codex before I commit"
→ /consulting-peer-llms:review codex
→ Address issues from synthesized report
→ Commit
```

### Get Second Opinion

```
User: "Ask gemini if this architecture is okay"
→ /consulting-peer-llms:review gemini
→ Evaluate feedback
→ Refine if needed
```

### Cross-Validate

```
User: "Check if other LLMs agree with my approach"
→ /consulting-peer-llms:review
→ Review consensus in synthesized report
```

## Output Format

**Stage 1: Raw Responses**
```markdown
# Gemini Review
{original Gemini feedback}
---

# Codex Review
{original Codex feedback}
---
```

**Stage 2: Synthesized Report**
```markdown
# Final Assessment

## Critical Issues Requiring Immediate Attention
- Issue: {description}
- Impact: {why critical}
- Location: {file:line}
- Recommendation: {specific fix}

## Architecture & Design Concerns
{architectural improvements}

## Code Quality Issues
{quality improvements}

## Testing Gaps
{test coverage problems}

## What's Working Well
{positive feedback}

## Actionable Recommendations
1. **Immediate**: {fix right now}
2. **Before Merge**: {must handle}
3. **Future Enhancement**: {consider later}

## Summary
{overall assessment and next steps}
```

## Key Features

✅ **Dynamic CLI Selection**: Specify which LLMs to consult
✅ **Auto-Detection**: Finds all installed CLIs if no arguments provided
✅ **Parallel Execution**: Runs multiple CLIs simultaneously for speed
✅ **Always Synthesizes**: Structured report even for single CLI
✅ **Graceful Degradation**: Continues if some CLIs fail

## When to Use

✅ **Before major commits**: Get validation before committing
✅ **Second opinions**: Check architectural decisions
✅ **Cross-validation**: Verify approach with multiple perspectives

❌ **Don't use for**:
- Every code change (it's heavyweight)
- Quick internal reviews
- Automatic triggers (only on explicit request)

## Documentation

- **[SKILL.md](SKILL.md)** - Complete workflow and implementation details
- **[reference/prompt-template.md](reference/prompt-template.md)** - Review prompt structure
- **[reference/cli-commands.md](reference/cli-commands.md)** - CLI execution patterns
- **[reference/report-format.md](reference/report-format.md)** - Report examples

## Troubleshooting

**"No CLIs found"**
```bash
# Check installation
which gemini codex claude

# Install if needed
# (Follow installation guides for each CLI)
```

**"CLI failed or returned empty"**
```bash
# Test CLI
gemini "test"
codex exec "test"

# Check auth if needed
export GEMINI_API_KEY="your-key"
```

**All CLIs timeout**
```bash
# Test responsiveness
time gemini "hello"

# If slow, reduce prompt complexity
# Skill automatically uses git diff summary (not full diff)
```

## License

MIT

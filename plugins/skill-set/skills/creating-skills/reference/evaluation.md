# Evaluation and Iteration Methodology

## The Core Loop

Skill development is iterative. The loop:

1. **Draft** the skill (or improve an existing one)
2. **Run** test cases — with the skill AND without (baseline)
3. **Grade** results against defined assertions
4. **Review** outputs qualitatively with the user
5. **Improve** the skill based on feedback
6. **Repeat** until satisfied

---

## Step 1: Define Test Cases

Create 2-3 realistic test prompts — things a real user would actually say. Save them with expected outputs:

```json
{
  "skill_name": "example-skill",
  "evals": [
    {
      "id": 1,
      "prompt": "User's realistic task prompt",
      "expected_output": "Description of expected result",
      "files": [],
      "expectations": [
        "Output includes a summary section",
        "All data fields are populated"
      ]
    }
  ]
}
```

**Good test prompts** are concrete and specific — include file paths, personal context, column names, company names. A mix of lengths and styles (formal, casual, with typos).

**Bad test prompts** are abstract and generic — "Format this data", "Create a chart".

---

## Step 2: Run With-Skill vs Baseline

For each test case, run two versions:

- **With-skill**: Execute the task with your skill loaded
- **Baseline**: Same task, no skill (for new skills) or old version (for improvements)

If subagents are available, spawn both runs in parallel per test case. Otherwise run sequentially.

Organize results by iteration:

```
workspace/
├── iteration-1/
│   ├── eval-descriptive-name/
│   │   ├── with_skill/outputs/
│   │   └── without_skill/outputs/
│   └── ...
├── iteration-2/
│   └── ...
```

---

## Step 3: Grade with Assertions

Assertions are objectively verifiable statements about expected behavior.

**Good assertions** (objectively checkable):
- "Output is a valid PDF file"
- "Report contains a summary section with 3+ bullet points"
- "No API errors in execution transcript"

**Bad assertions** (subjective):
- "Output looks professional"
- "Writing style is good"
- Subjective qualities are better evaluated qualitatively by the user

For each assertion, record:

| Field | Description |
|-------|-------------|
| `text` | What the assertion checks |
| `passed` | true/false |
| `evidence` | Specific evidence from the output |

For assertions that can be checked programmatically, write a script rather than eyeballing it — scripts are faster, more reliable, and reusable across iterations.

---

## Step 4: Benchmark

Track these metrics across with-skill and baseline runs:

| Metric | What it measures |
|--------|-----------------|
| **Pass rate** | % of assertions passed (mean ± stddev across runs) |
| **Time** | Execution duration in seconds |
| **Tokens** | Total token consumption |
| **Tool calls** | Number of tool invocations |

**Watch for:**
- Assertions that always pass regardless of skill (non-discriminating — consider removing)
- High-variance evals (possibly flaky or model-dependent)
- Time/token tradeoffs (skill improves quality but costs more — is it worth it?)

---

## Step 5: Iterate on Improvements

### Principles

1. **Generalize, don't overfit.** You're iterating on a few examples, but the skill will be used across many different prompts. Don't make fiddly changes that only fix your test cases. If there's a stubborn issue, try different metaphors or restructured approaches rather than oppressively constrictive rules.

2. **Keep the prompt lean.** Read the transcripts, not just final outputs. If the skill makes Claude waste time on unproductive steps, cut those parts and see what happens.

3. **Explain the why.** Rather than heavy-handed MUSTs and NEVERs, explain reasoning so Claude understands the importance. This produces more robust behavior than rigid rules.

4. **Bundle repeated work.** If all test runs independently write similar helper scripts, bundle that script in `scripts/` — save every future invocation from reinventing the wheel.

### When to Stop

- User says they're happy
- All feedback is empty (everything looks good)
- No meaningful progress between iterations

---

## Description Optimization

The description field is the primary mechanism that determines whether Claude invokes a skill.

### How Triggering Works

Skills appear in Claude's `available_skills` list with their name + description. Claude decides whether to consult a skill based on that description. Key insight: **Claude only consults skills for tasks it can't easily handle on its own** — simple one-step queries may not trigger a skill even with a perfect description match.

### Trigger Eval Methodology

Create a set of 15-20 eval queries — a mix of should-trigger and should-not-trigger:

**Should-trigger queries (8-10):**
- Different phrasings of the same intent (formal, casual)
- Cases where user doesn't name the skill but clearly needs it
- Uncommon use cases and competitive cases (where this skill should win over another)

**Should-not-trigger queries (8-10):**
- **Near-misses** are most valuable — queries sharing keywords but needing something different
- Adjacent domains, ambiguous phrasing where naive keyword match would trigger
- Avoid obviously irrelevant queries ("write fibonacci") — they don't test anything

```json
[
  {"query": "realistic detailed user prompt", "should_trigger": true},
  {"query": "near-miss prompt that shouldn't trigger", "should_trigger": false}
]
```

### The "Pushy" Description Strategy

Claude tends to **undertrigger** — not using skills when they'd be useful. Combat this by making descriptions slightly assertive:

```yaml
# Too passive
description: Processes PDF files for analysis.

# Appropriately pushy
description: Processes PDF files for analysis, extraction, and transformation. Use this skill whenever the user mentions PDFs, document extraction, form filling, or wants to work with any PDF file, even if they don't explicitly ask for "PDF processing".
```

### Test and Iterate

For each query in your eval set, check if the skill triggers as expected. Revise the description based on failures:
- **False negatives** (should trigger, didn't): Add keywords, broaden scope
- **False positives** (shouldn't trigger, did): Narrow scope, add specificity

---

## Blind Comparison (Advanced)

For rigorous A/B comparison between two skill versions:

1. Give both outputs to an independent evaluator without revealing which is which
2. Let the evaluator judge quality on a rubric (correctness, completeness, formatting)
3. Analyze why the winner won and apply insights to improvement

This is optional — the human review loop is usually sufficient.

---

## Quick Reference

| Phase | Action | Output |
|-------|--------|--------|
| Draft | Write/improve SKILL.md | Skill file |
| Test | Run with-skill + baseline | Output files |
| Grade | Check assertions | Pass/fail results |
| Benchmark | Aggregate metrics | Pass rate, time, tokens |
| Review | User evaluates outputs | Qualitative feedback |
| Improve | Revise skill | Updated SKILL.md |
| Optimize | Tune description | Better triggering accuracy |

# Testing Methodology

Skills can be tested at varying levels of rigor depending on your needs.

## Testing Approaches

- **Manual testing in Claude.ai** - Run queries directly and observe behavior. Fast iteration, no setup required.
- **Scripted testing in Claude Code** - Automate test cases for repeatable validation across changes.
- **Programmatic testing via API** - Build evaluation suites that run systematically against defined test sets.

Choose the approach that matches your quality requirements and skill visibility.

## Pro Tip: Iterate on a Single Task First

The most effective skill creators iterate on a single challenging task until Claude succeeds, then extract the winning approach into a skill. This leverages Claude's in-context learning and provides faster signal than broad testing.

Once you have a working foundation, expand to multiple test cases for coverage.

---

## Three Test Types

### 1. Triggering Tests

**Goal**: Ensure skill loads at the right times.

**Test cases:**
- Triggers on obvious tasks
- Triggers on paraphrased requests
- Doesn't trigger on unrelated topics

**Example test suite:**

```
Should trigger:
- "Help me set up a new ProjectHub workspace"
- "I need to create a project in ProjectHub"
- "Initialize a ProjectHub project for Q4 planning"

Should NOT trigger:
- "What's the weather in San Francisco?"
- "Help me write Python code"
- "Create a spreadsheet" (unless skill handles sheets)
```

**Debugging approach:**
Ask Claude: "When would you use the [skill name] skill?" Claude will quote the description back. Adjust based on what's missing.

### 2. Functional Tests

**Goal**: Verify skill produces correct outputs.

**Test cases:**
- Valid outputs generated
- API calls succeed
- Error handling works
- Edge cases covered

**Example:**

```
Test: Create project with 5 tasks
Given: Project name "Q4 Planning", 5 task descriptions
When: Skill executes workflow
Then:
  - Project created in ProjectHub
  - 5 tasks created with correct properties
  - All tasks linked to project
  - No API errors
```

### 3. Performance Comparison

**Goal**: Prove skill improves results vs. baseline.

**Example comparison:**

```
Without skill:
- User provides instructions each time
- 15 back-and-forth messages
- 3 failed API calls requiring retry
- 12,000 tokens consumed

With skill:
- Automatic workflow execution
- 2 clarifying questions only
- 0 failed API calls
- 6,000 tokens consumed
```

---

## Success Criteria

These are aspirational targets - rough benchmarks rather than precise thresholds.

### Quantitative Metrics

**Skill triggers on 90% of relevant queries**
- How to measure: Run 10-20 test queries that should trigger your skill. Track how many times it loads automatically vs. requires explicit invocation.

**Completes workflow in X tool calls**
- How to measure: Compare the same task with and without the skill enabled. Count tool calls and total tokens consumed.

**0 failed API calls per workflow**
- How to measure: Monitor MCP server logs during test runs. Track retry rates and error codes.

### Qualitative Metrics

**Users don't need to prompt about next steps**
- How to assess: During testing, note how often you need to redirect or clarify. Ask beta users for feedback.

**Workflows complete without user correction**
- How to assess: Run the same request 3-5 times. Compare outputs for structural consistency and quality.

**Consistent results across sessions**
- How to assess: Can a new user accomplish the task on first try with minimal guidance?

---

## Iteration Based on Feedback

Skills are living documents. Plan to iterate based on:

### Undertriggering Signals

- Skill doesn't load when it should
- Users manually enabling it
- Support questions about when to use it

**Solution**: Add more detail and nuance to the description - this may include keywords particularly for technical terms

### Overtriggering Signals

- Skill loads for irrelevant queries
- Users disabling it
- Confusion about purpose

**Solution**: Add negative triggers, be more specific

### Execution Issues

- Inconsistent results
- API call failures
- User corrections needed

**Solution**: Improve instructions, add error handling

---

## Evaluation-Driven Development

Create evaluations BEFORE extensive documentation to solve real problems:

1. **Identify gaps**: Run Claude on representative tasks without the skill
2. **Create evaluations**: Build scenarios that test these gaps
3. **Establish baseline**: Measure performance without the skill
4. **Write minimal instructions**: Address the gaps
5. **Iterate**: Execute evaluations, compare, refine

Work with one Claude instance to create skills, test with other instances in real tasks. Observe behavior, gather insights, iterate based on actual usage patterns.

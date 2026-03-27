# Workflow Patterns

## Table of Contents

- [Degrees of Freedom](#degrees-of-freedom) (high, medium, low)
- [Template Patterns: Strict vs Flexible](#template-patterns-strict-vs-flexible)
- [Plan-Validate-Execute Pattern](#plan-validate-execute-pattern)
- [Choosing Your Approach](#choosing-your-approach)
- [Pattern 1: Sequential Workflow Orchestration](#pattern-1-sequential-workflow-orchestration)
- [Pattern 2: Multi-MCP Coordination](#pattern-2-multi-mcp-coordination)
- [Pattern 3: Iterative Refinement](#pattern-3-iterative-refinement)
- [Pattern 4: Context-Aware Tool Selection](#pattern-4-context-aware-tool-selection)
- [Pattern 5: Domain-Specific Intelligence](#pattern-5-domain-specific-intelligence)
- [Pattern 6: Subagent Execution](#pattern-6-subagent-execution)
- [Use Case Categories](#use-case-categories)

---

These patterns emerged from skills created by early adopters and internal teams. Choose the pattern that best fits your use case.

## Degrees of Freedom

Match the level of specificity in your instructions to the task's fragility and variability.

**High freedom** (text-based guidance) — when multiple approaches are valid and decisions depend on context:

```markdown
## Code review process
1. Analyze the code structure and organization
2. Check for potential bugs or edge cases
3. Suggest improvements for readability
4. Verify adherence to project conventions
```

**Medium freedom** (pseudocode or parameterized scripts) — when a preferred pattern exists but some variation is acceptable:

````markdown
## Generate report
Use this template and customize as needed:
```python
def generate_report(data, format="markdown", include_charts=True):
    # Process data, generate output, optionally include visualizations
```
````

**Low freedom** (exact scripts, no parameters) — when operations are fragile, consistency is critical, or a specific sequence must be followed:

````markdown
## Database migration
Run exactly this script:
```bash
python scripts/migrate.py --verify --backup
```
Do not modify the command or add additional flags.
````

**Analogy:** Think of Claude as a robot exploring a path:
- **Narrow bridge with cliffs**: One safe way forward. Provide exact instructions and guardrails. Example: database migrations that must run in exact sequence.
- **Open field with no hazards**: Many paths lead to success. Give general direction. Example: code reviews where context determines approach.

---

## Template Patterns: Strict vs Flexible

When providing output templates, match strictness to the situation.

**Strict template** — for API responses, data formats, or compliance requirements:

````markdown
## Report structure
ALWAYS use this exact template structure:
```markdown
# [Analysis Title]
## Executive summary
[One-paragraph overview of key findings]
## Key findings
- Finding 1 with supporting data
- Finding 2 with supporting data
## Recommendations
1. Specific actionable recommendation
```
````

**Flexible template** — when adaptation improves output:

````markdown
## Report structure
Here is a sensible default format, but use your best judgment:
```markdown
# [Analysis Title]
## Executive summary
[Overview]
## Key findings
[Adapt sections based on what you discover]
## Recommendations
[Tailor to the specific context]
```
Adjust sections as needed for the specific analysis type.
````

The strict/flexible choice is itself a degree of freedom decision — match it to how fragile the output format is.

---

## Plan-Validate-Execute Pattern

For complex operations where mistakes are costly, have Claude create a verifiable intermediate plan before executing.

```
analyze input → create plan file → validate plan → execute → verify output
```

**Example:** Updating 50 form fields in a PDF based on a spreadsheet. Without validation, Claude might reference non-existent fields, create conflicting values, or miss required fields.

**Solution:** Create an intermediate `changes.json` that gets validated before applying:

```markdown
## Batch update workflow
1. Analyze the PDF form fields: `python scripts/analyze_form.py input.pdf`
2. Create `changes.json` mapping field names to new values
3. Validate the plan: `python scripts/validate_changes.py changes.json`
4. If validation fails, fix issues and re-validate
5. Apply changes: `python scripts/apply_changes.py input.pdf changes.json output.pdf`
6. Verify output: `python scripts/verify_output.py output.pdf`
```

**When to use:** Batch operations, destructive changes, complex validation rules, high-stakes operations.

**Tip:** Make validation scripts verbose with specific error messages like `"Field 'signature_date' not found. Available fields: customer_name, order_total, signature_date_signed"` to help Claude fix issues.

---

## Choosing Your Approach

**Problem-first**: "I need to set up a project workspace" → Skill orchestrates the right calls in the right sequence. Users describe outcomes; skill handles tools.

**Tool-first**: "I have Notion MCP connected" → Skill teaches Claude optimal workflows and best practices. Users have access; skill provides expertise.

---

## Pattern 1: Sequential Workflow Orchestration

**Use when**: Users need multi-step processes in a specific order.

```markdown
## Workflow: Onboard New Customer

### Step 1: Create Account
Call MCP tool: `create_customer`
Parameters: name, email, company

### Step 2: Setup Payment
Call MCP tool: `setup_payment_method`
Wait for: payment method verification

### Step 3: Create Subscription
Call MCP tool: `create_subscription`
Parameters: plan_id, customer_id (from Step 1)

### Step 4: Send Welcome Email
Call MCP tool: `send_email`
Template: welcome_email_template
```

**Key techniques:**
- Explicit step ordering
- Dependencies between steps
- Validation at each stage
- Rollback instructions for failures

---

## Pattern 2: Multi-MCP Coordination

**Use when**: Workflows span multiple services.

```markdown
## Design-to-Development Handoff

### Phase 1: Design Export (Figma MCP)
1. Export design assets from Figma
2. Generate design specifications
3. Create asset manifest

### Phase 2: Asset Storage (Drive MCP)
1. Create project folder in Drive
2. Upload all assets
3. Generate shareable links

### Phase 3: Task Creation (Linear MCP)
1. Create development tasks
2. Attach asset links to tasks
3. Assign to engineering team

### Phase 4: Notification (Slack MCP)
1. Post handoff summary to #engineering
2. Include asset links and task references
```

**Key techniques:**
- Clear phase separation
- Data passing between MCPs
- Validation before moving to next phase
- Centralized error handling

---

## Pattern 3: Iterative Refinement

**Use when**: Output quality improves with iteration.

```markdown
## Iterative Report Creation

### Initial Draft
1. Fetch data via MCP
2. Generate first draft report
3. Save to temporary file

### Quality Check
1. Run validation script: `scripts/check_report.py`
2. Identify issues:
   - Missing sections
   - Inconsistent formatting
   - Data validation errors

### Refinement Loop
1. Address each identified issue
2. Regenerate affected sections
3. Re-validate
4. Repeat until quality threshold met

### Finalization
1. Apply final formatting
2. Generate summary
3. Save final version
```

**Key techniques:**
- Explicit quality criteria
- Iterative improvement
- Validation scripts
- Know when to stop iterating

---

## Pattern 4: Context-Aware Tool Selection

**Use when**: Same outcome, different tools depending on context.

```markdown
## Smart File Storage

### Decision Tree
1. Check file type and size
2. Determine best storage location:
   - Large files (>10MB): Use cloud storage MCP
   - Collaborative docs: Use Notion/Docs MCP
   - Code files: Use GitHub MCP
   - Temporary files: Use local storage

### Execute Storage
Based on decision:
- Call appropriate MCP tool
- Apply service-specific metadata
- Generate access link

### Provide Context to User
Explain why that storage was chosen
```

**Key techniques:**
- Clear decision criteria
- Fallback options
- Transparency about choices

---

## Pattern 5: Domain-Specific Intelligence

**Use when**: Skill adds specialized knowledge beyond tool access.

```markdown
## Payment Processing with Compliance

### Before Processing (Compliance Check)
1. Fetch transaction details via MCP
2. Apply compliance rules:
   - Check sanctions lists
   - Verify jurisdiction allowances
   - Assess risk level
3. Document compliance decision

### Processing
IF compliance passed:
  - Call payment processing MCP tool
  - Apply appropriate fraud checks
  - Process transaction
ELSE:
  - Flag for review
  - Create compliance case

### Audit Trail
- Log all compliance checks
- Record processing decisions
- Generate audit report
```

**Key techniques:**
- Domain expertise embedded in logic
- Compliance before action
- Comprehensive documentation
- Clear governance

---

## Pattern 6: Subagent Execution

**Use when**: Skill runs exploratory or isolated tasks that shouldn't pollute the main conversation context.

```yaml
---
name: deep-research
context: fork
agent: Explore
allowed-tools: Bash(gh *)
---

Research $ARGUMENTS thoroughly:

1. Find relevant files using Glob and Grep
2. Read and analyze the code
3. Summarize findings with file references
```

**Key techniques:**
- `context: fork` creates an isolated subagent context
- `agent` selects execution environment (`Explore`, `Plan`, `general-purpose`, or custom)
- Skill content becomes the subagent's prompt — no access to conversation history
- Results are summarized and returned to main conversation
- Only meaningful for skills with explicit task instructions, not guidelines

**When NOT to use `context: fork`:**
- Skills that provide conventions or style guides (no actionable prompt for subagent)
- Skills that need access to the current conversation context

---

## Use Case Categories

### Category 1: Document & Asset Creation

**Used for**: Creating consistent, high-quality output (documents, presentations, designs, code).

**Key techniques:**
- Embedded style guides and brand standards
- Template structures for consistent output
- Quality checklists before finalizing
- No external tools required - uses Claude's built-in capabilities

### Category 2: Workflow Automation

**Used for**: Multi-step processes that benefit from consistent methodology.

**Key techniques:**
- Step-by-step workflow with validation gates
- Templates for common structures
- Built-in review and improvement suggestions
- Iterative refinement loops

### Category 3: MCP Enhancement

**Used for**: Workflow guidance to enhance MCP tool access.

**Key techniques:**
- Coordinates multiple MCP calls in sequence
- Embeds domain expertise
- Provides context users would otherwise need to specify
- Error handling for common MCP issues

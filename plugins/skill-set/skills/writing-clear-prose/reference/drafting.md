# Drafting Workflow

Step-by-step process for drafting non-fiction prose from scratch.

## Step 1: Define Purpose and Audience

Before writing anything, answer these three questions:

1. **Purpose**: What should the reader know, believe, or do after reading this?
2. **Audience**: What does the reader already know? What don't they know?
3. **Scope**: What is explicitly out of scope?

Write these answers down. They become your filter for every sentence that follows.

## Step 2: Create Outline

Use progressive disclosure structure:

```
Title / Summary (1-2 sentences)
  ├── Key points (scannable without reading body)
  ├── Body sections (one claim per section)
  │   ├── Claim
  │   ├── Evidence / example
  │   └── Implication
  └── Appendix / References (supporting detail)
```

**Rules**:
- Each section makes exactly one claim
- Claims flow logically (cause → effect, problem → solution, or chronological)
- A reader who reads only the title and section headers should get the main argument

## Step 3: Apply Context Zero

Write as if the reader has zero prior context about this topic.

**Checklist**:
- [ ] All acronyms defined on first use
- [ ] Technical terms explained or annotated parenthetically
- [ ] References to "the project" / "the system" name it specifically
- [ ] No pronoun without a clear antecedent in the same paragraph
- [ ] Background provided where reader's knowledge likely ends (Step 1 audience analysis)

## Step 4: Draft Section by Section

For each section in your outline:

1. **Write the claim first** — one sentence stating the section's point
2. **Add evidence** — data, examples, or logical argument supporting the claim
3. **Connect to next section** — ensure the last sentence creates a logical bridge

**Per-section checks**:
- Does this section make exactly one claim?
- Is the claim supported by concrete evidence (not just assertion)?
- Can I remove any sentence without weakening the argument?

## Step 5: Internal Review

Before sharing the draft, run a quick self-review:

1. Read the title and all section headers in sequence — do they tell the full story?
2. Read only the first sentence of each section — do they form a coherent argument?
3. Check for anti-patterns (see `anti-patterns.md`)
4. Verify concreteness: highlight any sentence that can't be fact-checked

## Document Type Templates

### Explanatory Text

```
Purpose: Reader understands [topic]
Structure:
  1. What it is (definition + context)
  2. How it works (mechanism, 2-3 key concepts)
  3. Why it matters (implications, use cases)
  4. Limitations / caveats
```

### Persuasive Proposal

```
Purpose: Reader approves [action]
Structure:
  1. Problem statement (concrete pain, quantified if possible)
  2. Proposed solution (what + how)
  3. Strongest counter-argument + rebuttal (steel man)
  4. Expected outcome (measurable)
  5. Next steps (specific, actionable)
```

### Technical Document

```
Purpose: Reader can implement / operate [system]
Structure:
  1. Overview (what it does, for whom)
  2. Architecture / design (how it works)
  3. Setup / usage (step-by-step)
  4. Troubleshooting (common issues + fixes)
  5. Reference (API, config, glossary)
```

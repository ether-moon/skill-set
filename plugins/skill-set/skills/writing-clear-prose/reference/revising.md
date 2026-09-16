# Revision Checklist

For a substantial revision, address structure before style. For a focused edit, use only the applicable checks and preserve the requested scope.

## Pass 1: Structure

Check the document's skeleton before touching any prose.

- [ ] **Purpose visible**: The first paragraph states what the reader will know, believe, or do
- [ ] **One claim per section**: Each section makes exactly one point with supporting evidence
- [ ] **Logical flow**: Sections follow a clear progression (cause → effect, problem → solution, chronological, or general → specific)
- [ ] **No orphan sections**: Every section connects to the document's stated purpose
- [ ] **Progressive disclosure**: Title + headers tell the full story; body adds depth
- [ ] **Lead not buried**: The conclusion or recommendation appears early, not at the end
- [ ] **No fractal summaries**: Summaries appear once (at the top), not repeated per section
- [ ] **No one-point dilution**: Each section adds new information, not a restatement of a previous point
- [ ] **Paragraph variety**: Paragraphs vary in length and internal structure — not all identical

**Action**: Move, merge, or delete sections. Don't rewrite prose yet.

## Pass 2: Clarity

Ensure the intended audience can follow the document without access to the current conversation.

- [ ] **Audience context**: Supply missing context without re-teaching knowledge the user says the audience has
- [ ] **Concrete over abstract**: Every abstract claim has a specific example, data point, or measurement
- [ ] **Terms defined**: Technical terms and acronyms explained on first use
- [ ] **Antecedents clear**: Every pronoun has an unambiguous referent in the same paragraph
- [ ] **Transcreation applied**: Foreign-language sources and domain jargon adapted naturally
- [ ] **Steel man present**: Opposing viewpoints presented in strongest form (for persuasive text)

**Action**: Add only supported examples, definitions, and context needed by this audience. Unknown evidence remains unknown.

## Pass 3: Style

Polish prose after structure and clarity are solid.

- [ ] **Active voice**: Default to active; passive only when the actor is unknown or irrelevant
- [ ] **No AI cliches**: Remove stock phrases, inflated vocabulary, filler words, and unsupported claims of importance
- [ ] **No -ing filler**: Delete trailing participle phrases that add no evidence ("highlighting its importance")
- [ ] **No negative parallelism**: Remove "It's not X — it's Y" patterns; state the point directly
- [ ] **Brevity applied**: Every sentence earns its place; no filler words or phrases
- [ ] **One idea per sentence**: Break compound sentences making multiple claims
- [ ] **Consistent tone**: Formal or informal throughout — no register shifts
- [ ] **Hedging minimal**: One hedge per claim maximum ("might", "could", "potentially")
- [ ] **No stakes inflation**: Claims of importance backed by evidence, not assertion

**Action**: Cut words that add no meaning, activate verbs, and remove filler. Do not target a word-count reduction unless the user requested one; preserve qualifications and facts.

## Pass 4: Consistency

Final polish for mechanical correctness.

- [ ] **Terminology consistent**: Same concept uses same term throughout (no synonym drift)
- [ ] **Formatting consistent**: Headers, lists, code blocks follow the same pattern
- [ ] **No bold-first bullet pattern**: Not every bullet starts with a bolded phrase
- [ ] **Em dashes limited**: 2-3 per piece maximum; prefer commas or parentheses
- [ ] **References valid**: All links, citations, and cross-references point to real targets
- [ ] **Numbers consistent**: Units, precision, and formatting match throughout
- [ ] **Tone consistent**: No unexpected shifts between sections

**Action**: Search-and-replace for consistency. Verify all references.

## Section-by-Section Feedback Pattern

When the user requests section-by-section feedback, this format can help. Otherwise return the requested revision with a concise summary of material changes:

```
## Section: [Section Title]

**Structure**: [ok / needs restructuring — explain]
**Clarity**: [ok / unclear — quote the unclear sentence, suggest fix]
**Style**: [ok / verbose/passive/cliche — quote, suggest fix]

Suggested revision:
> [Revised text if needed]
```

## Versioning Guidance

When the document already has a revision-history convention, follow it for substantive revisions. Do not create version metadata merely to record a prose edit:

- **Structural changes** (sections moved, added, or removed): Note in revision history
- **Clarity changes** (examples added, terms defined): Minor revision
- **Style changes** (word cuts, voice changes): No version note needed
- **Consistency changes** (terminology fixes): No version note needed

## When to Stop Revising

Stop when:
- Applicable checks are complete with no remaining issues
- Further changes would be preference, not improvement
- The document achieves its stated purpose (Step 1 of drafting)

Do not:
- Revise more than 3 full passes on the same section
- Rewrite sentences that already meet all checklist items
- Add new content during revision (that's drafting, not editing)

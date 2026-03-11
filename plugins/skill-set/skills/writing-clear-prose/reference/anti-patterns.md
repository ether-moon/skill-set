# Anti-Patterns

Common mistakes in AI-assisted and human writing. Check output against these lists during revision.

Sources: Orwell, Strunk & White, [tropes.fyi](https://tropes.fyi/tropes-md), [Wikipedia: Signs of AI writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing)

## AI Vocabulary

These words and phrases signal AI-generated text. Avoid or replace.

### Cliche Phrases

| Cliche | Fix |
|---|---|
| "It's important to note that..." | Delete or state the point directly |
| "In today's fast-paced world..." | Delete — adds nothing |
| "Let's dive in / dive deep / delve" | Delete or start directly |
| "Let's break this down / unpack this" | Delete — pedagogical voice |
| "Navigating the landscape of..." | Name the specific topic |
| "Cutting-edge / game-changing" | State what changed and by how much |
| "Unlock the power of..." | State the specific capability |
| "At the end of the day" | Delete or "ultimately" |
| "A deep understanding of..." | Describe what was understood |
| "Here's the kicker / Here's the thing" | Delete — false suspense |
| "In conclusion / To sum up / In summary" | Delete — competent writing doesn't announce its conclusion |
| "No discussion would be complete without..." | Delete — editorializing |

### Inflated Vocabulary

| Word | Fix |
|---|---|
| leverage, utilize, harness, streamline | "use", "simplify", or describe the specific action |
| robust, comprehensive, holistic | Describe what it actually covers |
| seamless / seamlessly | Describe the specific integration |
| paradigm shift | Describe the specific change |
| tapestry, landscape (as metaphors) | Name the specific domain |
| ecosystem, synergy, framework (as abstractions) | Name the specific system. OK when referring to actual software frameworks |
| pivotal, crucial, vital | State why it matters with evidence |
| testament, enduring legacy | State the specific impact |
| groundbreaking, transformative | State what changed, with measurements |

### Filler Words

Delete unless they add information the reader doesn't already have:

- currently, notably, importantly, additionally, furthermore, moreover, certainly, arguably, remarkably

### Magic Adverbs

Adverbs that inflate mundane descriptions. Delete if the sentence works without them:

- quietly, deeply, fundamentally, merely, simply (as intensifiers)

### Fabricated Precision

Inventing specific numbers, percentages, or metrics to appear concrete when no real data exists. This is the dark side of the Concreteness principle — worse than vagueness because it presents fiction as fact.

| Fabricated | Fix |
|---|---|
| "Reduced load time by 47%." (no benchmark run) | "Reduced load time." or "Reduced load time noticeably." |
| "3x throughput improvement." (no measurement) | "Throughput improved after the refactor." |
| "Saved the team 20 hours per sprint." (no tracking) | "Reduced manual work for the team." |

**Rule**: Numbers require sources. If you can't link a number to a benchmark, profiling result, user requirement, or documented threshold, delete it. Qualitative descriptions are honest; fabricated metrics are misinformation.

## AI Sentence Patterns

Structural patterns that appear far more often in AI text than human text.

### Negative Parallelism

**Pattern**: "It's not X — it's Y"

The single most commonly identified AI tell. One use per document at most.

- Before: "It's not a product launch. It's a paradigm shift."
- Fix: State the actual point directly. "The release changes how users interact with the API."

**Variant**: "Not because X, but because Y"

### Dramatic Countdown

**Pattern**: "Not X. Not Y. Just Z."

- Before: "Not ten. Not fifty. Five hundred twenty-three lint violations."
- Fix: "We found 523 lint violations across 67 files."

### Self-Posed Rhetorical Questions

**Pattern**: "The X? A Y."

Limit to 1 per document. Never in sequence.

- Before: "The result? Devastating. The worst part? Nobody saw it coming."
- Fix: "The result was devastating because no monitoring caught the regression."

### Anaphora Abuse

**Pattern**: Repeating the same sentence opening 3+ times consecutively.

- Before: "They could expose... They could offer... They could provide..."
- Fix: Vary sentence structure. Combine related points.

### Tricolon Overuse

**Pattern**: Formulaic groups of three. One tricolon is rhetoric; three consecutive tricolons are a pattern failure.

- Before: "speed, quality, and efficiency... innovative, transformative, and groundbreaking..."
- Fix: Let content determine list length. Sometimes two items suffice; sometimes four are needed.

### Superficial -ing Analysis

**Pattern**: Appending a present participle phrase that adds no substance.

Both tropes.fyi and Wikipedia flag this — Wikipedia found it in 100% of AI articles and 0% of human articles. The strongest single indicator.

- Before: "Response time improved by 40%, highlighting the importance of caching."
- Fix: "Response time improved by 40%. The bottleneck was repeated database queries that caching eliminated."
- Before: "The team shipped three features, showcasing their dedication."
- Fix: "The team shipped three features." (or explain what made it notable)

### False Ranges

**Pattern**: "From X to Y" where X and Y are not on a real spectrum.

- Before: "From innovation to implementation to cultural transformation."
- Fix: Name specific examples instead of implying a continuum.

### Serves-As Dodge

**Pattern**: Replacing "is" with "serves as", "stands as", "represents", "marks".

- Before: "The building serves as a reminder of the city's heritage."
- Fix: "The building is a reminder of the city's heritage."

## AI Tone Patterns

### Stakes Inflation

Everything becomes world-historically significant. Blog posts about API pricing become meditations on civilization.

- Before: "This will fundamentally reshape how we think about computing."
- Fix: State the specific, bounded impact with evidence.

### Inflated Symbolism

Connecting routine topics to grand themes using a repertoire of stock phrases.

Avoid: "testament to", "plays a vital role", "watershed moment", "pivotal moment", "deeply rooted", "symbolizing its enduring legacy", "marks a crucial phase"

Fix: State the actual significance with evidence, or delete if there is none.

### Asserting Obviousness

Claiming clarity instead of demonstrating it.

- Before: "The reality is simpler and less flattering."
- Fix: State the reality and let the reader judge.

Avoid: "History is clear", "The truth is simple", "It goes without saying"

### Vague Attributions

Citing unnamed authorities to manufacture consensus.

- Before: "Experts argue that this approach has significant drawbacks."
- Fix: Name the expert, cite the source. If you can't name them, you don't have a source.

Avoid: "industry reports suggest", "observers have cited", "several publications note"

### Promotional Tone

Writing reads like an advertisement or tourism brochure rather than analysis.

Avoid: "rich cultural heritage", "nestled in the heart of", "boasts a range of features", "stunning innovation", "must-visit"

Fix: Replace with specific, verifiable descriptions.

### Despite-Challenges Dismissal

**Pattern**: Acknowledge problems only to immediately dismiss them.

- Before: "Despite these challenges, the initiative continues to thrive."
- Fix: If challenges matter, address them substantively. If not, don't mention them.

## AI Structural Patterns

### Fractal Summaries

Summarizing at every level — paragraph, section, and document. "What I'm going to tell you; what I'm telling you; what I just told you."

- Fix: One summary per document (at the top). Sections don't need their own summaries.
- Avoid: "As we've seen in this section...", "Now that we've explored X...", "In the next section, we will discuss..."

### Dead Metaphor Repetition

Introducing one metaphor and repeating it 5+ times throughout the piece.

- Fix: Use a metaphor once or twice, then move on.

### One-Point Dilution

A single argument restated 10 different ways across thousands of words. 800 words of content become 4000 words of circular repetition.

- Fix: State each point once with evidence. If a new paragraph doesn't add new information, delete it.

### Listicle in a Trench Coat

Disguising a list as prose with "The first... The second... The third..."

- Fix: Use an explicit numbered list, or write genuine prose that connects points argumentatively.

### Paragraph Uniformity

Every paragraph has the same length and follows the same internal structure (definition, explanation, hedge, summary).

- Fix: Let content determine paragraph length and structure. Variation is natural.

### Over-Smooth Tone

Replacing specific, unusual facts with generic positive descriptions. All friction and personality removed.

- Fix: Preserve concrete details, rough edges, and specifics. See Concreteness principle.

## AI Formatting Patterns

### Em-Dash Overuse

AI uses 10-20+ em dashes per piece where a human writer uses 2-3. Often used where commas, parentheses, or separate sentences would work better.

- Fix: Limit em dashes to 2-3 per piece. Use commas, parentheses, or split into separate sentences.

### Bold-First Bullets

Every bullet point starts with a bolded phrase, often restating what follows.

- Before: "**Scalability:** The system is designed to scale easily."
- Fix: Vary bullet point structure. Not every bullet needs a bold label.

### Overused Transitions

Heavy reliance on conjunctive adverbs between every sentence or paragraph.

Avoid starting consecutive sentences with: moreover, furthermore, in addition, however, consequently, not only...but also

Fix: Let the logical connection between sentences speak for itself. Use transitions only when the relationship isn't obvious.

## AI Composition Patterns (Conditional)

These patterns are legitimate in moderation. The problem is overuse or mechanical application.

| Pattern | OK | Problem |
|---|---|---|
| "Think of it as..." analogy | When reader needs accessible framing | Patronizing tone; implies reader can't understand without hand-holding |
| Invented concept label ("the X paradox") | After building the argument | Naming without arguing; rhetorical shorthand that skips evidence |
| "Imagine a world where..." | Once in a proposal introduction | Repeated futuristic invitations with wonderful scenario lists |
| Historical analogy | One well-chosen precedent | Rapid-fire stacking ("Apple didn't... Facebook didn't... Stripe didn't...") |
| Self-posed question ("The X? A Y.") | Once for emphasis | Repeated sequence of self-answered questions |
| Curly quotation marks | Consistent use is fine | Mixing curly and straight quotes in the same document |

## Drafting Anti-Patterns

| Anti-Pattern | Problem | Fix |
|---|---|---|
| **Burying the lead** | Key point appears in paragraph 3+ | Move conclusion to first paragraph |
| **Hedge stacking** | "might possibly perhaps" | One hedge maximum per claim |
| **Synonym drift** | Calling the same thing "system", "platform", "solution" | Pick one term, use it consistently |
| **Abstraction cascade** | Each sentence more abstract than the last | Ground every abstract claim with a concrete example |
| **Kitchen sink** | Including everything to seem thorough | Cut anything that doesn't serve the document's purpose |
| **Throat clearing** | Opening with background the reader already knows | Start where the reader's knowledge ends |

## Revision Anti-Patterns

| Anti-Pattern | Problem | Fix |
|---|---|---|
| **Style-first revision** | Polishing sentences before fixing structure | Always revise structure first (see `revising.md`) |
| **Rewriting instead of editing** | Generating new text rather than cutting | Editing = subtracting; draft new text only to fill structural gaps |
| **Consistency blindness** | Ignoring terminology drift during revision | Ctrl+F each key term; verify consistent usage |
| **Feedback accumulation** | Collecting feedback without acting on it | Process feedback in real-time, one pass per category |

## Rationalization Table

If you catch yourself thinking these, stop and apply the relevant principle.

| Thought | Reality | Principle |
|---|---|---|
| "The reader will understand what I mean" | They won't. Be explicit. | Concreteness |
| "This sounds more professional" | Jargon without explanation excludes readers. | Transcreation |
| "The counter-argument is too weak to mention" | If it's that weak, steel-manning it costs nothing. | Steel Man |
| "I need this sentence for flow" | Flow comes from structure, not filler. | Brevity |
| "Adding more detail shows thoroughness" | Unnecessary detail obscures the point. | Brevity |
| "I should hedge to be safe" | Over-hedging signals uncertainty, not caution. | Brevity |
| "This -ing phrase rounds out the sentence" | It adds nothing. Delete it. | Brevity |
| "I need a transition word here" | If the connection isn't obvious, restructure. If it is, the transition is filler. | Brevity |

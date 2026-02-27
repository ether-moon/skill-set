# Core Principles

Four principles for clear non-fiction prose. Apply in order: concreteness grounds the argument, transcreation makes it accessible, steel man makes it credible, brevity makes it readable.

## 1. Concreteness Over Abstraction

Replace vague claims with specific, observable details. Abstract language feels impressive but communicates nothing; concrete language is verifiable and memorable.

**Rule**: If a sentence can't be fact-checked, it's too abstract.

| Before (abstract) | After (concrete) |
|---|---|
| We significantly improved performance. | Response time dropped from 1200ms to 340ms. |
| The system is highly scalable. | The system handles 10,000 concurrent connections on a single node. |
| We leveraged cutting-edge technology. | We used PostgreSQL 16's parallel query execution. |
| Stakeholder alignment was achieved. | The engineering lead, PM, and designer signed off on the spec. |

**Diagnostic questions**:
- Can someone verify this claim with a measurement?
- Would two readers picture the same thing?
- Does this sentence survive "compared to what?"

**Sources**: Orwell's "Politics and the English Language" — "Never use a metaphor, simile or other figure of speech which you are used to seeing in print." Strunk & White Rule 12 — "Use definite, specific, concrete language."

## 2. Transcreation Over Translation

When incorporating foreign-language sources or domain-specific material, adapt the meaning naturally rather than translating word-by-word. Annotate domain terms on first use.

**Rule**: The reader should never feel they're reading a translation.

| Approach | Example |
|---|---|
| Literal translation | "The mood of the workplace was like a dead mouse." |
| Transcreation | "The office atmosphere was tense and lifeless." |
| Domain jargon (raw) | "We applied CQRS with event sourcing on the aggregate root." |
| Domain jargon (annotated) | "We separated read and write models (CQRS) and stored every state change as an event (event sourcing)." |

**Guidelines**:
- Preserve the original's intent and emotional weight, not its syntax
- Annotate technical terms parenthetically on first use
- When quoting, provide both original and adapted version if the nuance matters
- Adapt idioms to equivalents in the target language

## 3. Steel Man Argumentation

Present opposing viewpoints in their strongest possible form before offering your rebuttal. This builds credibility and preempts objections.

**Rule**: If the opposing side wouldn't recognize their argument in your summary, you haven't steel-manned it.

**Pattern**:
```
1. State the strongest version of the counter-argument
2. Acknowledge what's valid about it
3. Present your position with evidence for why it's stronger
```

| Approach | Example |
|---|---|
| Straw man | "Some people think testing is a waste of time, but they're wrong." |
| Steel man | "Integration tests catch real user-facing bugs that unit tests miss, and they require less mocking. However, their 10x longer runtime creates a feedback loop that slows development — a tradeoff we measured at 45 minutes per PR cycle." |

**When to apply**:
- Persuasive proposals where decision-makers will have objections
- Technical documents comparing approaches
- Any text arguing for a specific choice over alternatives

## 4. Brevity and Clarity

Every sentence must earn its place. Cut words that don't add meaning. Prefer short words over long, active voice over passive, and one idea per sentence.

**Rule**: If removing a sentence doesn't change the meaning, remove it.

| Before | After | Cut |
|---|---|---|
| In order to facilitate the process of onboarding | To onboard | 7 words |
| It is important to note that the system requires | The system requires | 6 words |
| Due to the fact that we were unable to | Because we couldn't | 6 words |
| At this point in time | Now | 4 words |
| Has the ability to | Can | 3 words |

**Diagnostic questions**:
- Can I say this in fewer words without losing meaning?
- Is this sentence active voice? If not, does passive serve a purpose?
- Does this paragraph have one main point?

**Sources**: Strunk & White Rule 13 — "Omit needless words." Orwell Rule 2 — "Never use a long word where a short one will do."

# Common Mistakes and Anti-Patterns

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| **Grep first** | Use `find_symbol` with `substring_matching=True` if unsure of exact name |
| **Read entire files** | Use `get_symbols_overview` first, then read specific symbols |
| **Ignore Context7** | For any `import`, `require`, `gem`, check Context7 for official docs |
| **Skip memories** | Always `list_memories` at start to check existing knowledge |
| **Text search for symbols** | Use `find_symbol` and `find_referencing_symbols` (LSP-powered, accurate) |
| **Guess library usage** | `resolve-library-id` + `get-library-docs` for official patterns |

---

## Anti-Patterns: Rationalizations

These are excuses that indicate you're about to make a mistake. If you catch yourself thinking these, STOP.

| Excuse | Reality | What To Do Instead |
|--------|---------|-------------------|
| "Grep is faster" | `find_symbol` is faster AND more accurate (finds semantic refs, not strings) | Use `find_symbol` with `substring_matching=True` |
| "Need to read full file to be sure" | `get_symbols_overview` + targeted symbol reads is more efficient | Call `get_symbols_overview` FIRST |
| "Serena not activated" | YOU can activate it | Call `activate_project` NOW, no excuses |
| "Context7 found nothing" | You tried 1 search term only | Try 2+ variations before giving up |
| "Workflow doesn't apply here" | Yes it does - you don't decide | Follow the workflow anyway |
| "Can understand from code" | Official docs (Context7) explain intent, best practices, gotchas | Use Context7 with multiple search terms |
| "My knowledge is enough" | Libraries update constantly, Context7 has latest version-specific info | Check Context7 anyway |
| "Already using Serena" | Using `search_for_pattern` only ≠ using symbolic tools | Use `find_symbol`, `find_referencing_symbols` |
| "WebSearch is fine" | Less reliable than official docs, often outdated | Try Context7 2+ times before WebSearch |
| "Just reading config files" | Config is code, use symbolic tools | `get_symbols_overview` on config too |
| "CLI help is sufficient" | Official docs include concepts, architecture, examples | Context7 provides comprehensive guides |

---

## Red Flags - STOP Immediately

If you catch yourself doing ANY of these, STOP and start over:

### Tool Misuse

- ❌ **Using Grep before `find_symbol`**
  - Why wrong: Text search finds strings, not semantic meaning
  - Correct: Use `find_symbol` with `substring_matching=True` for fuzzy search

- ❌ **Using Read before `get_symbols_overview`**
  - Why wrong: Loading entire file content wastes tokens
  - Correct: Get overview first, then read specific symbols

- ❌ **"Just need to check one file"**
  - Why wrong: You still don't know what's IN the file
  - Correct: Use `get_symbols_overview` first, ALWAYS

### Activation Excuses

- ❌ **"Serena isn't activated"**
  - Why wrong: YOU can activate it
  - Correct: Call `activate_project` immediately, no excuses

### Search Laziness

- ❌ **"Context7 didn't work" after 1 try**
  - Why wrong: You only tried one search term
  - Correct: Try 2+ search term variations before giving up

- ❌ **"WebSearch is faster"**
  - Why wrong: WebSearch gives outdated blog posts, not official docs
  - Correct: Try Context7 with 2+ search terms, THEN WebSearch

### Knowledge Assumptions

- ❌ **"I know how this lib works"**
  - Why wrong: Libraries change, versions differ, you might be wrong
  - Correct: Check Context7 docs anyway for authoritative info

### Workflow Rationalization

- ❌ **"This workflow doesn't apply"**
  - Why wrong: Workflows exist because "simple" tasks become complex
  - Correct: Follow the workflow that matches your task type

---

## Recognizing Rationalization

**You are rationalizing if you:**

1. Skip a workflow step because "it seems unnecessary"
2. Use a familiar tool (grep/Read) instead of correct tool (find_symbol/get_symbols_overview)
3. Assume you understand a library without checking docs
4. Try Context7 once and immediately give up
5. Claim Serena "can't be activated" instead of activating it
6. Read entire files "just to be sure" without trying `get_symbols_overview`

**What to do when you catch yourself rationalizing:**

1. STOP
2. Go back to Tool Selection Priority
3. Follow the correct workflow from the start
4. No shortcuts

---

## Why These Patterns Matter

### Text search vs Semantic search

**Text search (grep):**
- Finds string matches
- Misses: renamed variables, different namespaces, comments
- False positives: string literals, comments

**Semantic search (find_symbol):**
- Finds actual code symbols
- Understands: scope, inheritance, references
- LSP-powered accuracy

### Full file reads vs Symbolic reads

**Full file read:**
- Loads entire file (100s-1000s of lines)
- High token cost
- Unclear what's relevant

**Symbolic read (get_symbols_overview + find_symbol):**
- Loads only structure first
- Then loads specific symbols
- Clear, targeted, efficient

### Guessing vs Official docs

**Guessing from code:**
- See HOW it's used (implementation)
- Miss WHY it's designed that way (intent)
- Don't know best practices or gotchas

**Official docs (Context7):**
- Understand concepts and architecture
- Learn recommended patterns
- Discover edge cases and warnings
- Version-specific accuracy

---

## Recovery from Mistakes

**If you realize you made a mistake:**

1. Acknowledge it (don't rationalize further)
2. State which tool/workflow you should have used
3. Start over with the correct approach
4. Don't try to "recover" with more wrong tools

**Example:**

```
❌ "I used grep and read 5 files, let me read a few more..."

✅ "I should have used find_symbol first. Let me start over:
   1. find_symbol name_path='ClassName' substring_matching=True
   2. get_symbols_overview on the found file
   3. Then read specific symbols if needed"
```

---

## Summary

**The core principle:**

Use the MOST SPECIFIC tool available for your task:
- Know library name? → Context7
- Know symbol name? → find_symbol
- Know file but not symbols? → get_symbols_overview
- Don't know anything? → search_for_pattern (code files only)
- Still unclear? → Read specific symbols
- Last resort? → Read full file

**Never go backwards up this chain without exhausting the more specific tools first.**

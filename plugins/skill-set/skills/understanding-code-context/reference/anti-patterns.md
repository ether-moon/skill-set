# Common Mistakes and Anti-Patterns

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| **WebSearch first** | Use Context7 with multiple search term variations |
| **One search term only** | Try 2+ variations (exact name, framework+concept, org/repo, base name) |
| **Reading source code** | Check Context7 official docs first |
| **Assuming library behavior** | Official docs explain intent, best practices, and gotchas |
| **Giving up after one try** | Try 2+ search term variations before using WebSearch |

---

## Anti-Patterns: Rationalizations

These are excuses that indicate you're about to make a mistake. If you catch yourself thinking these, STOP.

| Excuse | Reality | What To Do Instead |
|--------|---------|-------------------|
| "WebSearch is faster" | Context7 has official, version-specific docs. WebSearch gives outdated blog posts. | Use Context7 with multiple search variations |
| "Context7 found nothing" | You tried 1 search term only | Try 2+ variations before giving up |
| "Can understand from code" | Official docs (Context7) explain intent, best practices, gotchas | Use Context7 with multiple search terms |
| "My knowledge is enough" | Libraries update constantly, Context7 has latest version-specific info | Check Context7 anyway |
| "Reading source is fine" | Time-consuming and doesn't explain intent | Check Context7 official docs first |
| "One search term is enough" | Library names vary (package name, org/repo, base name) | Try 2+ variations |

---

## Red Flags - STOP Immediately

If you catch yourself doing ANY of these, STOP and start over:

### Search Laziness

- ❌ **"Context7 didn't work" after 1 try**
  - Why wrong: You only tried one search term
  - Correct: Try 2+ search term variations before giving up

- ❌ **"WebSearch is faster"**
  - Why wrong: WebSearch gives outdated blog posts, not official docs
  - Correct: Try Context7 with 2+ search terms, THEN WebSearch if needed

### Knowledge Assumptions

- ❌ **"I know how this lib works"**
  - Why wrong: Libraries change, versions differ, you might be wrong
  - Correct: Check Context7 docs anyway for authoritative info

- ❌ **"Can understand from code"**
  - Why wrong: Code shows HOW, not WHY. Official docs explain intent and best practices
  - Correct: Check Context7 docs first

### Tool Misuse

- ❌ **Reading source code before checking docs**
  - Why wrong: Time-consuming and doesn't explain intent
  - Correct: Check Context7 official docs first

---

## Recognizing Rationalization

**You are rationalizing if you:**
1. Use WebSearch before trying Context7 variations
2. Try Context7 once and immediately give up
3. Assume you understand a library without checking docs
4. Read source code instead of checking official docs
5. Skip Context7 because "it seems unnecessary"

**What to do when you catch yourself rationalizing:**
1. STOP
2. Try Context7 with multiple search term variations
3. Read official documentation
4. No shortcuts

---

## Why These Patterns Matter

### Official docs vs WebSearch

**Official docs (Context7):**
- Authoritative, version-specific information
- Explains intent and design rationale
- Best practices and patterns
- Up-to-date information

**WebSearch:**
- Blog posts and tutorials (not official)
- Often outdated
- Version mismatches
- Inconsistent quality

### Official docs vs Source code

**Official docs (Context7):**
- Explains concepts and architecture
- Best practices and patterns
- Intent and design rationale
- Common pitfalls

**Source code:**
- Shows implementation (HOW)
- Doesn't explain intent (WHY)
- Time-consuming to read
- May miss important concepts

---

## Recovery from Mistakes

**If you realize you made a mistake:**
1. Acknowledge it (don't rationalize further)
2. State which approach you should have used
3. Start over with Context7 and multiple search variations
4. Don't try to "recover" with more wrong tools

**Example:**
```
❌ "I used WebSearch and read some blog posts, let me read a few more..."

✅ "I should have used Context7 first. Let me start over:
   1. resolve-library-id 'library-name' (try multiple variations)
   2. get-library-docs to get official documentation
   3. Understand from authoritative source"
```

---

## Summary

**The core principle:**

Use Context7 with multiple search term variations to get official, authoritative documentation for external libraries.

**Never:**
- Use WebSearch before trying Context7
- Try only one search term
- Read source code before checking official docs
- Assume you know how a library works

**Always:**
- Try 2+ search term variations with Context7
- Read official documentation first
- Understand intent and best practices from docs
- Apply official patterns to project usage

# Anti-Patterns and Recovery

## Common Anti-Patterns

Each of these undermines the value of having official documentation available. Understanding why they are counterproductive is more useful than memorizing a list of "don'ts."

### 1. WebSearch Before Context7

**What happens:** You search the web first, find a blog post or StackOverflow answer, and use that as the basis for your response.

**Why it is counterproductive:** Blog posts are often outdated, version-mismatched, or reflect one author's opinion rather than official guidance. Context7 provides the library maintainers' own documentation, which is authoritative and version-specific.

**Better approach:** Try Context7 with at least 2 search term variations first. Fall back to WebSearch only for libraries not indexed in Context7.

### 2. Giving Up After One Search Term

**What happens:** You try `resolve-library-id "library-name"`, get no results, and immediately switch to WebSearch or source code reading.

**Why it is counterproductive:** Library names vary significantly across package managers (npm vs pip vs gems), GitHub organizations, and common usage. A single search term only covers one naming convention.

**Better approach:** Try at least 2 variations: exact package name, framework + concept, org/repo format, or base name. The library is usually there under a different name.

### 3. Reading Source Code Instead of Docs

**What happens:** You open the library's source files and try to understand behavior from the implementation.

**Why it is counterproductive:** Source code shows _how_ something is implemented but not _why_ it was designed that way. Official documentation explains intent, recommended patterns, gotchas, and migration paths that source code does not surface.

**Better approach:** Check Context7 docs first. Read source code only when you need implementation details that docs do not cover (e.g., understanding an undocumented edge case).

### 4. Relying on Prior Knowledge

**What happens:** You assume you know how a library works based on training data or previous experience, and skip the documentation lookup.

**Why it is counterproductive:** Libraries update frequently. APIs change between major versions, configuration options get deprecated, and best practices evolve. Prior knowledge may reflect an older version or incorrect assumptions.

**Better approach:** Check Context7 even for familiar libraries. A quick lookup confirms whether your knowledge is current and often surfaces details you would have missed.

---

## Recovery

If you realize you have already gone down the wrong path (e.g., you used WebSearch results or made assumptions without checking docs):

1. Acknowledge the approach was suboptimal — do not compound the mistake by adding more web searches
2. Start over with the Context7 workflow:
   ```
   resolve-library-id "library-name" (try multiple variations)
   get-library-docs to get official documentation
   ```
3. Revise your earlier understanding based on the official docs

The goal is not perfection on the first attempt — it is recognizing when to course-correct and using the most reliable source available.

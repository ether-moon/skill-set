# Context7 Tool Reference

## Overview

Context7 provides authoritative, version-specific documentation for external libraries and frameworks. These are the two tools this skill uses.

## resolve-library-id

**Purpose:** Find the Context7-compatible library ID for a given library name.

**When to use:** Always the first step when looking up any external library — required before calling `get-library-docs`.

**Parameters:**
- `libraryName` (required): The library name to search for
- `query` (required): Description of what you need help with, used to rank results by relevance

**Command:**
```bash
resolve-library-id libraryName="importmap-rails" query="how to pin JavaScript packages in Rails"
```

**Returns:** A list of matching libraries with:
- Library ID (format: `/org/project`)
- Name and description
- Code snippet count
- Source reputation (High, Medium, Low, Unknown)
- Benchmark score (quality indicator, max 100)
- Available versions

**Selection guidance:** Prioritize results by name match, source reputation, snippet count, and benchmark score. If multiple good matches exist, prefer High reputation with more snippets.

**Search variations:** When the first search does not match, try in this order:
1. Exact package name: `"importmap-rails"`
2. Framework + concept: `"rails import maps"`
3. Organization/repo: `"rails/importmap"`
4. Base name: `"importmap"`

---

## get-library-docs

**Purpose:** Fetch official documentation for a library using its Context7-compatible library ID.

**When to use:** After resolving a library ID with `resolve-library-id`.

**Parameters:**
- `libraryId` (required): Context7-compatible library ID (e.g., `/rails/importmap`, `/vercel/next.js/v14.3.0-canary.87`)
- `query` (required): Specific question or task — be descriptive for better results

**Command:**
```bash
get-library-docs libraryId="/rails/importmap" query="how to pin a new JavaScript package"
```

**Returns:**
- Official, version-specific documentation
- Library concepts and architecture
- API reference and usage patterns
- Best practices, gotchas, and configuration examples

**Tips for better results:**
- Use specific queries: "How to set up JWT authentication in Express" works better than "auth"
- Include the version in `libraryId` if you need version-specific docs (e.g., `/vercel/next.js/v14.3.0-canary.87`)

---

## Why Context7 Over Alternatives

| Source | Strengths | Weaknesses |
|--------|-----------|------------|
| **Context7** | Official, version-specific, authoritative, explains intent and best practices | Some libraries not indexed |
| **WebSearch** | Broad coverage | Often outdated, version mismatches, blog posts over official docs |
| **Source code** | Shows exact implementation | Time-consuming, does not explain intent or best practices |

Context7 should be the first source consulted. WebSearch is a reasonable fallback when a library is not indexed in Context7.

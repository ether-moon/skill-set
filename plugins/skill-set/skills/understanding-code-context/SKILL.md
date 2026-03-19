---
name: understanding-code-context
description: Find and read official documentation for external libraries and frameworks using Context7. Use when researching library APIs, understanding framework configuration, learning library concepts, looking up dependency documentation, or when user asks "how does X library work", "what's the API for X", "look up docs for X", "how to configure X" — provides authoritative, version-specific docs instead of outdated web search results or source code reading.
---

# Understanding Code Context

## Overview

**Core principle**: Use official documentation (Context7) to understand external libraries and frameworks instead of web search or reading source code.

Official docs explain intent, best practices, and version-specific behavior — things you cannot reliably get from blog posts, StackOverflow, or source code alone.

## When to Use

Use this skill when:
- Understanding how an external library or framework works
- Learning library concepts, patterns, and APIs
- Finding official documentation for dependencies
- Understanding library configuration and usage patterns

Not applicable for:
- Exploring project code (use Grep, Glob, Read)
- Finding implementations within the current codebase
- Simple file content reading

## Core Workflow

**Step 1**: Resolve the library ID with `resolve-library-id`. Try multiple search term variations — library names differ across registries, organizations, and common usage.

**Step 2**: Fetch documentation with `get-library-docs` using the resolved ID.

**Step 3**: Read and apply official patterns to the project.

```
1. resolve-library-id "library-name"
   - If not found: try variations (framework + concept, org/repo, base name)
   - Try at least 2 variations before falling back to WebSearch
2. get-library-docs libraryId="/org/project"
3. Apply official patterns and concepts to project usage
```

**Example:**
```
User: "How do I set up authentication middleware in Express?"

1. resolve-library-id "express"
   - If ambiguous: try "expressjs", "express.js middleware"
2. get-library-docs libraryId="/expressjs/express"
3. Explain middleware patterns, app.use() setup, and auth best practices from official docs
```

## Search Strategy

Context7 indexes libraries under various names. When the first search does not match, try variations in this order:

1. **Exact package name**: `"importmap-rails"`, `"@tanstack/react-query"`
2. **Framework + concept**: `"rails import maps"`, `"react server components"`
3. **Organization/repo**: `"rails/importmap"`, `"tanstack/query"`
4. **Base name**: `"importmap"`, `"react-query"`

Context7 has official, version-specific documentation that WebSearch cannot match. Exhausting these variations first avoids falling back to outdated blog posts or StackOverflow answers.

## Avoiding Common Pitfalls

Context7 is the preferred first source because it provides official, version-specific documentation. These habits undermine that advantage:

- **Reaching for WebSearch first** — WebSearch returns blog posts and tutorials that may be outdated or version-mismatched. Try Context7 variations first.
- **Giving up after one search term** — Library names vary across package managers, GitHub orgs, and common usage. Two or more variations usually find the right result.
- **Reading source code instead of docs** — Source code shows implementation (how) but not intent (why). Official docs explain best practices, gotchas, and design rationale.
- **Assuming prior knowledge is sufficient** — Libraries update frequently. Context7 has the latest version-specific information.

For a deeper catalog of these patterns and recovery strategies, see [reference/anti-patterns.md](reference/anti-patterns.md).

## Quick Reference

```bash
# Find library documentation
resolve-library-id "library-name"
get-library-docs libraryId="/org/project"
```

For detailed tool parameters and return values, see [reference/tools.md](reference/tools.md).

For extended workflow patterns and examples, see [reference/workflows.md](reference/workflows.md).

## Troubleshooting

### Context7 Connection Issues

**"Context7 server not connected"**
- Verify MCP server is running in Settings > Extensions
- Reconnect Context7 if status shows disconnected
- Check API key is valid

**"No results found"**
- Try multiple search term variations (see Search Strategy above)
- Check spelling of library name
- Some libraries may not be indexed — fall back to WebSearch

### Library Not Found

**After trying multiple variations:**
1. Check if the library exists on npm/PyPI/crates.io/etc.
2. Use WebSearch as fallback for unindexed libraries
3. Check the library's official documentation URL directly

### Stale Documentation

**"Documentation seems outdated"**
- Context7 provides version-specific docs
- Verify you are using the correct library ID
- Check the library's changelog for recent changes

## See Also

- [reference/tools.md](reference/tools.md) — Detailed tool parameters and usage
- [reference/workflows.md](reference/workflows.md) — Extended workflow patterns with examples
- [reference/anti-patterns.md](reference/anti-patterns.md) — Common mistakes and recovery strategies

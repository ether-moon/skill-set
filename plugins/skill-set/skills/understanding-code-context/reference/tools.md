# Context7 Tool Usage

## Overview

Context7 provides authoritative, version-specific documentation for external libraries and frameworks. This is the primary and only tool used by this skill.

## Tool Commands

### resolve-library-id

**Purpose:** Find the Context7-compatible library ID for a given library name.

**When to use:**
- First step when looking up any external library
- Before calling `get-library-docs`

**Command:**
```bash
resolve-library-id "library-name"
```

**Search Strategy:**

Try multiple variations in this order:

1. **Exact package name**: `"importmap-rails"`
2. **Framework + concept**: `"rails import maps"`
3. **Organization/repo**: `"rails/importmap"`
4. **Base name**: `"importmap"`

**Important**: Try 2+ variations before giving up or using WebSearch.

**Example:**
```bash
# Try 1: Exact name
resolve-library-id "importmap-rails"

# If not found, try 2: Framework + concept
resolve-library-id "rails import maps"

# If not found, try 3: Organization/repo
resolve-library-id "rails/importmap"

# If not found, try 4: Base name
resolve-library-id "importmap"
```

---

### get-library-docs

**Purpose:** Get official documentation for a library using its Context7-compatible library ID.

**When to use:**
- After successfully resolving library ID with `resolve-library-id`
- To understand library concepts, patterns, APIs, and best practices

**Command:**
```bash
get-library-docs context7CompatibleLibraryID="/org/project"
```

**What you get:**
- Official, version-specific documentation
- Library concepts and architecture
- API reference and patterns
- Best practices and gotchas
- Configuration examples

**Example:**
```bash
# After resolve-library-id returns "/rails/importmap"
get-library-docs context7CompatibleLibraryID="/rails/importmap"
```

---

## Complete Workflow

**Understanding an external library:**

```bash
# Step 1: Find library ID (try multiple variations)
resolve-library-id "library-name"
# If not found, try variations:
resolve-library-id "framework concept"
resolve-library-id "org/repo"
resolve-library-id "basename"

# Step 2: Get documentation
get-library-docs context7CompatibleLibraryID="/org/project"

# Step 3: Read and understand official patterns
# Apply understanding to project usage
```

---

## Why Context7 Over Alternatives

**Context7 advantages:**
- ✅ Official, version-specific documentation
- ✅ Authoritative patterns and APIs
- ✅ Up-to-date information
- ✅ Explains intent and best practices
- ✅ No outdated blog posts or StackOverflow answers

**WebSearch disadvantages:**
- ❌ Often outdated information
- ❌ Blog posts and tutorials (not official docs)
- ❌ Version mismatches
- ❌ Inconsistent quality

**Reading source code disadvantages:**
- ❌ Time-consuming
- ❌ Doesn't explain intent or best practices
- ❌ May miss important concepts
- ❌ Version-specific issues

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| **WebSearch first** | Use Context7 with multiple search term variations |
| **One search term only** | Try 2+ variations before giving up |
| **Reading source code** | Check Context7 official docs first |
| **Assuming library behavior** | Official docs explain intent and best practices |

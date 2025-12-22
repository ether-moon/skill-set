# Core Workflow

## Understanding External Library

This is the only workflow provided by this skill. Use it whenever you need to understand an external library, framework, or dependency.

**❌ Old way (baseline):**
```
WebSearch → Read blog posts → Guess from code → Trial and error
```

**✅ New way:**
```
1. resolve-library-id "library-name" (try multiple variations)
2. get-library-docs to understand concepts and patterns
3. Apply official patterns to project usage
```

---

## Detailed Steps

### Step 1: Find Library ID

Try multiple search term variations:

```bash
# Variation 1: Exact package name
resolve-library-id "importmap-rails"

# If not found, Variation 2: Framework + concept
resolve-library-id "rails import maps"

# If not found, Variation 3: Organization/repo
resolve-library-id "rails/importmap"

# If not found, Variation 4: Base name
resolve-library-id "importmap"
```

**Important**: Try 2+ variations before giving up or using WebSearch.

---

### Step 2: Get Documentation

Once you have the library ID:

```bash
get-library-docs context7CompatibleLibraryID="/rails/importmap"
```

This provides:
- Official documentation
- Concepts and architecture
- API reference
- Best practices
- Configuration examples

---

### Step 3: Apply Understanding

Use the official documentation to:
- Understand how the library works
- Learn recommended patterns
- Apply to project usage
- Avoid common pitfalls

---

## Complete Example

**User request:** "Help me understand how importmap works and how to add a new library"

**Workflow execution:**

```markdown
1. resolve-library-id "importmap-rails"
   - If not found: try "rails/importmap", "rails import maps", "importmap"
   
2. get-library-docs context7CompatibleLibraryID="/rails/importmap"
   - Understand: import maps spec, pin vs pin_all_from, CDN vs vendor
   
3. Explain concepts based on official docs:
   - What import maps are
   - How pin() works
   - How to add a new library using pin()
   - Best practices from official docs
```

---

## When This Workflow Applies

**Always use this workflow when:**
- Understanding any external library/framework
- Learning library concepts and patterns
- Finding official documentation
- Understanding library configuration
- Learning how to use a library feature

**This workflow applies to:**
- ✅ Any `import`, `require`, `gem`, external dependency
- ✅ Framework features
- ✅ Library configuration
- ✅ Understanding library APIs

**Common rationalizations to REJECT:**
- "This is just config, not library usage" → WRONG. Config is HOW you use the library. This workflow applies.
- "I can guess from the code" → WRONG. Official docs explain intent and best practices.
- "WebSearch is faster" → WRONG. Context7 has official, version-specific docs.

---

## Why This Workflow Matters

**Official documentation provides:**
- Authoritative information
- Version-specific details
- Best practices and patterns
- Intent and design rationale
- Common pitfalls and gotchas

**Without official docs, you:**
- May misunderstand library behavior
- Miss important concepts
- Use outdated patterns
- Encounter version-specific issues
- Waste time reading source code

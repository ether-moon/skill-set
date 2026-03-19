# Workflow: Understanding External Libraries

## The Workflow

This is the single workflow provided by this skill. Use it whenever you need to understand an external library, framework, or dependency.

```
1. resolve-library-id "library-name" (try multiple search variations)
2. get-library-docs to read official concepts, patterns, and APIs
3. Apply official patterns to project usage
```

This replaces the less reliable default approach of web searching for blog posts, guessing from source code, or relying on prior knowledge that may be outdated.

---

## Detailed Steps

### Step 1: Find Library ID

Try multiple search term variations. Library names differ between package managers, GitHub organizations, and common usage:

```bash
# Variation 1: Exact package name
resolve-library-id libraryName="@tanstack/react-query" query="data fetching and caching"

# If not found — Variation 2: Common name
resolve-library-id libraryName="react-query" query="data fetching and caching"

# If not found — Variation 3: Organization/repo
resolve-library-id libraryName="tanstack/query" query="data fetching and caching"
```

Try at least 2 variations before falling back to WebSearch — Context7 has the library more often than the first search term suggests.

### Step 2: Fetch Documentation

Once you have the library ID, query for the specific topic you need:

```bash
get-library-docs libraryId="/tanstack/query" query="how to use useQuery hook for data fetching with caching"
```

Be specific in your query. "useQuery hook caching and refetch behavior" returns more relevant docs than "react-query".

### Step 3: Apply Understanding

Use the official documentation to:
- Understand the library's intended usage patterns
- Learn recommended configuration approaches
- Identify common pitfalls the docs warn about
- Apply best practices to the project's specific context

---

## Example 1: Rails Dependency

**User request:** "Help me understand how importmap works and how to add a new library"

```
1. resolve-library-id libraryName="importmap-rails" query="how to add JavaScript packages"
   - Found: /rails/importmap-rails

2. get-library-docs libraryId="/rails/importmap-rails" query="pin JavaScript packages and manage import maps"
   - Learned: import maps spec, pin vs pin_all_from, CDN vs vendor

3. Explain:
   - What import maps are and how Rails implements them
   - How pin() works for adding packages
   - When to use pin_all_from for directory-level imports
   - CDN vs vendored approaches based on official recommendations
```

## Example 2: React Library

**User request:** "How do I handle form validation with react-hook-form?"

```
1. resolve-library-id libraryName="react-hook-form" query="form validation setup"
   - Found: /react-hook-form/react-hook-form

2. get-library-docs libraryId="/react-hook-form/react-hook-form" query="register fields, validation rules, and error handling"
   - Learned: useForm hook, register API, validation modes, resolver pattern

3. Explain:
   - How useForm() and register() work together
   - Built-in validation vs schema validation with resolvers
   - Error handling patterns from official docs
   - Performance considerations (uncontrolled vs controlled)
```

---

## When This Workflow Applies

This workflow applies to any task involving external dependencies:
- Any `import`, `require`, `gem`, pip package, or cargo crate
- Framework features and configuration
- Library APIs and usage patterns
- Understanding how a third-party tool works

Configuration is part of library usage. "Just config" still benefits from official docs that explain what each option does and what the defaults mean.

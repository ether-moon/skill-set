---
name: understanding-code-context
description: Use when exploring codebases, finding implementations, understanding library usage, or tracing dependencies - leverages LSP symbolic tools (Serena) and official documentation (Context7) instead of text search and full file reading for efficient, accurate code comprehension
---

# Understanding Code Context

## Overview

**Core principle**: Use semantic understanding (LSP) and official documentation (Context7) instead of text search and file reading.

Text search finds strings. Symbolic tools find meaning.

## MANDATORY FIRST STEPS

**Before ANY code exploration, complete these steps IN ORDER:**

1. `initial_instructions` (if not already read in this session)
2. `activate_project` (if Serena not active for this project)
3. `check_onboarding_performed`
4. `list_memories`

**No exceptions. No "can't activate Serena" excuses. Activate it.**

## When to Use

Use this skill when:
- Finding where a feature is implemented
- Understanding external library/framework usage
- Tracing symbol dependencies and references
- Exploring unfamiliar codebase sections
- Preparing for refactoring (impact analysis)

Don't use for:
- Simple file content reading (use Read directly)
- Exact string replacement (use Edit/grep)

## Tool Selection Priority

**Always follow this order:**

| Priority | Tool | Use When | Example |
|----------|------|----------|---------|
| 1 | **Memory** | Check existing knowledge | `list_memories` → `read_memory` |
| 2 | **Context7** | External lib/framework | `resolve-library-id "importmap-rails"` |
| 3 | **Symbolic Tools** | Know symbol name | `find_symbol "UserBlock"` |
| 4 | **Pattern Search** | Don't know symbol name | `search_for_pattern "block.*user"` |
| 5 | **Full File Read** | Last resort only | `Read app/models/user.rb` |

## Core Workflows

### Workflow 1: Finding Implementation

**❌ Old way (baseline):**
```
Grep "feature_name" → Read entire files → Manual parsing
```

**✅ New way:**
```
1. check_onboarding_performed
2. list_memories → read relevant memories
3. find_symbol "FeatureName" (with substring_matching if needed)
4. get_symbols_overview (if need to understand file structure first)
5. find_referencing_symbols (to see usage)
6. Only read specific symbol bodies (include_body=True)
```

**Example:**
```markdown
User: "Where is the user blocking feature implemented?"

You:
1. check_onboarding_performed
2. list_memories (check for "architecture" or "models")
3. find_symbol name_path="UserBlock" substring_matching=False
   - If not found: find_symbol name_path="block" substring_matching=True
4. find_referencing_symbols on UserBlock to see controllers/services
5. get_symbols_overview for controller file to see available actions
6. Read only the specific action methods needed
```

### Workflow 2: Understanding External Library

**❌ Old way (baseline):**
```
Read config files → Read gem source code → Guess from code
```

**✅ New way:**
```
1. resolve-library-id "library-name"
2. get-library-docs to understand concepts and patterns
3. find_symbol to locate project's configuration
4. find_referencing_symbols to see actual usage examples in codebase
5. Combine: official patterns (Context7) + project usage (Serena)
```

**Example:**
```markdown
User: "Help me understand how importmap works and how to add a new library"

You:
1. resolve-library-id "importmap-rails"
   - If not found: try "rails/importmap", "rails import maps", "importmap"
2. get-library-docs (understand: import maps spec, pin vs pin_all_from, CDN vs vendor)
3. find_file "importmap.rb" to locate config
4. get_symbols_overview config/importmap.rb
5. find_referencing_symbols on "pin" method to see usage patterns
6. Explain: official concept (from Context7) + project examples (from Serena)
```

#### Context7 Search Strategy

When official library documentation is needed:

1. Try exact gem/package name: `"importmap-rails"`
2. Try framework + concept: `"rails import maps"`
3. Try organization/repo: `"rails/importmap"`
4. Try base name: `"importmap"`

**ONLY use WebSearch after trying 2+ variations.**

**Why:** Context7 has official, version-specific documentation. WebSearch gives you blog posts and outdated StackOverflow. Official docs are more accurate.

### Workflow 3: Tracing Dependencies

**❌ Old way (baseline):**
```
Grep class name → Read all matching files → Manual connection
```

**✅ New way:**
```
1. find_symbol to locate the symbol
2. find_referencing_symbols to get all references with context snippets
3. Analyze snippets (often sufficient without reading full files)
4. Read full symbol body only if snippet unclear
```

**Example:**
```markdown
User: "Find all usages of the UserMannerPoint class"

You:
1. find_symbol name_path="UserMannerPoint" relative_path="app/models"
2. find_referencing_symbols name_path="UserMannerPoint" relative_path="app/models/user_manner_point.rb"
   - Returns: referencing symbols WITH code snippets
3. Analyze the snippets to understand usage patterns
4. Only read full files if snippets don't provide enough context
```

### Workflow 4: Complex Analysis (3+ Components)

**When analysis spans multiple layers (frontend + backend + DB + external service):**

```
1. Consider using Sequential MCP for systematic analysis
2. Sequential can coordinate: Context7 (docs) + Serena (code) + your reasoning
3. See MCP_Sequential.md for triggers
```

## Workflow Selection - NOT YOUR CHOICE

**You don't decide if a workflow applies. It applies. Follow it.**

| Workflow | Applies When | Does NOT Apply When |
|----------|--------------|---------------------|
| Workflow 1 | Finding ANY implementation (models, controllers, services, etc.) | NEVER - always applies to implementation searches |
| Workflow 2 | Understanding ANY external lib/gem/package/framework | NEVER - configuration IS part of usage |
| Workflow 3 | Finding ANY symbol usages/references/dependencies | NEVER - always applies to dependency tracking |
| Workflow 4 | Analysis spans 3+ components across layers | Simple single-file or single-component tasks |

**Common rationalizations to REJECT:**

- "This is just config, not library usage" → WRONG. Config is HOW you use the library. Workflow 2 applies.
- "I'm just finding a file, not implementation" → WRONG. Finding implementation files uses Workflow 1.
- "Workflow is overkill" → WRONG. Workflows exist because "simple" tasks become complex. Follow it.

## Red Flags - STOP Immediately

If you catch yourself doing ANY of these, STOP and start over:

- ❌ Using Grep before `find_symbol`
- ❌ Using Read before `get_symbols_overview`
- ❌ "Serena isn't activated" (activate it!)
- ❌ "Context7 didn't work" after 1 try (try 2+ search terms!)
- ❌ "This workflow doesn't apply" (yes it does!)
- ❌ "WebSearch is faster" (it's less accurate!)
- ❌ "I know how this lib works" (check docs anyway!)
- ❌ "Just need to check one file" (use `get_symbols_overview` first!)

**All of these mean: STOP. Go back to Tool Selection Priority. Start over with correct tools.**

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| **Grep first** | Use `find_symbol` with `substring_matching=True` if unsure of exact name |
| **Read entire files** | Use `get_symbols_overview` first, then read specific symbols |
| **Ignore Context7** | For any `import`, `require`, `gem`, check Context7 for official docs |
| **Skip memories** | Always `list_memories` at start to check existing knowledge |
| **Text search for symbols** | Use `find_symbol` and `find_referencing_symbols` (LSP-powered, accurate) |
| **Guess library usage** | `resolve-library-id` + `get-library-docs` for official patterns |

## Anti-Patterns: Rationalizations

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

## Integration with Other MCPs

**Serena** (this skill's foundation):
- `find_symbol`: Locate symbols by name path
- `find_referencing_symbols`: Find all references (LSP-powered)
- `get_symbols_overview`: Understand file structure before reading
- `*_memory`: Persistent learning across sessions

**Context7** (external knowledge):
- `resolve-library-id`: Find library documentation
- `get-library-docs`: Get official patterns and APIs

**Sequential** (complex analysis):
- Use when 3+ interconnected components
- Coordinates multiple MCPs systematically

## Memory Usage

**Start with existing knowledge:**
- Always check `list_memories` before exploring
- Read relevant memories to avoid redundant exploration

**Memory writing is handled by general workflow patterns, not this skill.**

## Quick Reference

**Finding code:**
```
find_symbol name_path="ClassName/method_name" relative_path="app/models"
```

**Understanding structure:**
```
get_symbols_overview relative_path="app/models/user.rb"
```

**Finding usages:**
```
find_referencing_symbols name_path="ClassName" relative_path="app/models/class.rb"
```

**External library:**
```
resolve-library-id "library-name"
get-library-docs context7CompatibleLibraryID="/org/project"
```

**Check memory:**
```
list_memories
read_memory memory_file_name="architecture-feature.md"
```

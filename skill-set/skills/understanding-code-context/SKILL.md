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

## Quick Tool Selection

| Priority | Tool | Use When |
|----------|------|----------|
| 1 | **Memory** | Check existing knowledge |
| 2 | **Context7** | External lib/framework |
| 3 | **Symbolic Tools** | Know symbol name |
| 4 | **Pattern Search** | Don't know symbol name |
| 5 | **Full File Read** | Last resort only |

**Detailed tool descriptions and examples**: See [reference/tools.md](reference/tools.md)

## Core Workflows

This skill provides 4 workflows:

1. **Finding Implementation** - Locate where features are implemented
2. **Understanding External Library** - Learn how libraries work and are configured
3. **Tracing Dependencies** - Find all usages of a symbol
4. **Complex Analysis** - Analyze 3+ interconnected components

**Detailed workflow steps and examples**: See [reference/workflows.md](reference/workflows.md)

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

**Complete list of mistakes and anti-patterns**: See [reference/anti-patterns.md](reference/anti-patterns.md)

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

# Core Workflows

## Workflow 1: Finding Implementation

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

---

## Workflow 2: Understanding External Library

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

### Context7 Search Strategy

When official library documentation is needed:

1. Try exact gem/package name: `"importmap-rails"`
2. Try framework + concept: `"rails import maps"`
3. Try organization/repo: `"rails/importmap"`
4. Try base name: `"importmap"`

**ONLY use WebSearch after trying 2+ variations.**

**Why:** Context7 has official, version-specific documentation. WebSearch gives you blog posts and outdated StackOverflow. Official docs are more accurate.

---

## Workflow 3: Tracing Dependencies

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

---

## Workflow 4: Complex Analysis (3+ Components)

**When analysis spans multiple layers (frontend + backend + DB + external service):**

```
1. Consider using Sequential MCP for systematic analysis
2. Sequential can coordinate: Context7 (docs) + Serena (code) + your reasoning
3. See MCP_Sequential.md for triggers
```

---

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

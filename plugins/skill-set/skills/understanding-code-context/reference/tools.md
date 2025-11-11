# Tool Selection and Usage

## Tool Selection Priority

**Always follow this order:**

| Priority | Tool | Use When | Example |
|----------|------|----------|---------|
| 1 | **Memory** | Check existing knowledge | `list_memories` → `read_memory` |
| 2 | **Context7** | External lib/framework | `resolve-library-id "importmap-rails"` |
| 3 | **Symbolic Tools** | Know symbol name | `find_symbol "UserBlock"` |
| 4 | **Pattern Search** | Don't know symbol name | `search_for_pattern "block.*user"` |
| 5 | **Full File Read** | Last resort only | `Read app/models/user.rb` |

## Tool Details

### 1. Memory (Serena)

**Purpose:** Leverage existing knowledge from previous sessions

**When to use:**
- ALWAYS at the start of exploration (`list_memories`)
- Before deep diving into codebase
- To avoid redundant exploration

**Commands:**
```bash
list_memories
read_memory memory_file_name="architecture-feature.md"
```

**Why first:** Saves time by reusing accumulated knowledge.

---

### 2. Context7 (Official Documentation)

**Purpose:** Get authoritative, version-specific documentation for external libraries

**When to use:**
- Any `import`, `require`, `gem`, external dependency
- Understanding library concepts and patterns
- Before reading project configuration files

**Commands:**
```bash
resolve-library-id "importmap-rails"
get-library-docs context7CompatibleLibraryID="/rails/importmap"
```

**Search strategy:**
1. Exact name: `"importmap-rails"`
2. Framework + concept: `"rails import maps"`
3. Organization/repo: `"rails/importmap"`
4. Base name: `"importmap"`

Try 2+ variations before using WebSearch.

**Why before code:** Official docs explain intent, best practices, and gotchas that code alone won't reveal.

---

### 3. Symbolic Tools (Serena LSP)

**Purpose:** Semantic code navigation using Language Server Protocol

#### 3a. find_symbol

**When to use:**
- You know (or can guess) the symbol name
- Finding classes, methods, functions by name

**Examples:**
```bash
# Exact match
find_symbol name_path="UserBlock" substring_matching=False

# Fuzzy search
find_symbol name_path="block" substring_matching=True

# With depth (get children)
find_symbol name_path="UserBlock" depth=1 include_body=False

# Read specific method
find_symbol name_path="UserBlock/create" include_body=True
```

**Name path patterns:**
- `"ClassName"` - Top-level class
- `"ClassName/method"` - Method within class
- `"/ClassName"` - Absolute path (top-level only)
- `"method"` - Any method with that name (no ancestor restriction)

#### 3b. get_symbols_overview

**When to use:**
- Before reading entire file
- Understanding file structure
- Finding what symbols exist in a file

**Example:**
```bash
get_symbols_overview relative_path="app/models/user.rb"
```

**Returns:** Top-level symbols with metadata (kind, range, children count)

**Why before Read:** Understand structure without loading full content.

#### 3c. find_referencing_symbols

**When to use:**
- Finding all usages of a symbol
- Understanding dependencies
- Impact analysis before refactoring

**Example:**
```bash
find_referencing_symbols name_path="UserBlock" relative_path="app/models/user_block.rb"
```

**Returns:** Referencing symbols WITH code snippets

**Why powerful:** Context snippets often sufficient without reading full files.

---

### 4. Pattern Search (Serena)

**Purpose:** Flexible regex-based search when you don't know symbol names

**When to use:**
- Don't know exact symbol name
- Searching for patterns across files
- Non-code files (YAML, JSON, etc.)

**Example:**
```bash
search_for_pattern substring_pattern="block.*user"
                   restrict_search_to_code_files=True
                   context_lines_before=2
                   context_lines_after=2
```

**Options:**
- `restrict_search_to_code_files=True` - Code files only (faster)
- `restrict_search_to_code_files=False` - All files (including YAML, JSON)
- `paths_include_glob="*.rb"` - Filter by file pattern
- `relative_path="app/models"` - Restrict to directory

**Why after symbolic tools:** Slower and less semantic than `find_symbol`.

---

### 5. Full File Read

**Purpose:** Read complete file contents

**When to use (LAST RESORT):**
- Small files (<100 lines)
- Non-code files (README, config)
- After all other approaches failed

**Why last:** Most token-expensive. Use `get_symbols_overview` + targeted symbol reads instead.

---

## Decision Tree

```
Need to understand code?
├─ Is it external library/framework?
│  └─ YES → Context7 (resolve-library-id + get-library-docs)
│
├─ Do I know the symbol name?
│  ├─ YES → find_symbol
│  └─ NO → Can I guess pattern?
│     ├─ YES → search_for_pattern (code files only)
│     └─ NO → get_symbols_overview first, then find_symbol
│
├─ Need to see all usages?
│  └─ find_referencing_symbols
│
└─ Still unclear?
   └─ Read specific symbol bodies (include_body=True)
      └─ ONLY IF NECESSARY → Read full file
```

---

## Common Tool Combinations

### Exploring New Feature
```bash
1. list_memories
2. find_symbol name_path="FeatureName" substring_matching=True
3. find_referencing_symbols name_path="FeatureName" relative_path="..."
4. get_symbols_overview relative_path="..." (for related files)
```

### Understanding Library Usage
```bash
1. resolve-library-id "library-name"
2. get-library-docs context7CompatibleLibraryID="/org/project"
3. find_file "config_file_name"
4. get_symbols_overview relative_path="config/..."
5. find_referencing_symbols (to see actual usage)
```

### Impact Analysis
```bash
1. find_symbol name_path="ClassName"
2. find_referencing_symbols name_path="ClassName" relative_path="..."
3. Analyze snippets (often sufficient)
4. Read specific symbol bodies only if snippets unclear
```

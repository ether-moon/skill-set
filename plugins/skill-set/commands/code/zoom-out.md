---
description: Draw a higher-level system map of unfamiliar code in the project's domain vocabulary. Describes the module's responsibility, callers, dependencies, and sibling modules without diving into implementation details.
---

Invoke the `zooming-out-on-code` skill to get oriented in an unfamiliar area of the codebase. The skill goes up one level of abstraction from the file or function in question, reads the project's `CONTEXT.md` and relevant ADRs first, and produces a four-part map: responsibility, callers, dependencies, siblings — all in domain vocabulary, not implementation language.

**When to use this command:**
- Before changing code in an area you don't know
- When a teammate hands off a system you have no prior context on
- When you need orientation before diving deeper

**Output is intentionally compact.** Deeper detail is a follow-up question, not part of this command's output.

# Interface Design

**When to skip:** if the right interface is already obvious for the chosen candidate, skip this entire reference and hand off to `grilling-plans` directly. Use this only when the interface shape would set a long-term direction and the user is unsure between alternatives.

When the user picks a deepening candidate and you need to explore alternative interfaces for the deepened module, use this **parallel sub-agent pattern**.

Based on Ousterhout's "Design It Twice": your first interface idea is unlikely to be the best. Force yourself to generate radically different alternatives, then choose.

Uses the vocabulary in `deep-modules.md` — **module**, **interface**, **seam**, **adapter**, **leverage**.

## Process

### 1. Frame the problem space

Before spawning sub-agents, write a user-facing explanation of the problem space for the chosen candidate:

- The constraints any new interface would need to satisfy
- The dependencies it would rely on, and which category they fall into (see `deepening.md`)
- A rough illustrative code sketch to ground the constraints — not a proposal, just a way to make the constraints concrete

Show this to the user, then immediately proceed to step 2. The user reads and thinks while sub-agents work in parallel.

### 2. Spawn sub-agents

Use the `Agent` tool with `superpowers:dispatching-parallel-agents` to spawn 3+ agents in parallel. Each must produce a **radically different** interface for the deepened module. (Ousterhout's original argument is "design it twice"; we go to three because the fourth Ports & Adapters constraint only fires for category-3/4 dependencies, so three is the realistic floor when network seams are in play.)

Prompt each sub-agent with a separate technical brief: file paths, coupling details, dependency category from `deepening.md`, what sits behind the seam. The brief is independent of the user-facing problem-space explanation. Give each agent a different design constraint:

- **Agent 1: Minimize the interface.** Aim for 1–3 entry points max. Maximize leverage per entry point.
- **Agent 2: Maximize flexibility.** Support many use cases and extension points.
- **Agent 3: Optimize for the most common caller.** Make the default case trivial; rare cases may carry extra ceremony.
- **Agent 4 (when applicable): Ports & Adapters.** Design around the dependency seams from `deepening.md` so adapters can vary without touching the logic.

Include both architecture vocabulary (`deep-modules.md`) and project domain vocabulary (`CONTEXT.md`) in each brief so each sub-agent names things consistently.

Each sub-agent outputs:

1. **Interface** — types, methods, params, plus invariants, ordering, error modes
2. **Usage example** showing how callers use it
3. **What the implementation hides** behind the seam
4. **Dependency strategy** and adapters (per `deepening.md`)
5. **Trade-offs** — where leverage is high, where it's thin

### 3. Present and compare

Present designs **sequentially** so the user can absorb each one, then compare them in prose. Contrast by:

- **Depth** — leverage at the interface
- **Locality** — where change concentrates
- **Seam placement** — what varies, what's fixed

After comparing, give your own recommendation: which design you think is strongest and why. **Be opinionated — the user wants a strong read, not a menu.** If elements from different designs combine well, propose a hybrid.

### 4. Hand off to grilling

Once the user picks a design, hand off to `grilling-plans` to interrogate it before implementation. Designs always look better in the abstract; grilling forces the unspoken assumptions into the open.

# Agent Team Skill Research

**Date**: 2026-03-07
**Objective**: Research foundations for building an "agent team" skill for skill-set

---

## 1. Anthropic Official Patterns & Infrastructure

### 1.1 Agentic Design Patterns (Building Effective Agents, Dec 2024)

Anthropic distinguishes **Workflows** (predefined code paths) from **Agents** (LLMs dynamically directing their own processes) and recommends simple, composable patterns over complex frameworks.

**Five workflow patterns:**

| Pattern | Description | When to Use |
|---------|-------------|-------------|
| **Prompt Chaining** | Sequential LLM calls, each processing previous output | Decomposable tasks with clear steps |
| **Routing** | Initial LLM classifies input, dispatches to specialized handlers | Distinct input categories needing different treatment |
| **Parallelization** | LLMs work simultaneously ("sectioning" or "voting") | Independent subtasks or consensus-building |
| **Orchestrator-Workers** | Central LLM decomposes tasks at runtime, delegates to workers, synthesizes | Complex tasks where subtasks aren't known upfront |
| **Evaluator-Optimizer** | One LLM generates, another evaluates in a feedback loop | Iterative quality improvement |

> Anthropic advises starting with direct LLM API calls rather than complex frameworks.

**Source**: https://www.anthropic.com/research/building-effective-agents

### 1.2 Claude Agent SDK

Available as `@anthropic-ai/claude-agent-sdk` (TypeScript) and `claude-agent-sdk` (Python). Provides the same runtime powering Claude Code as a programmable library.

**Multi-agent capabilities:**

- **Subagents via `agents` parameter**: Define agent types with `AgentDefinition` objects specifying `description`, `prompt`, `tools`, and optionally `model`. Include `Task` in `allowedTools` to enable delegation.
- **Context isolation**: Each subagent runs in its own fresh conversation. Only the final result returns to the parent.
- **Parallelization**: Multiple subagents can run concurrently; results are synthesized.
- **Nesting restriction**: Subagents cannot spawn other subagents.
- **Sessions**: Supports session persistence via `session_id` and `resume`.
- **MCP integration**: MCP servers plug in directly via `mcpServers`.
- **Three-layer architecture**: MCP (protocol) → Agent Skills (capability packages) → Agent SDK (runtime)

**Sources**:
- https://platform.claude.com/docs/en/agent-sdk/overview
- https://platform.claude.com/docs/en/agent-sdk/subagents

### 1.3 Claude Code Built-in Subagent System

Three built-in subagent types:

| Subagent | Model | Tools | Purpose |
|----------|-------|-------|---------|
| **Explore** | Haiku | Read-only | File discovery, code search |
| **Plan** | Inherits | Read-only | Research for plan mode |
| **General-purpose** | Inherits | All tools | Complex multi-step tasks |

**Custom subagents**: Markdown files with YAML frontmatter in `.claude/agents/` (project) or `~/.claude/agents/` (user).

Key configuration fields:
- `name`, `description` (required)
- `tools` / `disallowedTools` — allowlist/denylist
- `model` — sonnet, opus, haiku, or inherit
- `permissionMode` — default, acceptEdits, dontAsk, bypassPermissions, plan
- `maxTurns`, `skills`, `memory`, `background`, `isolation` (git worktree), `hooks`, `mcpServers`

Agent tool spawns subagents. Can restrict spawnable types using `Agent(worker, researcher)` syntax. Supports foreground (blocking) and background (concurrent) execution.

**Source**: https://code.claude.com/docs/en/sub-agents

### 1.4 Claude Code Agent Teams (Experimental)

Higher-level multi-agent orchestration system. Enabled via `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. Requires Opus 4.6+, introduced in Claude Code v2.1.32 (Feb 2026).

**Architecture:**
- **Team Lead**: Main session that creates the team, spawns teammates, coordinates
- **Teammates**: Fully independent Claude Code instances with their own context windows
- **Shared Task List**: Tasks with states and dependency tracking
- **Mailbox**: Direct peer-to-peer messaging between teammates

**Subagents vs. Agent Teams:**

| Dimension | Subagents | Agent Teams |
|-----------|-----------|-------------|
| Context | Results return to caller | Fully independent |
| Communication | Report to parent only | Direct peer-to-peer |
| Coordination | Parent manages all work | Shared task list, self-coordination |
| Best for | Focused tasks, result-only | Complex work requiring discussion |
| Token cost | Lower | Higher (each is a full instance) |

**TeammateTool operations**: spawnTeam, cleanup, message, broadcast, shutdown_request/response, plan_approval_response, TaskCreate, TaskUpdate, TaskList, TaskGet

**Best practices**: 3-5 teammates; 5-6 tasks per teammate; avoid same-file edits; teammates don't inherit conversation history (only project context like CLAUDE.md).

**Limitations**: No session resumption with in-process teammates, no nested teams, one team per session, fixed lead.

**Source**: https://code.claude.com/docs/en/agent-teams

---

## 2. Open-Source Multi-Agent Frameworks

### 2.1 LangGraph (LangChain)

- **GitHub**: github.com/langchain-ai/langgraph — LangChain: 80K+ stars
- **Architecture**: Graph-based state machine. Agents are nodes; conditional edges determine flow. Supports cycles, loops, retries, human-in-the-loop.
- **Multi-agent patterns**: Supervisor (one agent delegates), Swarm (peer handoffs), Pipeline (sequential), Scatter-gather (parallel fan-out/fan-in)
- **Claude support**: Yes, via LangChain model integrations
- **Config format**: Code-first (Python, TypeScript). `StateGraph`, `add_node`, `add_edge`
- **Use cases**: Complex stateful workflows, production systems with checkpointing, compliance-heavy enterprise
- **Status**: Very active. v1.0 in late 2025. Used by Klarna, Replit, Uber, LinkedIn, Elastic

### 2.2 CrewAI

- **GitHub**: github.com/crewAIInc/crewAI — ~44,300 stars, 5.2M monthly downloads
- **Architecture**: Role-based teams. Each agent has role, goal, backstory. Two modes: Crews (autonomous) and Flows (event-driven production pipelines).
- **Multi-agent patterns**: Sequential or hierarchical task execution. Agents can delegate to each other.
- **Claude support**: Yes, via LiteLLM
- **Config format**: **YAML-based** (recommended). `config/agents.yaml` + `config/tasks.yaml`. Python class with `@CrewBase` decorator.
- **Use cases**: Rapid prototyping, content pipelines, research teams, business process automation
- **Status**: Very active. 100K+ developers certified.

### 2.3 Microsoft AutoGen → Agent Framework

- **GitHub**: github.com/microsoft/autogen — ~54,600 stars, 856K monthly downloads
- **Architecture**: Conversational patterns. Agents interact through multi-turn conversations. Event-driven.
- **Claude support**: Yes
- **Status**: **Maintenance mode** since Oct 2025. Merged with Semantic Kernel into Microsoft Agent Framework (GA targeting Q1 2026).

### 2.4 OpenAI Agents SDK

- **GitHub**: github.com/openai/openai-agents-python — ~19,000 stars, 10.3M monthly downloads
- **Architecture**: Lightweight primitives — Agents (LLMs + instructions + tools), Handoffs (delegation), Guardrails (validation). Minimal abstractions.
- **Multi-agent patterns**: Handoff-based. Agent explicitly hands off to another. No central orchestrator required.
- **Claude support**: Yes, provider-agnostic via Chat Completions API
- **Config format**: Code-first (Python, TypeScript)
- **Use cases**: Production multi-agent workflows, customer service routing
- **Status**: Very active. Swarm (educational) deprecated in favor of this.

### 2.5 Google Agent Development Kit (ADK)

- **GitHub**: github.com/google/adk-python — ~17,800 stars, 3.3M monthly downloads
- **Architecture**: Event-driven runtime with hierarchical agent tree. Built-in primitives: `SequentialAgent`, `CoordinatorAgent`, `LoopAgent`, `ParallelAgent`.
- **Claude support**: Yes, via LiteLLM
- **Config format**: Code-first (Python, TypeScript, Go, Java)
- **Use cases**: Google ecosystem, multi-modal agents, enterprise
- **Status**: Very active. Launched April 2025. Supports A2A protocol and MCP.

### 2.6 Mastra

- **GitHub**: github.com/mastra-ai/mastra — fast-growing, 150K weekly NPM downloads
- **Architecture**: TypeScript-native. Agent Networks with LLM-based routing. Workflow orchestration.
- **Claude support**: Yes, model-agnostic
- **Use cases**: TypeScript/JS-first development, web app integration, RAG
- **Status**: Very active. $13M seed (YC). Used by Replit Agent 3, PayPal, Adobe, Docker.

### 2.7 Pydantic AI

- **GitHub**: github.com/pydantic/pydantic-ai — ~15,200 stars
- **Architecture**: "FastAPI for AI agents." Type-safe, model-agnostic. MCP + A2A support.
- **Claude support**: Yes, first-class Anthropic support
- **Use cases**: Type-safe agents, structured outputs, production agents with observability
- **Status**: Very active (v1.66.0)

### 2.8 Others

| Framework | Stars | Notes |
|-----------|-------|-------|
| **Dify** | ~129K | Low-code/visual platform, drag-and-drop |
| **Agency Swarm** | ~3,900 | Real-world org structures (CEO, VA, Developer roles) |

---

## 3. Cross-Framework Patterns

### 3.1 Agent Coordination Models

| Model | Description | Frameworks |
|-------|-------------|------------|
| **Supervisor/Coordinator** | One agent dispatches tasks to specialists | LangGraph, ADK, CrewAI hierarchical |
| **Peer Handoff/Swarm** | Agents hand off directly without central control | OpenAI Agents SDK, LangGraph Swarm |
| **Sequential Pipeline** | Assembly-line through ordered agents | Universal |
| **Parallel Fan-out/Fan-in** | Simultaneous distribution, consolidated results | LangGraph scatter-gather, ADK ParallelAgent |
| **Conversational** | Multi-turn dialogue between agents | AutoGen's original pattern |

### 3.2 Agent Communication Mechanisms

- **Shared state**: Agents read/write to common state (LangGraph)
- **Message passing**: Structured messages (AutoGen, ADK events)
- **Direct delegation**: One agent explicitly calls another (CrewAI, OpenAI handoffs)
- **LLM-routed**: LLM decides which agent handles subtask (ADK AutoFlow, Mastra)

### 3.3 Agent Definition Commonalities

Every framework requires:
1. **Identity**: Role/name/description
2. **Goal/Objective**: What the agent should achieve
3. **Instructions**: System prompt or behavior specification
4. **Tools**: Available capabilities
5. **Model**: Which LLM to use

Optional additions:
- Backstory/personality (CrewAI)
- Guardrails (OpenAI Agents SDK)
- Type-safe outputs (Pydantic AI)
- Memory/persistence

### 3.4 Configuration Approaches

| Approach | Frameworks | Pros | Cons |
|----------|------------|------|------|
| **YAML** | CrewAI | Declarative, easy to read | Less flexible |
| **Code-first** | LangGraph, OpenAI SDK, ADK, Mastra, Pydantic AI | Maximum flexibility | More complex |
| **Visual/Low-code** | Dify | Accessible | Limited customization |
| **Markdown + Frontmatter** | Claude Code custom subagents | Natural for Claude skills | Claude-specific |

### 3.5 Emerging Interoperability Standards

- **Agent2Agent (A2A)**: Google-initiated, adopted by ADK, Pydantic AI, CrewAI
- **Model Context Protocol (MCP)**: Anthropic-initiated, widely adopted for tool integration
- **Agent Skills**: Anthropic-initiated open standard for capability packages

---

## 4. Existing Patterns in skill-set Codebase

### 4.1 Ralph — Sequential Loop with Fresh Context

- Two modes (PLANNING/BUILDING)
- Spawns one Task subagent per iteration with fresh context
- **State**: Plan file on disk (`tmp/ralph/{session-id}/plan.md`)
- **Progress**: Git commits + plan file hash changes
- **Stuck detection**: 3 consecutive iterations with no progress

### 4.2 Consulting-Peer-LLMs — Parallel Multi-Tool Execution

- Detects installed CLI tools (gemini, codex, claude)
- Launches all simultaneously in background
- Waits for all, then synthesizes results
- Shows raw responses first, then consolidates

### 4.3 CodeRabbit-Feedback — Interactive Isolated Subagent

- Three phases: Collection → Discussion → Application
- Severity classification (CRITICAL/MAJOR/MINOR)
- Triple verification system for applied changes

### 4.4 State Management Comparison

| Skill | State Location | Update Frequency | Context Sharing |
|-------|---------------|-----------------|-----------------|
| ralph | Disk (plan.md) | Every iteration | Fresh context per subagent |
| consulting-peer-llms | Memory | Single pass | None (parallel) |
| coderabbit-feedback | GitHub API | Per phase | User approval between phases |

---

## 5. Design Implications for Agent Team Skill

### 5.1 Which Claude Infrastructure to Target?

| Option | Maturity | Fit for Skill |
|--------|----------|--------------|
| **Custom subagents** (`.claude/agents/`) | Stable | Best: generate agent definitions, orchestrate via skill |
| **Agent Teams** (experimental) | Experimental | Future: powerful but requires env flag, Opus 4.6+ |
| **Agent SDK** (external) | Stable | Out of scope: for external apps, not Claude Code skills |

**Recommendation**: Build primarily on custom subagents (stable), with optional Agent Teams support as experimental extension.

### 5.2 Orchestration Pattern Selection

Based on research, the most applicable patterns for a Claude Code skill:

1. **Orchestrator-Workers** (Anthropic's own recommendation for complex tasks)
2. **Parallel Fan-out/Fan-in** (already proven in consulting-peer-llms)
3. **Sequential Pipeline** (already proven in ralph)

### 5.3 Key Design Decisions

1. **Team definition format**: Markdown + YAML frontmatter (consistent with Claude Code custom subagents)
2. **State management**: Disk-based (proven by ralph pattern)
3. **Communication**: File-based shared state + result synthesis (practical for Claude Code)
4. **Agent spawning**: Via Agent tool with configurable subagent types
5. **Progress tracking**: Git commits + file hash changes (proven pattern)

### 5.4 What to Borrow from Open-Source

| Concept | Source | Application |
|---------|--------|-------------|
| Role/Goal/Backstory agent definition | CrewAI | Structured agent identity in YAML |
| Sequential + Hierarchical process types | CrewAI | Team execution modes |
| Graph-based conditional routing | LangGraph | Complex workflow support |
| Handoff mechanism | OpenAI Agents SDK | Agent-to-agent delegation |
| Built-in orchestration primitives | Google ADK | SequentialAgent, ParallelAgent, CoordinatorAgent concepts |
| Shared state object | LangGraph | Centralized team state |

---

## 6. Sources

### Anthropic Official
- [Building Effective Agents](https://www.anthropic.com/research/building-effective-agents)
- [Agent SDK Overview](https://platform.claude.com/docs/en/agent-sdk/overview)
- [Agent SDK Subagents](https://platform.claude.com/docs/en/agent-sdk/subagents)
- [Claude Code Custom Subagents](https://code.claude.com/docs/en/sub-agents)
- [Claude Code Agent Teams](https://code.claude.com/docs/en/agent-teams)
- [Building Agents with Claude Agent SDK](https://www.anthropic.com/engineering/building-agents-with-the-claude-agent-sdk)
- [Multi-Agent Research System](https://www.anthropic.com/engineering/multi-agent-research-system)
- [Anthropic Cookbook - Agent Patterns](https://github.com/anthropics/anthropic-cookbook/tree/main/patterns/agents)

### Open-Source Frameworks
- [LangGraph](https://github.com/langchain-ai/langgraph)
- [CrewAI](https://github.com/crewAIInc/crewAI)
- [Microsoft AutoGen](https://github.com/microsoft/autogen)
- [OpenAI Agents SDK](https://github.com/openai/openai-agents-python)
- [Google ADK](https://github.com/google/adk-python)
- [Mastra](https://github.com/mastra-ai/mastra)
- [Pydantic AI](https://github.com/pydantic/pydantic-ai)
- [Dify](https://github.com/langgenius/dify)

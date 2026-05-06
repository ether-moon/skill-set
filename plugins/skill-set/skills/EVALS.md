# Skill Evaluation Conventions

This document describes the conventions used by `evals.json` files under each
skill (`plugins/skill-set/skills/<skill>/evals/evals.json`) and the supporting
`evals/files/` fixture directories.

It is the canonical reference for the eval schema. Each skill's `evals/`
directory may contain a short `README.md` that points to this document instead
of duplicating the conventions.

## File layout

```
plugins/skill-set/skills/<skill>/
└── evals/
    ├── evals.json              # eval definitions for this skill
    └── files/                  # input fixtures
        └── <eval-name>/        # one directory per eval (matches `name` in evals.json)
            └── ...             # fixture files referenced by `files` paths
```

## evals.json schema

Each `evals.json` is an object:

```json
{
  "skill_name": "<skill-name>",
  "evals": [ { "id": 0, "name": "...", "prompt": "...", "files": [...], "expectations": [...] } ]
}
```

### Field semantics

- **`skill_name`** — must match the parent directory name (`skills/<skill_name>/`).
- **`id`** — stable integer identifier for the eval, scoped to the skill.
- **`name`** — kebab-case identifier; must match a directory under `evals/files/`.
- **`prompt`** — the user-facing prompt sent to the agent. May reference paths
  relative to the eval's fixture directory.
- **`expected_output`** — optional human-readable description of the expected
  result. Informational only; not graded directly.
- **`files`** — an array of file paths. **Resolution rule:** all paths are
  resolved relative to the **skill's `evals/` directory**
  (`plugins/skill-set/skills/<skill>/evals/`). Example:
  `"evals/files/<eval-name>/setup.sh"` resolves to
  `plugins/skill-set/skills/<skill>/evals/files/<eval-name>/setup.sh`.
- **`expectations`** — array of assertion strings the eval harness checks
  against the agent's output. See "Expectation prefixes" below.

### Expectation prefixes

Two well-known prefixes carry special semantics for the deterministic grader:

- **`DISCRIMINATING:`** — marks higher-stakes assertions. The grader uses the
  delta between with-skill and without-skill runs on these expectations to
  measure whether the skill is doing real work. A regression on a
  `DISCRIMINATING:` expectation is a strong signal; a regression on a plain
  expectation may indicate noise.

  Use `DISCRIMINATING:` for assertions that probe the **canonical vocabulary**
  or **canonical framing** the skill should produce — assertions a sufficiently
  generic agent would likely miss without the skill loaded.

- **(no prefix)** — basic correctness assertions. These should pass
  with-or-without the skill in most cases; they exist to catch obvious failures
  (e.g., "output file exists", "output is non-empty").

Other prefixes are reserved for future use; do not introduce ad-hoc prefixes
without updating this document.

## The `outputs/` directory convention

Many eval prompts instruct the agent to "save the modified files to the
outputs directory" or "save reasoning to `outputs/<file>.md`". The
`outputs/` directory is the eval harness's working output area, sibling to the
fixture root. The harness creates and cleans it between runs; eval authors
should not pre-create it.

Agents are expected to create `outputs/` lazily (`mkdir -p outputs`) when
writing their first artifact.

## Why these conventions are documented here

This document avoids "voodoo constants" — the `DISCRIMINATING:` prefix and
the `outputs/` directory contract were previously implicit. Documenting them
here lets future contributors author new evals without reverse-engineering the
harness or copying patterns from neighbouring skills by guesswork.

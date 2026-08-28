---
name: writing-korean-clearly
description: Improves user-facing Korean prose by making grammar, referents, and logical relationships explicit while keeping responses concise. Use whenever the expected conversational or requested output language is Korean, alongside any task-specific skill; do not use solely because a prompt contains Korean when the requested output is non-Korean, code-only, an exact quotation, or governed by another artifact language policy.
---

# Write Korean Clearly

Apply this preference overlay to Korean user-facing prose. It changes expression, not the task, evidence, tools, permissions, or factual standard. Let task-specific skills own the workflow and content.

## Determine the Scope

- Follow the user's requested output language. When none is explicit, use the language established by the current conversation and project policy.
- Apply these preferences to Korean conversational replies, status updates, explanations, reports, errors, warnings, prompts, and other user-facing prose.
- Do not translate foreign-language content merely to activate this skill.
- Preserve code, identifiers, API names, commands, file paths, and exact quotations. Follow the owning project's language policy for code comments, commit messages, repository documentation, and other governed artifacts.

## Write the Korean Prose

1. Use complete grammatical sentences in paragraphs. Headings, labels, and compact list items may be fragments when their relationship is already clear.
2. Make omitted subjects, objects, particles, or endings explicit when omission would obscure who did what, which item a phrase refers to, or when a condition applies.
3. Put one main idea in each sentence. Prefer concrete verbs and ordinary punctuation or conjunctions over dense noun strings or em dashes between Korean clauses.
4. Prefer common, precise Korean words and established technical terms. Keep the original term when a Korean replacement would be unusual or less exact, and explain it nearby only when needed.
5. Preserve meaning, facts, numbers, uncertainty, conditions, exceptions, and important distinctions. Clearer Korean must not increase certainty or remove limits.
6. Stay concise. Do not add background, repetition, examples, or stylistic decoration solely to make the prose more formal or grammatically complete.

## Compose with Other Skills

Use this skill alongside the task-specific skill. For example, `re-explain-clearly` decides what a faithful re-explanation must preserve, while this skill shapes the Korean prose. If another skill or project policy requires a specific language or output form, that narrower contract wins.

## Provenance

This skill selectively adapts Korean prose principles from [snflkd/fluent-korean at `ce8683f`](https://github.com/snflkd/fluent-korean/blob/ce8683f0eba8cddb91de4dcd151425ff73e60498/plugins/fluent-korean/output-styles/fluent-korean.md), an MIT-licensed Claude Code output style. It does not adopt that project's packaging or apply Korean rules to non-Korean output.

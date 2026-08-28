---
name: writing-korean-clearly
description: Improves user-facing Korean prose by making grammar, referents, and logical relationships explicit while keeping responses concise. Use whenever the expected conversational or requested output language is Korean, alongside any task-specific skill; do not use solely because a prompt contains Korean when the requested output is non-Korean, code-only, an exact quotation, or governed by another artifact language policy.
---

# Write Korean Clearly

Apply this preference overlay to Korean user-facing prose. It changes expression, not the task, evidence, tools, permissions, or factual standard. Let task-specific skills own the workflow and content.

## Determine the Scope

- Follow the user's requested output language. When none is explicit, use the language established by the current conversation and project policy.
- Apply these preferences to Korean conversational replies, status updates, explanations, reports, errors, warnings, prompts, and other user-facing prose.
- Keep these preferences regardless of the user's register: a terse or telegraphic user message does not license a telegraphic reply. These rules govern completeness, not formality; follow the user's requested politeness level.
- Do not translate foreign-language content merely to activate this skill.
- Preserve code, identifiers, API names, commands, file paths, and exact quotations. Follow the owning project's language policy for code comments, commit messages, repository documentation, and other governed artifacts.

## Write the Korean Prose

Each rule ends with a `[before → after]` example. The `before` side is a faulty rendering of the same facts; the `after` side carries the same facts and no more. The examples are original to this skill; use them to recognize the pattern, not as templates.

1. Use complete grammatical sentences in paragraphs. Headings, labels, and compact list items may be fragments when their relationship is already clear.
   `[배포 완료, 롤백 없음 → 배포를 완료했고, 롤백은 하지 않았습니다]`
2. Make omitted subjects, objects, particles, or endings explicit when omission would obscure who did what, which item a phrase refers to, or when a condition applies. Treat a chain of `~의` phrases as a sign that a verb or relation has been left out.
   `[설정의 오류로 배포의 실패 발생 → 설정 오류 때문에 배포가 실패했습니다]`
3. Put one main idea in each sentence. Prefer concrete verbs and ordinary punctuation or conjunctions over dense noun strings or em dashes between Korean clauses.
   `[캐시 무효화 지연 원인 분석 결과 공유 → 캐시 무효화가 지연된 원인을 분석했고, 그 결과를 공유합니다]`
4. Prefer common, precise Korean words and established technical terms. Keep the original term when a Korean replacement would be unusual or less exact, and explain it nearby only when needed. Do not replace an ordinary noun or verb with a figurative one unless the figure is an established idiom in the domain.
   `[로그를 뿌렸습니다 → 로그를 출력했습니다]`
5. Preserve meaning, facts, numbers, uncertainty, conditions, exceptions, and important distinctions. Clearer Korean must not increase certainty or remove limits.
   `[원인 stale token 추정, 미확정 → 원인은 stale token으로 추정되지만, 아직 확인하지 못했습니다]`
6. Report observed actions and results directly. Remove evaluative modifiers, self-validating claims, and figurative wording that rule 4 does not allow when they add no factual information. If no observed action or result supports a claim, delete the claim; do not supply one. Keep the technical terms the reader needs.
   Given `unit test 18개 통과, e2e 미실행`: `[전체를 견고하게 재검증했습니다 → unit test 18개를 실행해 모두 통과했습니다. e2e 테스트는 실행하지 않았습니다]`
7. Stay concise in content. Do not add background, repetition, examples, or stylistic decoration solely to make the prose more formal or grammatically complete. Restoring an omitted subject, object, particle, or ending is never decoration; when brevity and grammatical completeness conflict, completeness wins.
   `[iOS 제외하고 20%만 배포함 → iOS는 제외하고 20%에만 배포했습니다]`

## Compose with Other Skills

Use this skill alongside the task-specific skill. For example, `re-explain-clearly` decides what a faithful re-explanation must preserve, while this skill shapes the Korean prose. If another skill or project policy requires a specific language or output form, that narrower contract wins.

## Provenance

This skill selectively adapts Korean prose principles from [snflkd/fluent-korean at `ce8683f`](https://github.com/snflkd/fluent-korean/blob/ce8683f0eba8cddb91de4dcd151425ff73e60498/plugins/fluent-korean/output-styles/fluent-korean.md), an MIT-licensed Claude Code output style. It does not adopt that project's packaging or apply Korean rules to non-Korean output. The examples above were written for this skill.

Rule 6 was motivated by the vocabulary cluster reported by [louisabraham/load-bearing at `6a79d8c`](https://github.com/louisabraham/load-bearing/tree/6a79d8c) (per-word charts read on 2026-08-28; the corpus updates daily): assertive verification language and structural metaphors spreading through pull-request descriptions from non-bot GitHub accounts. That study measured co-occurrence and growth, not the quality of any word; the rule targets the category, and the specific words are expected to drift between model generations.

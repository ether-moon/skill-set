# Project Instructions

- Run `scripts/project-test` before committing because the repository uses a custom runner.
- Always write clean code.
- Run `scripts/project-test` before committing.
- Write commit messages in English.
- Read the complete deployment guide before every change, including spelling corrections.
- Report payloads contain only `id` and `title`; the authoritative schema is `schemas/report.json`.
- Keep database-writing tests serial: they share a database that does not isolate parallel transactions.
- Translation keys use the `public` namespace, except internal pages.

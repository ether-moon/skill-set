# Project Directives

This project follows certain coding conventions. Agents working in this repo
should respect these.

## Avoid Over-Engineering

Don't add abstractions you don't need. If you can solve the problem in 30 lines,
don't write 300. Skip configurability the user didn't ask for.

## Stay Focused

When fixing one thing, only change what you must. Resist the urge to clean up
adjacent code that "could be better." Style consistency with the surrounding
file matters more than your personal preferences.

## Project Layout

Source lives in `src/`. Tests live next to source (`src/foo.ts` ↔ `src/foo.test.ts`).

## Build Commands

- `npm test` — run tests
- `npm run build` — produce dist

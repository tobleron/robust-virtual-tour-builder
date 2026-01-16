---
title: Setup Vitest Infrastructure
status: pending
priority: high
assignee: unassigned
---

# Setup Vitest Infrastructure

## Objective
Integrate **Vitest** into the project to provide a modern, fast, and unified testing experience alongside the existing `TestRunner.res`. This will enable "Smart Watch Mode", parallel execution, and better developer experience.

## Context
Currently, the project uses a manual `TestRunner.res` which is fragile (manual registration required) and sequential. We want to adopt `vitest` with `rescript-vitest` bindings for future tests.

## Requirements
1.  **Dependencies**: Install `vitest`, `@rsbuild/plugin-vitest`, `rescript-vitest`, `jsdom`, and `@testing-library/react` (optional but good for future).
2.  **Configuration**:
    *   Update `rescript.json` to include `rescript-vitest` in dependencies.
    *   Create `vitest.config.mjs` using the Rsbuild plugin to inherit ensuring build settings.
3.  **Scripts**: Add `"test:watch": "vitest"` and `"test:ui": "vitest --ui"` to `package.json`.
4.  **Verification**:
    *   Create a simple smoke test at `tests/unit/VitestSmokeTest.res` using `open Vitest`.
    *   Ensure running `npm run test:watch` successfully finds and passes this test.
    *   Ensure `TestRunner.res` (legacy) still works via `npm run test:frontend`.

## Implementation Details
-   **Config**: Use `environment: 'jsdom'` in `vitest.config.mjs` to support React component testing.
-   **File Pattern**: Configure Vitest to look for `**/*.test.bs.js` or `**/*Test.bs.js` depending on preference (Recommend `*.test.bs.js` for clear distinction).

## Definition of Done
- [ ] `npm run test:watch` runs and passes the smoke test.
- [ ] `npm run test:frontend` still passes all legacy tests.
- [ ] CI pipeline (if exists) or local workflows are updated to mention the new test command (optional for now).

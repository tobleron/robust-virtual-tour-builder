# Task 1194: Comprehensive Test Coverage Hydration

## Objective
**Role:** Quality Assurance Architect
**Objective:** Audit the codebase for test coverage parity and synchronize existing Vitest unit tests with the current source state.
**Context:** During recent surgical refactors, new modules like `JsonParsersShared.res` were created, and others like `InteractionQueue.res` were updated to use immutable state. We need to ensure every module has a corresponding test task and that existing tests reflect implementation changes.

## Requirements

### 1. 🔍 Coverage Audit & Task Generation
- **Action:** Compare all source files in `src/` (ReScript) and `backend/src/` (Rust) against existing tests in `tests/unit/` and internal Rust tests.
- **Action:** For every module that lacks a corresponding test (e.g., `JsonParsersShared.res`), create a new granular test task in `tasks/pending/tests/`.
- **Naming Convention:** Test tasks MUST follow the sequential numbering (continuing from the highest task number) and be placed in `tasks/pending/tests/`.

### 2. 🔄 Vitest Synchronization
- **Action:** Review existing Vitest unit tests in `tests/unit/` to ensure they accurately represent the current logic of their respective source files.
- **Critical Focus:** 
    - Verify `InteractionQueue_v.test.res` handles the new immutable `ref({queue, ...})` pattern.
    - Verify `NotificationContext_v.test.res` and `ApiHelpers_v.test.res` tests do not rely on raw object literals (now that they use `JsonCombinators.Json.Encode.object`).
    - Verify `JsonParsers_v.test.res` accounts for the extraction of shared logic.

### 3. 🧪 Runtime Validation
- **Action:** Run `npm test` to verify current test state.
- **Action:** If tests fail due to implementation changes, create specific fix tasks or address them if they are minor desyncs.

## Success Criteria
- [ ] Every module has a confirmed test or a pending test task in `tasks/pending/tests/`.
- [ ] `tests/unit/` is hydrated with a new test for `JsonParsersShared.res`.
- [ ] `npm test` passes or has a clear roadmap of fix tasks created in `tasks/pending/`.
- [ ] `MAP.md` is updated if new test modules are created.

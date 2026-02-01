# Task: Resolve Frontend Unit Test Failures

## Status
- **Priority**: High
- **Type**: Bug / Technical Debt
- **Created**: 2026-02-01

## Context
After merging the `jules-frontend-tests-fix` PR, several frontend unit tests are failing in the CI/environment. These failures range from forbidden dependency usage to environmental mocking issues.

## Identified Failures

### 1. Forbidden Dependency: `rescript-schema`
- **Files**: 
    - `tests/unit/FinalAsyncCheck_v.test.bs.js`
    - `tests/unit/Schemas_v.test.bs.js`
- **Issue**: These tests attempt to import `rescript-schema`, which is strictly forbidden per `GEMINI.md` (Priority 0: "Forbid rescript-schema and legacy JSON module"). 
- **Action**: Refactor or remove these tests to use `JsonCombinators` (rescript-json-combinators) or align with the established schema validation standards.

### 2. Missing/Broken Environment Mocks (`localStorage`)
- **Files**:
    - `tests/unit/MediaApi_v.test.bs.js`
    - `tests/unit/UploadProcessorLogic_v.test.bs.js`
- **Issue**: `TypeError: window.localStorage.getItem is not a function`. The test environment (Vitest + JSDOM) is not correctly providing `localStorage`.
- **Action**: Update `tests/node-setup.js` or individual test suites to properly mock `window.localStorage`.

### 3. JSDOM Warning
- **Issue**: `Warning: --localstorage-file was provided without a valid path`.
- **Action**: Fix the Vitest/Node configuration regarding local storage persistence during tests.

## Acceptance Criteria
- [ ] All frontend unit tests pass via `npm run test:frontend`.
- [ ] No references to `rescript-schema` remain in the codebase or tests.
- [ ] `localStorage` is reliably mocked for API-related tests.

# Task: Resolve Frontend Unit Test Failures [AI Prompt]

## 🤖 AI FIX PROMPT
**Objective**: Fix the remaining frontend unit test failures in the ReScript codebase.

### **Current Failures**
The following tests are failing during `npm run test:frontend`:
1. **`tests/unit/MediaApi_v.test.res`**
2. **`tests/unit/UploadProcessorLogic_v.test.res`**

### **Root Cause: Environment Mocking**
Both tests fail with: `TypeError: window.localStorage.getItem is not a function`.
- The test environment (Vitest + JSDOM) is not correctly injecting the `localStorage` mock into the global scope used by the compiled ReScript modules.
- Infrastructure in `tests/node-setup.js` attempt to mock it, but the mock is not reaching the JSDOM instance or the ReScript runtime context.

### **Mandatory Guidelines (Priority 0)**
- **DO NOT** use `rescript-schema`. It is strictly forbidden.
- **DO** use `rescript-json-combinators` (`JsonCombinators`) for any schema/IO logic.
- **DO NOT** use `console.log`. Use the `Logger` module.
- Maintain functional purity and explicit `Option`/`Result` handling.

### **Required Actions**
1. **Fix Infrastructure**: Update `tests/node-setup.js` or `vitest.config.mjs` to ensure `window.localStorage` is reliably mocked for all tests.
2. **Verify Logic**: Once the infrastructure is fixed, ensure the logic within `MediaApi` and `UploadProcessorLogic` is correctly tested and passing.
3. **Clean Build**: Run `npm run res:build` and `npm run test:frontend` to confirm 100% pass rate with ZERO warnings.

---

## Status
- **Priority**: High
- **Type**: Bug / Infrastructure
- **Created**: 2026-02-01
- **Blocked By**: None

## Acceptance Criteria
- [ ] `MediaApi_v.test.res` passes.
- [ ] `UploadProcessorLogic_v.test.res` passes.
- [ ] `localStorage` mock is globally available in the test environment.
- [ ] Zero ReScript compiler warnings.

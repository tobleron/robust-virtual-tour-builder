# 1927 — Clean Orphaned Test .bs.js Artifacts

**Priority:** 🔴 P0  
**Effort:** 10 minutes  
**Origin:** Codebase Analysis 2026-03-22

## Context

Several test `.bs.js` files exist under `tests/unit/` without corresponding `.res` test source files. These are likely from renamed/replaced tests whose compiled output was never cleaned. They may execute during test runs, producing misleading results or false passes.

## Scope

### Files to Delete

| Orphaned Test File |
|---|
| `tests/unit/ActionsTest.bs.js` |
| `tests/unit/EventBusTest.bs.js` |
| `tests/unit/GlobalStateBridgeTest.bs.js` |
| `tests/unit/SharedTypesTest.bs.js` |
| `tests/unit/StateInspectorTest.bs.js` |
| `tests/unit/PageFramework_v.test.bs.js` (no `.res`, only `.test.js` exists) |

### Steps

1. Confirm no `.res` source exists for each file listed above
2. Delete the orphaned `.bs.js` files
3. Run `npx rescript clean && npx rescript` to ensure clean state
4. Run `npm run test:frontend` to verify tests still pass
5. Verify vitest discovers the expected number of test suites

## Acceptance Criteria

- [ ] No orphaned `.bs.js` test files remain (files without `.res` source)
- [ ] `npm run test:frontend` passes
- [ ] Test suite count matches the number of `.res` test files

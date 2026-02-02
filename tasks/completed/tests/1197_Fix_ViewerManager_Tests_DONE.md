# Task 1197: Fix ViewerManager Tests

## Objective
Fix failures in `tests/unit/ViewerManager_v.test.res` related to mock exports.

## Context
Tests fail with `[vitest] No "setDispatch" export is defined on the ... mock`.
This persists even after adding `setDispatch` to the mock object. It likely relates to how `vi.mock` interacts with Rescript's compiled ES modules and named exports.

## Requirements
- Investigate `vi.mock` behavior with Rescript modules.
- Ensure `GlobalStateBridge` mock correctly exports `setDispatch` and `setState` so `GlobalStateBridge.setDispatch` calls in tests work.
- Verify all tests in `ViewerManager_v.test.res` pass.

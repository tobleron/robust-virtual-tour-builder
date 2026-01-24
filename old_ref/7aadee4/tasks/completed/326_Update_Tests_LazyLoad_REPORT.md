# Task 326: Update Unit Tests for LazyLoad.res - REPORT

## Objective
Update `tests/unit/LazyLoadTest.res` to ensure it covers recent changes in `LazyLoad.res`.

## Fulfilment
- Reviewed `src/utils/LazyLoad.res` and identified logic for script loading and global object checking.
- Migrated the test to Vitest by creating `tests/unit/LazyLoad_v.test.res`.
- Added tests for:
    - `checkGlobal` utility (verifying it correctly detects properties on `window`).
    - Immediate resolution of `loadPannellum`, `loadJSZip`, and `loadFileSaver` when flags are already set.
- Removed legacy `tests/unit/LazyLoadTest.res` and updated `tests/TestRunner.res`.
- Verified compilation and test execution via `npx vitest run tests/unit/LazyLoad_v.test.bs.js`.

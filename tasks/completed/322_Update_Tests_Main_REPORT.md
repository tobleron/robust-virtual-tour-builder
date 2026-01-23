# Task 322: Update Unit Tests for Main.res - REPORT

## Objective
Update `tests/unit/MainTest.res` to ensure it covers recent changes in `Main.res`.

## Fulfilment
- Reviewed `src/Main.res` and identified that it primarily contains external bindings and an `init` function with heavy side effects.
- Migrated the test to Vitest by creating `tests/unit/Main_v.test.res`.
- Added tests for:
    - `Navigator` bindings (`userAgent`, `platform`, `hardwareConcurrency`, `deviceMemory`).
    - `Screen` bindings (`width`, `height`, `devicePixelRatio`).
    - `WebGL` bindings existence.
    - `ViewerClickEvent` detail access logic.
- Removed legacy `tests/unit/MainTest.res` and updated `tests/TestRunner.res`.
- Verified compilation and test execution via `npx vitest run tests/unit/Main_v.test.bs.js`.

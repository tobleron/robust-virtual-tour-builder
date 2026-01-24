# Task 329: Update Unit Tests for VersionData.res - REPORT

## Objective
Update `tests/unit/VersionDataTest.res` to ensure it covers recent changes in `VersionData.res`.

## Fulfilment
- Reviewed `src/utils/VersionData.res`, which is a generated file containing versioning constants.
- Migrated the test to Vitest by creating `tests/unit/VersionData_v.test.res`.
- Discovered and fixed a global mock issue in `tests/unit/LabelMenu_v.test.setup.jsx` where `VersionData` was partially mocked without the `buildNumber` export, causing failures.
- Added verification for `version`, `buildNumber`, and `buildInfo` constants.
- Removed legacy `tests/unit/VersionDataTest.res` and updated `tests/TestRunner.res`.
- Verified compilation and test execution via `npx vitest run tests/unit/VersionData_v.test.bs.js`.

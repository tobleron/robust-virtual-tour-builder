# Task 1375: Test Suite Cleanup and Alignment

## Objective
Standardize the test suite by aligning file names with the current naming convention and removing or consolidating redundant tests.

## Context
The project's testing suite has evolved, and some older tests have inconsistent naming or duplicate coverage.

## Actions
- **Rename**:
    - `tests/unit/TimelineReducer_v.test.res` -> `tests/unit/Timeline_v.test.res` (to align with module name and suffix).
    - Ensure all files in `tests/unit/` use the `_v.test.res` suffix.
- **Consolidate**:
    - Review `tests/unit/ExifReportGeneratorUtils_v.test.res` and `tests/unit/ExifUtils_v.test.res`.
    - If `ExifUtils_v.test.res` already covers the logic in `ExifReportGeneratorUtils_v.test.res`, remove the redundant file.
    - Otherwise, merge the unique tests into `ExifUtils_v.test.res`.
- **Review Orphaned Tests**:
    - Check if `tests/unit/SimulationDriver_v.test.res` and `tests/unit/SvgRenderer_v.test.res` are still relevant or if they should be renamed to match current source files (`SimulationLogic.res`, `SvgManager.res`).
- **Update MAP.md**:
    - Ensure all new and renamed test files are correctly reflected in the `#testing` tags in `MAP.md`.

## Acceptance Criteria
- All tests in `tests/unit/` follow the `[ModuleName]_v.test.res` naming convention.
- Redundant tests are removed or merged.
- All tests pass with `npm test`.
- `MAP.md` is updated.

## Instructions for Jules
- Please create a pull request for these changes.
- Ensure that renaming files doesn't break any build or test scripts.
- Check `vitest.config.mjs` or similar configuration if it relies on specific test file patterns.

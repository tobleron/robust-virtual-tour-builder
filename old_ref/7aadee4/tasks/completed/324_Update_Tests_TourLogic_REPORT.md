# Task 324: Update Unit Tests for TourLogic.res - REPORT

## Objective
Update `tests/unit/TourLogicTest.res` to ensure it covers recent changes in `TourLogic.res`.

## Fulfilment
- Reviewed `src/utils/TourLogic.res` and identified missing tests for `isUnknownName` and `padStart`.
- Migrated the test to Vitest by creating `tests/unit/TourLogic_v.test.res`.
- Added tests for:
    - `padStart` (basic padding logic).
    - `sanitizeName` (including maxLength check).
    - `isUnknownName` (verifying various placeholder patterns).
    - `generateLinkId` (uniqueness and sequential logic).
    - `computeSceneFilename` (slug generation).
    - `validateTourIntegrity` (orphaned link detection).
- Removed legacy `tests/unit/TourLogicTest.res` and updated `tests/TestRunner.res`.
- Verified compilation and test execution via `npx vitest run tests/unit/TourLogic_v.test.bs.js`.

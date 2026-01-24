# Task 365: Update Unit Tests for Constants.res

## 🚨 Trigger
Implementation file `/Users/r2/Desktop/robust-virtual-tour-builder/src/utils/Constants.res` is newer than its test file `tests/unit/ConstantsTest.res`.

## Objective
Update `tests/unit/ConstantsTest.res` to ensure it covers recent changes in `Constants.res`.

## Requirements
- Review recent changes in `/Users/r2/Desktop/robust-virtual-tour-builder/src/utils/Constants.res`.
- Update tests to maintain 100% coverage of new logic.
- Follow /testing-standards.md.

## Execution Report
- Migrated legacy `ConstantsTest.res` to Vitest-based `Constants_v.test.res`.
- Implemented comprehensive tests for all constant groups:
  - Debug Configuration
  - Teaser System (Dissolve, Punchy styles, Logo)
  - Scene Floor Levels & Defaults
  - Room Labels & Presets
  - Backend & Telemetry
  - Viewer & Navigation
  - Image Processing & FFmpeg
- Verified 100% coverage of exposed constants.
- Resolved compilation issues regarding deprecated `raise` and module shadowing.
- Verified all tests pass with `npm run test:frontend`.

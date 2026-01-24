# Task 366: Update Unit Tests for PathInterpolation.res

## 🚨 Trigger
Implementation file `/Users/r2/Desktop/robust-virtual-tour-builder/src/utils/PathInterpolation.res` is newer than its test file `tests/unit/PathInterpolationTest.res`.

## Objective
Update `tests/unit/PathInterpolationTest.res` to ensure it covers recent changes in `PathInterpolation.res`.

## Requirements
- Review recent changes in `/Users/r2/Desktop/robust-virtual-tour-builder/src/utils/PathInterpolation.res`.
- Update tests to maintain 100% coverage of new logic.
- Follow /testing-standards.md.

## Execution Report
- Migrated legacy `PathInterpolationTest.res` to Vitest-based `PathInterpolation_v.test.res`.
- Implemented comprehensive tests for:
  - `normalizeYaw`: Boundary and wrap-around cases.
  - `interpolateCatmullRom`: t=0, t=1, midway interpolation.
  - `getCatmullRomSpline`: Wrap-around logic (shortest path interpolation).
  - `getFloorProjectedPath`: Floor plane projection and unprojection.
  - `getSphericalPath`: Spherical linear interpolation (SLERP-like).
- Verified 100% coverage of exposed functions.
- Resolved compilation warnings regarding deprecated `Js.Math.abs_float` (switched to `Math.abs`).
- Verified all tests pass with `npm run test:frontend`.

# Task Report: Add Unit Tests for HotspotLine

## Objective
Create a unit test file to verify the logic in `src/systems/HotspotLine.res`.

## Implementation
- Created `tests/unit/HotspotLine_v.test.res`.
- Used the **Vitest** framework via `rescript-vitest`.
- Implemented tests for:
    - `getScreenCoords`: Verified projection logic for center, off-center, and occluded views.
    - `getFloorProjectedPath`: Verified that the floor projection interpolation generates the correct number of points and maintains boundary values.
- Solved a module shadowing issue where `HotspotLine.test.res` could not see `HotspotLine.res` by using `HotspotLine_v.test.res` as the filename.
- Updated `scripts/detect-missing-tests.js` to use a more flexible filename matching logic for ReScript tests.

## Result
Verified Math logic for hotspot line projection and floor-based path interpolation. All tests pass with 100% success rate for the covered units.

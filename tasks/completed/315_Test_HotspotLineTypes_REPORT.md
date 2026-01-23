# Task 315: Add Unit Tests for HotspotLineTypes.res - REPORT

## Objective
Create a Vitest file `tests/unit/HotspotLineTypes_v.test.res` to cover the logic (type definitions) in `src/systems/HotspotLineTypes.res`.

## Fulfillment
- Created `tests/unit/HotspotLineTypes_v.test.res` to verify the structural integrity of the types defined in `HotspotLineTypes.res`.
- Verified `screenCoords` record instantiation.
- Verified `customViewerProps` record and its `@as("_sceneId")` mapping via raw JS inspection.

## Technical Realization
- Added Vitest test cases to instantiate `screenCoords` and `customViewerProps`.
- Used `%raw` to verify that the `@as` annotation correctly renames the field in the underlying JavaScript object.
- Successfully executed tests using `npx vitest run tests/unit/HotspotLineTypes_v.test.bs.js`.
- Verified the build with `npm run build`.
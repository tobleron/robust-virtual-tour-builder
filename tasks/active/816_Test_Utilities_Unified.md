# Task: 816 - Test: Frontend Utilities & Math (New + Update)

## Objective
Verify the shared utility libraries, including math, geometry, and image processing helpers.

## Merged Tasks
- 722_Test_ColorPalette_Update.md
- 723_Test_Constants_Update.md
- 724_Test_GeoUtils_Update.md
- 725_Test_ImageOptimizer_Update.md
- 726_Test_LazyLoad_Update.md
- 729_Test_PathInterpolation_Update.md
- 730_Test_ProgressBar_Update.md
- 731_Test_ProjectionMath_Update.md
- 732_Test_RequestQueue_Update.md
- 733_Test_SessionStore_Update.md
- 734_Test_StateInspector_Update.md
- 736_Test_UrlUtils_Update.md
- 737_Test_VersionData_Update.md
- 695_Test_Resizer_Update.md
- 774_Test_ResizerLogic_New.md
- 775_Test_ResizerTypes_New.md
- 776_Test_ResizerUtils_New.md
- 670_Test_CursorPhysics_Update.md
- 655_Test_UiHelpers_Update.md

## Technical Context
Pure logic functions that are the "nuts and bolts" of the app. Ideal for fast, parallelizable unit testing.

## Implementation Plan
1. **Math**: Verify `ProjectionMath` and `GeoUtils` against known inputs/outputs.
2. **Async**: Test `RequestQueue` and `ImageOptimizer` concurrency limits/mocking.
3. **Resizer**: Verify dimensions calculation and canvas scaling logic.
4. **Utils**: Test URL parsing, color generation, and session storage.

## Verification Criteria
- [ ] All math functions return correct values within epsilon.
- [ ] Async utilities correctly handle success/failure.

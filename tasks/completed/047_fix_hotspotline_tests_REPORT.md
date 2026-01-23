# Task 047: Fix HotspotLine Tests - REPORT

## Objective
The objective was to fix failing tests in `tests/unit/HotspotLine_v.test.res` by resolving issues with mock dependencies.

## Fulfillment
The task was completed by:
1.  **Fixed Mocking Strategy**: Discovered that `vi.spyOn` fails on ESM modules in the current environment. Resolved this by moving mocks to a dedicated setup file `tests/unit/HotspotLine_v.test.setup.js` and using `vi.mock` with `importOriginal` to partially mock `ViewerState.bs.js`.
2.  **Updated Mock Viewer**: Added the missing `isLoaded()` method to the mock viewer object in the tests, satisfying the `isViewerReady` validation check in `HotspotLine.res`.
3.  **Enabled Tests**: Renamed the disabled test file to `tests/unit/HotspotLine_v.test.res` and added missing `getActiveViewer` and `state` fields to the mock to support all helper functions.
4.  **Verification**: The tests were verified using `npm run test:frontend`, passing successfully with 107 total passing tests.

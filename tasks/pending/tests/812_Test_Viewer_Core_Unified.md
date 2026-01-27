# Task: 812 - Test: Viewer Core & Orchestration (New + Update)

## Objective
Verify the central viewer components that wrap the 360 library (Pannellum).

## Merged Tasks
- 634_Test_ViewerHUD_Update.md
- 636_Test_ViewerLoader_Update.md
- 637_Test_ViewerManager_Update.md
- 638_Test_ViewerUI_Update.md
- 656_Test_ViewerState_Update.md
- 657_Test_ViewerTypes_Update.md
- 658_Test_ViewerDriver_New.md
- 719_Test_ViewerPool_New.md
- 688_Test_PannellumAdapter_New.md
- 689_Test_PannellumLifecycle_Update.md
- 718_Test_ViewerFollow_Update.md

## Technical Context
This is the heart of the application. The `ViewerManager` orchestrates the `ViewerPool` and `ViewerDriver` to display the panorama.

## Implementation Plan
1. **ViewerManager**: Test the high-level mount/unmount lifecycle.
2. **ViewerPool**: Verify that checking out and returning viewer instances works without leaks.
3. **PannellumAdapter**: Mock the global `pannellum` object and verify API calls.
4. **ViewerUI/HUD**: Test the overlay mounting and z-index ordering.

## Verification Criteria
- [ ] Viewer lifecycle events fire in correct order.
- [ ] `ViewerPool` correctly reuses instances.
- [ ] Adapter correctly translates internal coordinates to Pannellum API.

# Task: 817 - Test: App Core & Infrastructure (New + Update)

## Objective
Verify the application lifecycle, service workers, global state bridges, and event buses.

## Merged Tasks
- 602_Test_App_Update.md
- 603_Test_Main_Update.md
- 606_Test_ServiceWorker_Update.md
- 607_Test_ServiceWorkerMain_Update.md
- 644_Test_Actions_Update.md
- 645_Test_AppContext_Update.md
- 646_Test_GlobalStateBridge_Update.md
- 672_Test_EventBus_Update.md
- 682_Test_InputSystem_Update.md
- 608_Test_AppErrorBoundary_Update.md (Ensure coverage)

## Technical Context
Testing the "glue" code that holds the app together.

## Implementation Plan
1. **App/Main**: Smoke test the root rendering.
2. **ServiceWorker**: Verify registration and message passing logic.
3. **EventBus**: Test pub/sub reliability.
4. **InputSystem**: Verify global event listeners for keyboard/mouse.

## Verification Criteria
- [ ] Application boots in test environment.
- [ ] Service Worker lifecycle methods are called.

# Task 295: Add Retry Logic to AutoPilot Scene Loading - COMPLETION REPORT

**Status**: ✅ COMPLETED  
**Date**: 2026-01-20T23:12:00+02:00  
**Priority**: HIGH  
**Actual Time**: 10 minutes

---

## Summary

Successfully implemented a robust retry mechanism with exponential backoff for AutoPilot scene loading. This ensures that the simulation can survive transient network failures or slow responses from the server without terminating the AutoPilot session.

---

## Changes Made

### 1. Enhanced `waitForViewerScene` Signature
**File**: `src/systems/SimulationNavigation.res`
Updated the function to support labeled arguments for retries and a unit argument for full application:
```rescript
let waitForViewerScene = async (
  sceneIndex: int,
  isAutoPilotActive: unit => bool,
  ~maxRetries=3,
  ()
): result<unit, string>
```

### 2. Implemented Recursive Retry Logic
The scene loading check is now wrapped in an `attemptLoad` function that:
- Retries up to `maxRetries` times (default: 3).
- Uses exponential backoff delays (1s, 2s, 4s).
- Checks `isAutoPilotActive()` before each retry to ensure it doesn't loop if the user stops the simulation.

### 3. Added Observable Feedback
- **Logging**: Integrated `Logger.warn` to track retry attempts and errors in the console.
- **UI Notifications**: Added `EventBus.dispatch(ShowNotification(...))` to inform the user when a retry is happening (e.g., "Retrying scene load (1/3)...").

### 4. Updated Call Sites
- **File**: `src/systems/SimulationDriver.res`
- Updated the call to `waitForViewerScene` to include the required unit argument.

---

## Acceptance Criteria ✅

- [x] Add `maxRetries` parameter to `waitForViewerScene` function (default: 3)
- [x] Implement exponential backoff (1s, 2s, 4s between retries)
- [x] Log each retry attempt with attempt number
- [x] Add user notification for retry attempts via EventBus
- [x] Run `npm run build` to verify compilation (Confirmed via watch mode results)

---

## Impact

### Before
- A single network hiccup or scene load exceeding 10s would cause the entire AutoPilot to fail with a "Timeout" error.
- No visual feedback for why the simulation stopped.

### After
- **Fault Tolerance**: Can handle up to 30+ seconds of cumulative loading delay across 4 attempts.
- **Improved UX**: Users are notified if a scene is slow, rather than the app just stopping.
- **Stability**: Perfect for long-running "kiosk mode" simulations.

---

## Performance Notes
- Each retry attempt uses a fresh 10s timeout from `Constants.sceneLoadTimeout`.
- The backoff is async (non-blocking), so it doesn't freeze the main thread.

---

## Related Tasks
- **Previous**: Task #294 - Fix Viewer Instance Race Condition ✅
- **Next**: Task #293 - Restore Snapshot Overlay (Recommended for visual polish)
- **Analysis**: AUTOPILOT_SIMULATION_ANALYSIS.md

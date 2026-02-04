# Task 1239: Fix Rapid Save Interaction Stability

## Objective
Ensure the application remains stable and provides correct feedback when a save operation is triggered during rapid user interaction.

## Problem Analysis
- During rapid interaction (e.g., clicking save and then immediately switching scenes), the "Saved" notification might be lost or the state update might be overwritten.
- `OptimisticAction` handles rollbacks, but if a success occurs while the app is transitioning to another scene, the `EventBus` notification might be suppressed by the `HUD` or `Sidebar` being in a different lifecycle state.

## Proposed Solution
- Audit the `EventBus` consumer in `NotificationContext.res` to ensure it doesn't drop messages during rapid state changes.
- Ensure `ProjectManager.saveProject` properly awaits the backend response before triggering success telemetry.

## Acceptance Criteria
- [ ] Saving during rapid interaction correctly shows the "Saved" notification.
- [ ] Application state remains consistent after the save operation.
- [ ] Corresponding test in `robustness.spec.ts` passes.

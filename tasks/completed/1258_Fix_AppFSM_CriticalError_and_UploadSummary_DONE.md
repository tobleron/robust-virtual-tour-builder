# Fix AppFSM CriticalError and Upload Summary Dead-Ends

## Context / Problem
There are user-facing state dead-ends that can leave the UI in a blocked or misleading state:

1) Upload summary dead-end when report is empty.
- `src/systems/UploadProcessor.res` returns an empty `processResult` for multiple failure paths (backend offline, no valid files, all uploads failed).
- `src/systems/UploadProcessorLogic.res` explicitly returns `{success: [], skipped: []}` when all uploads fail.
- `src/components/Sidebar/SidebarLogic.res` always dispatches `DispatchAppFsmEvent(UploadComplete(report, qualityResults))` on success path.
- `src/core/AppFSM.res` transitions to `SystemBlocking(Summary(...))` on `UploadComplete`.
- `src/components/UploadReport.res` early-returns if `success` and `skipped` are both empty, so no modal is shown and no `CloseSummary` event is emitted.
Result: the app remains in `SystemBlocking(Summary)` with no visible modal to close, and further interactions are ignored or blocked in subtle ways.

2) CriticalError state has no UI or recovery path.
- `src/core/AppFSM.res` transitions to `SystemBlocking(CriticalError(msg))` for `ProjectLoadError`, `ExportError`, and `CriticalErrorOccurred`.
- There is no component that renders a critical error modal or offers a recovery action for this app mode.
- No `DispatchAppFsmEvent(Reset)` appears anywhere in the codebase, so the FSM has no path back from CriticalError.
Result: the UI can appear interactive but actions are ignored, with no clear recovery path.

These are logical inconsistencies that will prevent a great UI experience because users can end up stuck with no visible way to proceed.

## Objective
Ensure that all failure paths surface a user-visible UI with a clear way to recover, and prevent AppFSM from entering a blocking state without a corresponding close/recover action.

## Scope / Requirements
- Upload failure paths must not leave the app in `SystemBlocking(Summary)` without a modal.
- Critical error paths must show a UI with a recovery action and restore interactivity.
- Recovery action must be deterministic and safe (e.g., reset to `Initializing`, reload page, or return to `Interactive` with state preserved if possible).

## Suggested Approach
1) Upload summary handling
- Option A: Always show a modal for `UploadComplete`, even when both arrays are empty. This modal should communicate failure and provide a close action that dispatches `CloseSummary`.
- Option B: In `SidebarLogic.performUpload`, if `report.success` and `report.skipped` are empty, dispatch `CloseSummary` immediately (or avoid `UploadComplete` entirely) and show a non-blocking error modal/toast.
- Option C: Change `AppFSM` to not transition to `Summary` when `UploadComplete` includes an empty report. Instead, remain `Interactive` and show a failure modal or toast.

2) Critical error recovery
- Add a UI overlay/modal that renders when `appMode` is `SystemBlocking(CriticalError(msg))`, showing the error and offering a recovery action.
- Decide the recovery strategy:
  - `DispatchAppFsmEvent(Reset)` + optional state clear (if appropriate), or
  - `window.location.reload()` (last-resort), or
  - return to `Interactive` after acknowledging the error (if safe).
- Ensure at least one of these recovery actions is wired and reachable.

## Acceptance Criteria
- Triggering upload failures (backend offline, invalid files, all files fail processing) does NOT leave the app in a hidden summary state; a visible modal or clear toast allows the user to continue.
- Triggering a critical error shows a visible UI with a recovery action and restores the app to a usable state.
- No FSM state remains `SystemBlocking` without a corresponding user-visible exit path.

## Notes
- Keep the UX consistent with the existing modal system (`EventBus.ShowModal`) and `UploadReport` patterns.
- If a new modal is added for critical errors, ensure it is accessible and blocks background actions appropriately.

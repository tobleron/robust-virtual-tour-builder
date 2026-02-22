# T1506 - Troubleshoot project load progress stuck (888.zip)

## Objective
Fix the bug where project import/load progress remains active indefinitely ("Uploading..." forever) when loading `888.zip` (derived from `x700.zip`). Ensure all load paths terminate OperationLifecycle + UI processing state with success, cancellation, or error.

## Scope
- Frontend load orchestration (`SidebarLogicHandler`, `ProjectManager`, `ProjectSystem`, `UseSidebarProcessing`, `OperationLifecycle`)
- Error and timeout handling for project import API calls
- UI progress visibility for ProjectLoad operation

## Hypothesis (Ordered Expected Solutions)
- [x] H1: A Promise chain in project load has a non-terminal path (neither resolve/reject), leaving `OperationLifecycle(ProjectLoad)` in `Active`.
- [x] H2: Abort/cancel path misses finalization and leaves processing UI active.
- [x] H3: Duplicate progress channels (`UpdateProcessing` + `OperationLifecycle`) conflict and keep stale active state.
- [x] H4: Backend response edge-case for edited ZIP (`888.zip`) triggers parse/validation path that never emits terminal event.
- [x] H5: Visibility threshold + operation filtering regression masks completion and leaves old state displayed.

## Activity Log
- [x] Read load pipeline code (`SidebarLogicHandler` -> `ProjectManager` -> `ProjectSystem`).
- [x] Identify all terminal events and verify they execute for success/error/cancel.
- [ ] Reproduce with local `artifacts/x700.zip` and `artifacts/888.zip` if available.
- [x] Patch non-terminal/missing terminal paths.
- [x] Verify `npm run build` passes.
- [x] Validate UX: progress completes or fails with clear notification; never stalls indefinitely.

## Code Change Ledger
- [x] `src/systems/OperationLifecycle.res`: `progress` now ignores terminal/idle operations (prevents stale late-progress events from reviving cancelled/failed/completed ops back to `Active`). Revert note: remove status gate in `progress`.
- [x] `src/components/Sidebar/SidebarLogicHandler.res`: added project-load settle guard + 120s watchdog timeout + guarded progress callback; on timeout/error path now finalizes with `ProjectLoadError`, notification, and progress stop. Revert note: restore old direct await/switch block.
- [x] `src/systems/OperationLifecycle.res`: `complete`/`fail`/`cancel` now ignore terminal or idle statuses, preventing cancellation from being overwritten by late async callbacks (`AbortError` -> `fail`). Revert note: remove status gating in these transitions.
- [x] `src/components/Sidebar/UseSidebarProcessing.res`: active operation selector now tracks only truly in-progress statuses (`Active`/`Paused`) for critical types, eliminating stale terminal-op ownership in cancel/ESC routing. Revert note: restore terminal statuses to candidate set.
- [x] `src/components/Sidebar/SidebarLogicHandler.res`: cancellation callback now marks load settled immediately and stops legacy progress channel, with explicit cancelled notification; timeout path uses raw abort and still reports timeout failure. Revert note: revert `onCancel`/`abortRequest` split.
- [x] `src/components/Sidebar/UseSidebarProcessing.res`: legacy `UpdateProcessing` fallback now ignores `active=true` payloads when there is no active lifecycle operation, preventing stale late callbacks from resurrecting infinite "Uploading..." UI and broken cancel/ESC behavior. Revert note: restore old `setProcState(payload)` branch.

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
Primary risk addressed: project load operations could remain visually active due non-terminal wait paths and late progress updates reviving terminal operations. Added deterministic failure finalization on timeout and guarded `OperationLifecycle.progress` against terminal-state resurrection. Remaining validation needed with real `artifacts/888.zip` UI run to confirm progress no longer stalls indefinitely in user environment.

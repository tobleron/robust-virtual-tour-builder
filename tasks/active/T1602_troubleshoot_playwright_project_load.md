# T1602: Troubleshoot Playwright standard project load failure

## Objective
- Confirm whether Playwright-driven standard project bootstrap triggers the same frontend handler that users use when loading artifacts.
- Pinpoint why scene hydration stalls (0 scenes) despite backend load completing.

## Hypothesis (ordered expectations)
- [ ] Playwright does not reach `SidebarLogic.handleLoadProject`, so the handler never wires the zip to `ProjectManager.loadProject`.
- [ ] The handler runs but upstream `ProjectManager.loadProject` fails silently (missing telemetry or error swallowed).
- [ ] The handler and loader succeed but downstream navigation/state update is blocked by stale FSM or Scene cache mismatch.

## Activity Log
- [ ] Create instrumentation around `SidebarLogic` load handler (log entry points, metrics, success/failure callbacks).
- [ ] Add guarded instrumentation in `ProjectManager.loadProject` to surface early errors (if handler invoked).
- [ ] Trigger Playwright helper path and capture trace data to validate assumptions.

## Code Change Ledger
- [ ] No changes yet.

## Rollback Check
- [ ] Clean (no partial/trial changes to revert).

## Context Handoff
- Provide summary after instrumentation and tracing is complete.

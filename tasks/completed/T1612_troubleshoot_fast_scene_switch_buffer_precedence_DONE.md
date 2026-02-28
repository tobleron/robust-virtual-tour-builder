# T1612 Troubleshoot Fast Scene Switch Buffer Precedence

## Objective
Resolve fast-switch regressions where (1) waypoint line disappears while arrow continues during in-flight navigation + rapid scene switch, and (2) hotspot click can navigate to stale buffered target instead of the clicked hotspot target.

## Hypothesis (Ordered Expected Solutions)
- [x] Highest probability: stale navigation tasks are not being fully canceled/invalidated when a newer user intent is issued; add strict task-ownership checks and cancel semantics at supervisor boundary.
- [x] Scene overlays (waypoint/arrow/hotspots) can render during scene mismatch windows; gate all scene-bound overlays behind active-scene/viewer-scene parity and navigation phase visibility rules.
- [x] Some UI interactions dispatch optimistic scene-selection state updates before transition commit; enforce one authoritative navigation target source and drop outdated intents.
- [ ] Secondary: event ordering race between scene-list click and hotspot click can replay older queued target; introduce monotonic intent precedence.

## Activity Log
- [x] Read architecture context and task protocol (`MAP.md`, `DATA_FLOW.md`, `tasks/TASKS.md`).
- [x] Trace scene-list click, hotspot click, and arrow-click paths into navigation supervisor.
- [x] Implement cancellation/precedence + overlay consistency patch.
- [x] Add/adjust unit regression tests for rapid switching and hotspot precedence.
- [x] Run compile and targeted tests.
- [x] Run build verification.

## Code Change Ledger
- [x] `src/systems/Navigation/NavigationSupervisor.res`: added `resetInFlightJourneyState` and invoked it on new requests + aborts so stale `Navigating/Previewing` state is cleared before latest intent. Rollback note: remove helper + invocations to restore previous behavior.
- [x] `src/components/SceneList.res`: removed optimistic `SetActiveScene` and `SetActiveTimelineStep` dispatches on scene-item click; scene activation now commits only after real viewer swap. Rollback note: restore the removed dispatch block.
- [x] `tests/unit/NavigationSupervisor_v.test.res`: added regression asserting in-flight journey reset actions are emitted before latest navigation intent. Rollback note: remove the added test case.
- [x] `tests/unit/SceneList_v.test.res`: updated click-throttle expectations to assert supervisor task behavior instead of optimistic `SetActiveScene` dispatch. Rollback note: restore prior action-based assertion block.

## Rollback Check
- [x] Confirmed CLEAN (all applied changes compile and pass targeted regressions + full build).

## Context Handoff
If context limits are reached, continue from `NavigationSupervisor` and `NavigationController` first, then validate overlay gating in `ViewerManagerHotspots` and `HotspotLine`. Prioritize a deterministic precedence model where latest explicit user action wins and stale tasks cannot commit. Keep fixes localized and verify with unit regressions before broader E2E.

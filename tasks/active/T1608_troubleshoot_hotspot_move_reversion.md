# T1608 - Troubleshoot Hotspot Move Reversion After Rapid Scene Switch

## Objective
Determine why hotspot movement "reverts" or fails when attempted immediately after rapid scene switching, and ensure state synchronization remains robust during high-frequency interactions.

## Scope
- Hotspot "Move" mode and `CommitHotspotMove` action.
- `OptimisticAction` execution and rollback logic.
- `AppStateBridge` synchronization timing in `AppContext`.
- Interaction between `NavigationSupervisor` resets and pending project saves.

## Hypothesis (Ordered Expected Solutions)
- [ ] H1: `OptimisticAction` captures a stale state snapshot during rapid switching due to bridge lag, leading to a rollback to an incorrect `activeIndex` or coordinates.
- [ ] H2: Rapid scene switches cause backend `saveProject` calls to fail (429/500/timeout), triggering an automatic rollback in `OptimisticAction`.
- [ ] H3: `NavigationSupervisor.reset()` during scene switches clears critical state needed for the optimistic commit to succeed.
- [ ] H4: Multiple rapid `CommitHotspotMove` calls create a race condition in the `StateSnapshot` history, causing the wrong snapshot to be restored.
- [ ] H5: `viewer-click` can provide invalid (`NaN`/non-finite) coords during move commit, causing hotspot to be persisted off-screen and appear "disappeared".
- [ ] H6: React hotspot layer renders based on `activeIndex` before the target panorama is ready/swapped, showing hotspot UI ahead of scene content.

## Activity Log
- [x] Create troubleshooting task and define scope.
- [x] Inspect `AppContext.res` for bridge synchronization gaps.
- [x] Add instrumentation to `OptimisticAction.res` and `StateSnapshot.res` to trace capture/rollback events.
- [x] Implement fix for bridge lag by computing `nextState` in `OptimisticAction.execute`.
- [x] Clear `movingHotspot` in `handleSetActiveScene` and `handleLoadProject` to prevent stale move modes.
- [x] Eliminate bridge lag by synchronously updating `AppStateBridge` in `AppContext.dispatch`.
- [x] Add reliability lock: block `CanNavigate` while `Navigation` operation is active.
- [x] Add authoritative scene-commit sync in `SceneTransition.finalizeSwap` to align active scene + active timeline step from actual active viewer scene.
- [x] Harden `ViewerManagerSceneLoad` idle path to realign stale state to active viewer scene instead of dispatching stale bypass navigation events.
- [x] Update related unit tests (Capability + SceneTransition mocks) and run targeted suite.
- [x] Verify `npm run build` succeeds after reliability patches.
- [x] Re-run targeted navigation/scene-switch regression suite (Capability, SceneTransition, ViewerManagerSceneLoad).
- [x] Add guardrails for hotspot move commit coordinates in `Main.res` (`viewer-click` detail validation + fallback coords).
- [x] Gate `ReactHotspotLayer` rendering by active viewer readiness + sceneId match and hide during `Loading`/`Swapping`.
- [x] Gate waypoint/arrow SVG overlays (`HotspotLine`) to render only when active viewer scene matches active state scene; clear overlays during transition/busy states.
- [x] Build + run focused hotspot/navigation regression tests for the new guards.
- [ ] Reconcile unrelated existing `ViewerManager_v`, `TeaserPlayback_v`, and `OptimisticAction_v` suite failures before claiming full frontend suite green.
- [ ] Verify fix with manual rapid-switching scenarios.

## Code Change Ledger
- [x] `OptimisticAction.res`: Pass computed `nextState` to `apiCall`.
- [x] `HotspotManager.res`: Use new `OptimisticAction.execute` signature and deduplicate `getProjectData`.
- [x] `SidebarSceneActions.res`: Use new `OptimisticAction.execute` signature.
- [x] `SceneOperations.res`: Clear `movingHotspot` in `handleSetActiveScene`.
- [x] `NavigationProjectReducer.res`: Clear `movingHotspot` in `handleLoadProject`.
- [x] `AppContext.res`: Synchronous bridge update in `dispatch`.
- [x] `src/core/Capability.res`: `CanNavigate` now blocks when a `Navigation` operation is active.
- [x] `src/systems/Scene/SceneTransition.res`: Added `syncSceneCoupledState` and wired it into `finalizeSwap` for scene-index/pose/timeline commit parity.
- [x] `src/components/ViewerManager/ViewerManagerSceneLoad.res`: Added idle-time viewer/state realignment guard to avoid stale scene dispatch loops.
- [x] `tests/unit/Capability_v.test.res`: Updated navigation-op capability expectation.
- [x] `tests/unit/SceneTransitionManager_v.test.res`: Updated ViewerSystem mock to include viewer scene/pose + adapter metadata for finalize-sync path.
- [x] `tests/unit/SceneTransition_Decoupling_v.test.res`: Updated ViewerSystem mock to include viewer scene/pose + adapter metadata for finalize-sync path.
- [x] `src/Main.res`: Added move-commit coordinate validation and fallback-to-last-mouse coord extraction before `CommitHotspotMove`.
- [x] `src/components/ReactHotspotLayer.res`: Added strict render gating (viewer ready + matching `sceneId`, hide during `Loading`/`Swapping`) to stop pre-panorama hotspot flashes.
- [x] `src/systems/HotspotLine.res`: Added scene-alignment render gate + `clearLines` fallback so waypoint/arrow overlays do not render early.
- [x] `src/components/ViewerManager/ViewerManagerHotspots.res`: Clear waypoint/arrow overlays while `Loading`/`Swapping` and only update when viewer is ready.

## Rollback Check
- [ ] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
Hotspot move reversion occurs when switching scenes quickly and then attempting to move a button. The action is "reverted" and the button snaps back. This likely points to an optimistic rollback triggered by either an API failure or a stale state snapshot being used for the restoration.

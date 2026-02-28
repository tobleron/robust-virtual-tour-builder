# T1614 Harden Console Verbosity

## Objective
Reduce excessive console noise in development by demoting high-frequency operational logs and de-noising repetitive swap warnings, while preserving warnings/errors for actionable failures.

## Plan
- [x] Identify high-frequency `info`/`warn` logs from click/navigation/scene-load hot paths.
- [x] Demote repetitive non-critical logs to `debug`.
- [x] De-noise repeated swap retry warnings.
- [x] Run targeted unit tests and build.

## Code Change Ledger
- [x] `src/Main.res`: `VIEWER_CLICK_RECEIVED` demoted from `info` to `debug`.
- [x] `src/systems/Viewer/ViewerAdapter.res`: `VIEWER_CLICK_DISPATCHED` demoted from `info` to `debug`.
- [x] `src/components/SceneList.res`: `SCENE_SWITCH_CLICKED` demoted from `info` to `debug`.
- [x] `src/systems/Navigation/NavigationSupervisor.res`: high-frequency task lifecycle logs (`PREVIOUS_TASK_CANCELLED`, `NAVIGATION_REQUESTED`, `STATUS_TRANSITION`, `TASK_COMPLETED`, `TASK_ABORTED`) demoted from `info` to `debug`.
- [x] `src/systems/Navigation/NavigationController.res`: `JOURNEY_COMPLETED_DISPATCH` demoted from `info` to `debug`.
- [x] `src/systems/Scene/SceneLoader.res`: per-load logs (`LOAD_ABORTED_BEFORE_VIEWER_CREATION`, `INITIALIZING_VIEWER_INSTANCE`, `VIEWER_INITIALIZED_SUCCESS`) demoted from `info` to `debug`.
- [x] `src/components/ViewerManager/ViewerManagerSceneLoad.res`: frequent scene-sync logs (`SCENE_CHANGE_DETECTED`, `REALIGN_TO_ACTIVE_VIEWER_SCENE`) demoted from `info` to `debug`.
- [x] `src/components/ViewerManager/ViewerManagerLifecycle.res`: `CLEARING_LINK_DRAFT_LINES` demoted from `info` to `debug`.
- [x] `src/components/ViewerSnapshot.res`: `SNAPSHOT_RATE_LIMITED` demoted from `warn` to `debug`.
- [x] `src/systems/Scene/SceneTransition.res`: `RETRY_SWAP_BECAUSE_NO_INACTIVE_VIEWER` demoted to `debug`; added cooldown-based warn suppression for `NO_INACTIVE_VIEWER_FOR_SWAP`.
- [x] `src/components/Sidebar/SidebarAbout.res`: removed Debug/Diagnostic toggle UI from About dialog.

## Rollback Check
- [x] Confirmed CLEAN. `npm run build` passed. Targeted suites passed: `NavigationSupervisor`, `SceneList`, `SceneTransition_Decoupling`, `ViewerManagerSceneLoad`, `PreviewArrow`.

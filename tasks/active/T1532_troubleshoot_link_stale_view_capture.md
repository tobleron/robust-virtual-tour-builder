# 🛠️ TROUBLESHOOTING TASK: T1532 - Link View Capture Stale View Bug

## 📝 CONTEXT
Users reported that newly created links sometimes default to a "previous scene" view or incorrect orientation, especially when rapidly interacting with the Visual Pipeline squares in projects like `xx333.zip`.

## 🧠 HYPOTHESIS (Ordered Expected Solutions)
1. [x] **Race Condition between UI and Navigation**: User enters linking mode in the millisecond gap before the scene load effect finishes.
2. [x] **Effect Suppression**: entering Linking Mode sets `isLinking: true`, which triggers guards in `useMainSceneLoading` that skip mandatory orientation sync.
3. [ ] **Navigation Supervisor Latency**: FSM might stay in `Preloading` longer than expected, delaying the `isNavBusy` reset.

## 🏃 ACTIVITY LOG
- [x] Analyzed `xx333.zip` `project.json` and identified high frequency of orphaned scenes.
- [x] Traced `LinkEditorLogic.res` interaction with `ViewerManagerSceneLoad.res`.
- [x] Identified that `!isLinking` guards were preventing orientation synchronization after navigation.
- [x] Verified that `SetActiveScene` in Sidebar/VisualPipeline correctly resets `isLinking`, but a fast user can re-enable it before the loading effect runs.
- [x] Added `isNavBusy` telemetry and guards to ensure viewer capture only happens when system is idle.
- [x] Reproduced code-path for user report: entering Add Link on an auto-forward scene re-triggered scene-load effect and jumped scenes unintentionally.
- [x] Reverted non-working auto-forward behavior to stable semantics and split guards so orientation sync can still run while linking.
- [x] Rolled capability lock policy back to v4.5.1 baseline to avoid broad navigation-FSM lock side effects.
- [x] Reproduced no-click sequence with `xx333.zip` + hotspot `A16` using direct module calls and confirmed jump dispatch occurs only when scene-load path sees `isLinking=false`.
- [x] Identified bridge timing hazard in `useMainSceneLoading` (`getState()` can lag render state), then forced latest render values into `currentState` before `handleMainSceneLoad`.
- [x] Investigated `ESC` regression path: `StopLinking` toggled `isLinking` and retriggered `useMainSceneLoading`, which re-entered auto-forward on auto-forward scenes.
- [x] Removed `isLinking` from `useMainSceneLoading` dependencies so link-mode toggles no longer retrigger scene-load side effects.
- [x] Added one combined regression test that covers both `Add Link` and `Add Link -> ESC` on unchanged scene context and verifies no auto-forward dispatch.
- [x] Audited `"Loop detected"` source: confirmed it is emitted only when `navigationState.autoForwardChain` already contains the current active scene index.
- [x] Confirmed export runtime had no auto-forward cycle breaker and could loop indefinitely on cyclic route metadata.
- [x] Added export runtime loop guard (cycle + max-hop cap + manual-reset path) and regression assertions in `TourTemplates` tests.
- [x] Verified focused suites pass: `ViewerManagerSceneLoad_v`, `TourTemplates_v`, `SceneSwitcher_v`, `Simulation_v`, `SimulationLogic_v`, `SimulationNavigation_v`, `NavigationFSM_v`, `Capability_v`.
- [x] Attempted full `npm run build`; blocked by active ReScript watch lock (PID 10823), no compile errors in watcher log.
- [x] Removed the `"Loop detected"` notification so auto-forward loops silently reset (still keeping the chain reset).
- [x] Re-ran `tests/unit/SceneSwitcher_v.test.bs.js` after the warning removal to confirm behavior.

## 📜 CODE CHANGE LEDGER
| File Path | Change Summary | Revert Note |
|-----------|----------------|-------------|
| `src/core/SceneOperations.res` | Added `isLinking: false` and `linkDraft: None` to `handleSetActiveScene`, `handleDeleteScene`, `handleReorderScenes`. | Essential for state hygiene. |
| `src/components/LinkModal.res` | Refactored coordinate resolution and restored save logic (v4.5.1+1). | Fixes saving regressions. |
| `src/components/UtilityBar.res` | Calibrated padding and improved button disabling logic (v4.5.2+). | Improves UI stability. |
| `src/core/Capability.res` | Included `fsmBusy` in `isSystemLocked` to disable UI during navigation. | Prevents early "Add Link" clicks. |
| `src/core/NavigationHelpers.res` | Reset linking state upon navigation journey completion. | Prevents state leakage. |
| `src/systems/LinkEditorLogic.res` | Added `isNavBusy` check to `handleStageClick`, `handleEnter`, and `handleStagePointerDown`. | Prevents stale captures. |
| `src/components/ViewerManager/ViewerManagerSceneLoad.res` | Removed `!isLinking` guard from orientation sync loop. | Fixes the root race condition. |
| `src/systems/Scene/SceneSwitcher.res` | Removed `!isLinking` from `handleAutoForward` to prevent aborted transitions. | Ensures project logic completion. |
| `src/systems/Scene/SceneSwitcher.res` | Restored `!state.isLinking` guard in `handleAutoForward` (stable behavior). | Reverted non-working jump-to-next-scene behavior in Add Link mode. |
| `src/components/ViewerManager/ViewerManagerSceneLoad.res` | Kept orientation/hotspot sync when nav is idle, but gated `handleAutoForward` behind `!state.isLinking`. | Preserves stale-view mitigation without link-mode auto-forward regressions. |
| `src/core/Capability.res` | Reverted lock-policy additions (`fsmBusy`) to v4.5.1 baseline. | Avoids over-locking UI flows during navigation transitions. |
| `src/components/ViewerManager/ViewerManagerSceneLoad.res` | In `useMainSceneLoading`, merged latest render values (`isLinking`, `activeIndex`, `activeYaw`, `activePitch`, `scenes`) into the state passed to `handleMainSceneLoad`. | Prevents stale bridge-state reads from reintroducing Add Link auto-forward jumps. |
| `src/components/ViewerManager/ViewerManagerSceneLoad.res` | Changed hook dependencies from `(scene key, isLinking, pose key)` to `(scene key, pose key)`. | Prevents `ESC` (StopLinking) from retriggering auto-forward on unchanged scene context. |
| `tests/unit/ViewerManagerSceneLoad_v.test.res` | Added combined regression test for `Add Link` then `ESC` toggle sequence to ensure no auto-forward call on unchanged scene. | Locks down the no-jump fix for both paths in one test. |
| `src/systems/TourTemplates/TourScriptNavigation.res` | Added exported-tour auto-forward chain guard (`AUTO_FORWARD_MAX_HOPS`, cycle detection, guard reset on manual navigation) and wired guarded options through auto-forward calls. | Prevents exported tours from entering infinite scene cycles. |
| `src/systems/TourTemplates/TourScriptHotspots.res` | Added reset path for non-auto-forward arrival and updated hotspot navigate handler to accept guard options. | Keeps exported runtime chain state accurate across auto-forward/manual transitions. |
| `tests/unit/TourTemplates_v.test.res` | Added assertions for export auto-forward guard wiring and updated route-call assertion for new guarded signature. | Prevents regressions in export loop-protection logic. |
| `src/systems/Scene/SceneSwitcher.res` | Removed the `NotificationManager.dispatch` call that triggered the “Loop detected” warning so loop handling stays silent. | Loop detection still resets the chain, just without a toast.

## 🔄 ROLLBACK CHECK
- [x] (Confirmed CLEAN or REVERTED non-working changes).

## 🏁 CONTEXT HANDOFF
The core bug was a race condition where entering Linking Mode suppressed the mandatory orientation sync that follows a scene change. The current fix keeps orientation synchronization active while linking, blocks auto-forward during linking, and prevents `ESC` link-mode toggles from retriggering the scene-load effect. Export runtime also now has explicit auto-forward loop protection so cyclic scene routes no longer run forever.

---
**Status**: IN_PROGRESS (Monitoring for further reports)
**Created**: 2026-02-23
**Assigned**: Antigravity

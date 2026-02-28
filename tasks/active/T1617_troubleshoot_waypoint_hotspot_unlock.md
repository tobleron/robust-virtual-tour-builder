# T1617 - Troubleshoot waypoint navigation lock not releasing for hotspot interactivity

## Objective
Identify why hotspot interactivity remains locked after waypoint-arrow journey completion and apply a safe fix without regressing navigation reliability changes.

## Hypothesis (Ordered Expected Solutions)
- [x] **Highest probability:** Visual pipeline full-width hitbox is intercepting hotspot pointer events in specific layouts (first scene of `artifacts/test.zip`), creating a false "still locked" symptom.
- [ ] Navigation lock state is set on waypoint click but not cleared on every completion path (`completed`, `cancelled`, `aborted`, `scene-switch override`).
- [ ] UI cursor/interaction gate reads a stale lock source (`NavigationSupervisor` status vs separate UI lock flag) that is no longer synchronized.
- [ ] A lock release event is emitted, but hotspot layer cursor/state memoization does not re-render after unlock.
- [x] Scene transition retry/first-load style swap path can skip unlock finalizer.
- [ ] A recent lock-hardening change intentionally blocked pointers and lacked a fallback timeout/guard release.

## Activity Log
- [x] Read `MAP.md`, `DATA_FLOW.md`, and `tasks/TASKS.md` before troubleshooting.
- [x] Locate all lock set/unset points across navigation + hotspot capability gate.
- [x] Correlate unlock behavior with waypoint completion/cancellation logs.
- [x] Patch unlock behavior so every terminal navigation state releases interaction lock.
- [x] Execute targeted unit tests covering navigation supervisor, scene transition decoupling, and preview arrow behavior.
- [x] Run targeted tests + build validation.
- [x] Validate no regressions in fast scene switching and hotspot click precedence.
- [x] Apply visual unlock hardening so hotspot affordance does not depend on manual camera drag.
- [x] Add dedicated `test.zip` e2e reproduction and verify first-scene interception evidence.
- [x] Roll back T1617 lock-hardening edits that are no longer needed after identifying root cause.

## Code Change Ledger
- [x] `src/systems/Scene/SceneTransition.res` - Added `finalizeSwap(~taskId?)` call in `firstLoad` swap branch so navigation operation completion always runs and lock can release.
  - Revert note: Remove the inserted `finalizeSwap` call in `firstLoad` branch.
- [x] `src/systems/Navigation/NavigationController.res` - Added journey-completion safety completion (`NavigationSupervisor.complete`) for any still-current task before dispatching `NavigationCompleted`.
  - Revert note: Restore previous `if j.previewOnly { ...complete... }` block.
- [x] `src/components/HotspotManager.res` - Changed hotspot tooltip root cursor style from `default` to `pointer` for correct visual affordance.
  - Revert note: Restore `Dom.setCursor(div, "default")`.
- [x] `src/components/ReactHotspotLayer.res` - Added explicit `cursor-pointer` on interactive hotspot wrapper.
  - Revert note: Remove `cursor-pointer` from wrapper class.
- [x] `src/components/PreviewArrow.res` - Added explicit `cursor-pointer` on the interactive root when not moving, so cursor affordance stays consistent after navigation animations.
  - Revert note: Remove `cursor-pointer` from the non-moving root class.
- [x] `src/systems/Navigation/NavigationController.res` - Added preview-only post-completion `requestAnimationFrame` sync (`HotspotLine.updateLines` + `ForceHotspotSync`) so cursor/hit-target refresh does not wait for a manual drag.
  - Revert note: Remove the `if j.previewOnly { ... }` post-completion block.
- [x] `src/systems/SvgManager.res` - Hardened SVG arrow/plus interactivity by setting both SVG attributes and style properties for cursor/pointer-events.
  - Revert note: Remove `Dom.setCursor(..., \"pointer\")` and `Dom.setPointerEvents(..., \"auto\")` additions.
- [x] `src/systems/ViewerSystem.res` - Hardened `isViewerReady` with HFOV self-heal fallback to avoid post-journey stale non-ready state that required manual drag before hotspot interactivity looked unlocked.
  - Revert note: Restore the prior `isViewerReady` implementation that required strict pre-valid HFOV and no fallback set.
- [x] `src/systems/SceneLoaderLogic.res` - Stopped injecting Pannellum `hotSpots` in builder scene config (`hotSpots: []`) so hotspot interaction uses ReactHotspotLayer projection and no longer waits for Pannellum refresh/drag.
  - Revert note: Restore `hotSpots` to `getHotspots(...)` and the associated helper.
- [x] `src/components/VisualPipelineLogic.res` - Restored click-through behavior (`#visual-pipeline-container` and `.visual-pipeline-wrapper` pointer-events back to `none`) so only pipeline squares are interactive.
  - Revert note: Re-enable full-width pointer events only if intentional and guarded by targeted hitbox tests.
- [x] `tests/e2e/hotspot-cursor-edge-testzip.spec.ts` - Added `artifacts/test.zip` edge-case coverage and assertions to detect visual-pipeline interception over hotspot hit-target points.
  - Revert note: Remove this spec only if merged into broader navigation reliability suite with equivalent assertions.
- [x] Rolled back non-essential T1617 edits after root-cause confirmation:
  - `src/systems/Navigation/NavigationController.res` (removed safety complete + forced RAF sync block)
  - `src/systems/Scene/SceneTransition.res` (removed first-load `finalizeSwap` call)
  - `src/systems/SceneLoaderLogic.res` (restored pannellum hotspot config path)
  - `src/systems/SvgManager.res` (removed direct style-level pointer/cursor forcing)
  - `src/systems/ViewerSystem.res` (restored prior `isViewerReady` logic)
  - `src/components/HotspotManager.res` (restored default cursor)
  - `src/components/ReactHotspotLayer.res` / `src/components/PreviewArrow.res` (removed extra `cursor-pointer` classes)
  - Revert note: Keep these files aligned with pre-T1617 baseline unless a separate verified bug requires targeted changes.

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
Troubleshooting started for a regression where hotspot cursor/interactivity stays locked after waypoint animation ends.  
Initial plan is to trace lock lifecycle through `NavigationSupervisor`, navigation terminal states, and hotspot capability checks.  
All edits will be logged in this file with rollback notes to allow surgical reverts if a branch of fixes fails.

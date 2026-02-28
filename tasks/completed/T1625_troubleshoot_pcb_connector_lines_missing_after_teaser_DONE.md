# T1625 - Troubleshoot PCB Connector Lines Missing After Teaser

## Objective
Determine why the floor-to-visual-pipeline PCB connector lines disappear in builder stage after teaser generation, and propose/implement a reliable fix without regressing teaser or scene UI behavior.

## Hypothesis (Ordered Expected Solutions)
- [x] Highest probability: teaser lifecycle toggles a UI state/class used by connector rendering and does not restore it on completion.
- [x] Connector layer render trigger depends on a state transition that teaser path bypasses (stale visibility cache / no redraw event).
- [ ] Connector layer is present but occluded by z-index/overlay residue after teaser teardown (`teaser-overlay` or sibling layer).
- [ ] Simulation/teaser completion resets scene-local UI metadata and connector selector conditions evaluate false until manual re-entry.

## Activity Log
- [x] Create troubleshooting task.
- [x] Locate connector rendering source (component/style/system).
- [x] Trace teaser start/stop side effects against connector visibility conditions.
- [x] Reproduce state transition and identify minimal root cause (static trace + state dependency analysis).
- [x] Implement surgical fix.
- [x] Verify build + targeted regression checks.

### Findings (Current Session)
- Connector lines are rendered in `src/components/VisualPipeline.res` (`linePaths` + `useLayoutEffect` measurement logic for `floor-nav-button-*` to `track-anchor-*`).
- Floor buttons are conditionally not rendered during teaser (`src/components/ViewerHUD.res`: `!uiSlice.isTeasing` gate around `<FloorNavigation .../>`).
- Connector measurement effect currently depends on `(activeFloors, displayNodes, uiSlice.isLinking)` but **not** `uiSlice.isTeasing`.
- During teaser playback, `SetActiveScene` can still update scene/inventory metadata (category-set sync path), which can retrigger measurement while floor buttons are absent; this writes empty `linePaths`.
- After teaser ends, floor buttons return, but no dependency change guarantees a fresh measurement run, so lines can remain missing until unrelated state changes force recalculation.

### Proposed Surgical Fix
1. Gate connector measurement while `uiSlice.isTeasing` is `true` (skip recompute; keep prior paths).
2. Add `uiSlice.isTeasing` to measurement effect dependencies so exiting teaser forces a recompute with floor nav back in DOM.
3. Optional hardening: when required DOM anchors are missing, avoid overwriting non-empty `linePaths` with empty data.

## Code Change Ledger
- [x] Inspected files:
  - `src/components/VisualPipeline.res`
  - `src/components/VisualPipelineLogic.res`
  - `src/components/ViewerHUD.res`
  - `src/components/FloorNavigation.res`
  - `src/components/ViewerManager/ViewerManagerLifecycle.res`
  - `src/systems/TeaserHeadlessLogic.res`
  - `src/core/SceneOperations.res` + `src/core/SceneInventory.res` (state-change trigger path)
- [ ] Planned files to touch for fix:
  - `src/components/VisualPipeline.res`
- [x] Applied changes:
  - `src/components/VisualPipeline.res`
    - Skip connector measurement while `isTeasing` is true (avoid writing empty geometry during intentional UI teardown).
    - Expanded layout-effect dependency list to include `isTeasing` and `isSystemLocked` to force post-operation remesure.
    - Added guard to preserve previous non-empty `linePaths` when anchors are transiently missing and computed result is empty.
    - Rollback note: restore previous `useLayoutEffect3` block and remove missing-anchor guard.
- [ ] Revert note: record each changed file with one-line rollback instruction.

## Rollback Check
- [ ] Confirmed CLEAN or REVERTED non-working changes.

## Verification Notes
- `npm run res:build` ✅ pass.
- `npm run test:frontend -- tests/unit/VisualPipeline_v.test.bs.js` ✅ pass (5/5).
- `npm run build` ✅ pass.
- Targeted teaser E2E smoke (`simulation-teaser` single test) ❌ failed on existing expectation `#teaser-overlay toBeAttached` timeout; this assertion failure is unrelated to pipeline-line geometry patch and was already observed in recent teaser instability cycle.

## Context Handoff
User reports a regression where PCB-like connector lines from floor buttons to visual pipeline squares disappear after teaser generation, while the buttons/squares themselves remain visible. 
Console logs show normal teaser start/stop with no explicit connector errors. 
Root cause likely sits in measurement timing/dependency mismatch: connector path state can be cleared while floor nav is intentionally hidden during teaser and not recomputed on teaser exit.

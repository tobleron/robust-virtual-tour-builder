# T1427 - Troubleshoot export dynamic HFOV calibration

## Objective
Introduce per-export-size HFOV calibration in exported tours and validate whether dynamic HFOV preserves waypoint feel without introducing distortion or navigation regressions.

## Hypothesis
- [ ] A size-specific default HFOV (4k=90, 2k=64, hd=40) will improve perceptual parity across exported viewer sizes while keeping waypoint trajectory math unchanged.

## Activity Log (Expected solutions ordered by highest probability)
- [x] **P1 (Highest)**: Replace hardcoded export HFOV (`90`) with a per-export preset injected from `exportType` and applied consistently on init/load/animation camera calls.
- [ ] **P2**: Validate no behavioral regression in hotspot click/scene transitions after HFOV changes.
- [ ] **P3**: Evaluate optional dynamic HFOV formula (viewport-driven) behind a reversible switch if static presets are insufficient.
- [ ] **P4**: If dynamic approach degrades quality, rollback to static presets and document why.

## Code Changes Ledger (for surgical rollback)
- [x] Code changes started.
- [ ] Track every attempted edit with: file path, intent, and quick revert command.

### Attempted edits
- [x] `src/systems/TourTemplates.res`: Added export-size HFOV presets (`4k=90`, `2k=64`, `hd=40`) and replaced hardcoded `90` in export runtime calls (`loadScene`, `lookAt`, `setHfov`, and initial config `hfov/minHfov/maxHfov`).
- [x] Revert command (single-edit rollback): `git checkout -- src/systems/TourTemplates.res`
- [x] `src/systems/TourTemplates.res`: Reworked export viewport + HFOV behavior: `2k` and `hd` now share stage width clamp (`375..640`) and dynamic HFOV interpolation (`90 -> 65`) based on stage width; runtime now applies computed HFOV on load, resize, scene load, and animation frames.
- [x] `css/layout.css`: Set builder `#viewer-stage` minimum width to `640px` so stage does not shrink below 2k viewer size.
- [x] `tests/unit/TourTemplateStyles_v.test.res`: Updated style assertions for new stage sizing model.
- [x] `tests/unit/TourTemplateScripts_v.test.res`: Updated `generateRenderScript` call signature assertions for dynamic HFOV parameters.
- [x] `tests/unit/TourTemplates_v.test.res`: Updated HD export expectations for responsive stage and dynamic HFOV bounds.
- [x] `src/utils/Constants.res`: Added shared HFOV and stage width bounds (`globalMinHfov`, `globalMaxHfov`, builder landscape min/max width) for dynamic builder calibration.
- [x] `src/systems/SceneLoaderLogic.res`: Builder viewer config now uses `minHfov=65`, `maxHfov=90`, keeps `doubleClickZoom=false` and disables zoom controls.
- [x] `src/components/ViewerManager/ViewerManagerLifecycle.res`: Added dynamic builder HFOV recalculation (`90 -> 65`) based on stage width and applied on init, resize, and UI state updates.
- [x] `css/layout.css`: Added portrait fallback for stage viewer below small viewport thresholds (switches to portrait card instead of overflowing).
- [x] `css/components/viewer-ui.css`: Added responsive downscaling for floor buttons, room label, and logo in portrait/mobile stage mode.
- [x] `src/systems/TourTemplates.res`: Added portrait fallback + overlay downscaling for exports, enabled dynamic HFOV `90 -> 65` for 4k/2k/hd, and explicitly disabled zoom interactions including `doubleClickZoom`.

## Rollback Check
- [ ] Confirmed CLEAN or REVERTED non-working changes.

## Validation Checklist
- [ ] Exported 2k opens with HFOV 64 baseline behavior.
- [ ] Exported hd opens with HFOV 40 baseline behavior.
- [ ] Waypoint animation still runs and hotspot navigation remains clickable.
- [ ] No runtime script errors in exported tour.

## Context Handoff
- [ ] This task tracks HFOV calibration for export-size parity and potential dynamic-HFOV experimentation.
- [ ] Start with static presets first (4k=90, 2k=64, hd=40), then only test dynamic if needed.
- [ ] Any failed dynamic attempt must be logged with exact edits and a one-command rollback path.

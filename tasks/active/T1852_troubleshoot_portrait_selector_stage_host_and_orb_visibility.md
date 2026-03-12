## Objective

Troubleshoot and fix the exported-tour portrait mode selector so the 3 centered mode orbs render against the portrait stage, not the small top-left HUD container, and all three options remain visible before docking back to the intended top-left stacked position.

## Hypothesis (Ordered Expected Solutions)

- [ ] The portrait selector is currently mounted inside `.looking-mode-indicator`, so intro centering uses the wrong containing box. Moving it to a stage-level host should fix both the off-center intro and the missing/clipped orb.
- [ ] The intro state may still be inheriting legacy floor-tag container sizing / overflow behavior that clips the left-most orb. A dedicated portrait selector container should remove that constraint.
- [ ] Docked-state class transitions may be correct, but selector DOM placement is wrong. If host relocation alone does not fix it, portrait selector CSS selectors need to target the new stage-level host directly.

## Activity Log

- [x] Reviewed the screenshot symptom and compared it with the generated export structure.
- [x] Confirmed the current portrait selector host is still `#viewer-floor-tags-export` nested inside `.looking-mode-indicator`.
- [x] Added a dedicated stage-level portrait selector host to the export template.
- [x] Rewired portrait selector rendering/sync logic to target the new host while leaving classic/map rows on `#viewer-floor-tags-export`.
- [x] Updated portrait selector CSS and regression tests.
- [x] Rebuilt and verified export generation.

## Code Change Ledger

- [x] `src/systems/TourTemplateHtml.res` - Added `#viewer-portrait-mode-selector-export` as a stage-level host for the portrait intro/docked selector.
- [x] `src/systems/TourTemplates/TourScriptUINav.res` - Added selector host helpers, rendered portrait selector into the new host, and kept classic/map shortcut rows on the original floor-tag panel.
- [x] `src/systems/TourTemplates/TourScriptInput.res` - Included the new portrait selector host in the auto-tour pointer-down ignore list.
- [x] `src/systems/TourTemplates/TourStyles.res` - Retargeted portrait selector styling from `#viewer-floor-tags-export` to `#viewer-portrait-mode-selector-export` and hid that host outside portrait-adaptive mode.
- [x] `tests/unit/TourTemplateScripts_v.test.res` - Updated export-script assertions for the new selector host helper and pointer-down ignore selector list.
- [x] `tests/unit/TourTemplateStyles_v.test.res` - Updated portrait selector CSS assertions to target the new stage-level selector host.
- [x] `tests/unit/TourTemplates_v.test.res` - Asserted the generated export HTML now emits the dedicated portrait selector host.

## Rollback Check

- [x] Confirmed CLEAN. The fix path worked; no exploratory edits needed to be reverted.

## Context Handoff

The current portrait selector intro is mispositioned because it is rendered into `#viewer-floor-tags-export`, which lives inside `.looking-mode-indicator` at the top-left of the stage. As a result, intro centering is relative to that small HUD container, and one orb is clipped off-screen. The fix path is to introduce a dedicated stage-level portrait selector host and move the portrait selector renderer to it while leaving classic shortcut UI behavior untouched.

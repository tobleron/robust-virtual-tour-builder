# T1859 Troubleshoot Portrait Orb Left-Rail Alignment In Export Artifact

## Hypothesis (Ordered Expected Solutions)

- [ ] The exported artifact is still carrying stale dock-position CSS or JS and does not include the latest centerline alignment variables.
- [ ] The docked selector uses the correct variables, but the left rail and orb cluster are being aligned by different anchors (`left edge` vs `centerline`).
- [ ] Portrait mode is applying a fallback fixed inset that overrides the adaptive rail variables during the docked state.
- [ ] The artifact is loading a different shell path than expected (`classic`/`portrait-adaptive`) and the wrong selector rules are winning.

## Activity Log

- [x] Inspect the artifact `artifacts/eeeee` and identify which HTML entry is relevant to the reported portrait issue.
- [x] Compare the generated artifact script/CSS against current source expectations for portrait dock alignment.
- [x] Record whether the problem is stale export output, incorrect generated values, or incorrect CSS anchoring.
- [x] Measure the rendered selector and floor-rail positions in the live artifact using a headless browser.
- [x] Confirm the bug is caused by the docked portrait selector retaining intro-title layout width and centering the orb cluster inside that wide box.
- [x] Apply source fixes for docked portrait selector width/alignment, touch-shell HFOV locking, and portrait profile-aware width scaling.

## Code Change Ledger

- [x] [src/systems/TourTemplates/TourStyles.res](src/systems/TourTemplates/TourStyles.res) - Made portrait stage width profile-aware, aligned docked portrait selector to fit-content/left-start, and removed title layout footprint in docked portrait mode. Revert by restoring the old portrait viewport rule and docked selector rules.
- [x] [src/systems/TourTemplates/TourScriptViewport.res](src/systems/TourTemplates/TourScriptViewport.res) - Capped portrait HFOV to stay at least 7% below landscape, adjusted portrait buckets, and locked touch-shell HFOV bounds to prevent pinch zoom. Revert by restoring the previous portrait bucket values and removing the touch-shell `setHfovBounds` branch.
- [x] [tests/unit/TourTemplateScripts_v.test.res](tests/unit/TourTemplateScripts_v.test.res) - Updated export script assertions for the new portrait HFOV and touch Hfov-bounds behavior.
- [x] [tests/unit/TourTemplateStyles_v.test.res](tests/unit/TourTemplateStyles_v.test.res) - Updated style assertions for portrait profile scaling and docked selector fit-content behavior.

## Rollback Check

- [x] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff

The exported artifact `artifacts/eeeee` was not stale; it already contained the new adaptive rail variables. The actual defect was CSS anchoring: the docked portrait selector kept the intro title's width and centered the orb cluster inside that invisible wide box, which pushed the orbs to the right of the floor rail. The source fix now shrinks the docked selector to fit-content, removes the title footprint in docked portrait mode, makes portrait width profile-aware, and locks touch-shell HFOV so pinch zoom cannot alter it.

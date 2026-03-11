# T1841 Troubleshoot Export Portrait Logo Scaling

## Objective
Determine why exported tours render the logo too small in portrait mode and adjust the export logo sizing formula so portrait branding remains legible without regressing landscape sizing.

## Hypothesis (Ordered Expected Solutions)
- [ ] Portrait export currently reuses the landscape logo sizing result and then multiplies it down again, causing the logo to become disproportionately small on narrow stages.
- [ ] The portrait width/height caps are too conservative for tall mobile-style aspect ratios, so wide logos hit the width cap too early.
- [ ] The generated export artifact may still reflect an older sizing formula; confirm the current source and artifact behavior match before patching.

## Activity Log
- [x] Read `MAP.md`, `DATA_FLOW.md`, `tasks/TASKS.md`, `.agent/workflows/debug-standards.md`, and `.agent/workflows/rescript-standards.md`.
- [x] Inspected the latest user-provided export artifact under `artifacts/Export_RMX_kamel_al_kilany_080326_1528_v5.2.4 (8)`.
- [x] Confirmed portrait logo sizing uses the shared stage-area formula and then applies `LOGO_PORTRAIT_SCALE = 0.88`, which makes portrait logos smaller than landscape.
- [x] Patched export logo sizing to use dedicated portrait area/cap ratios while leaving landscape sizing unchanged, and removed the portrait fallback CSS shrink.
- [x] Verified with `npx vitest run tests/unit/TourTemplates_v.test.bs.js tests/unit/TourTemplateStyles_v.test.bs.js` and `npm run build`.

## Code Change Ledger
- [x] `src/systems/TourTemplateHtml.res` - Replaced portrait post-scale shrinking with dedicated portrait area and width/height caps in `syncExportLogoSize`.
- [x] `src/systems/TourTemplates/TourStyles.res` - Removed portrait fallback `0.88x` shrink from watermark and portrait marketing positioning CSS.
- [x] `tests/unit/TourTemplates_v.test.res` - Added regression expectations for the new portrait logo sizing constants and runtime calculations.
- [x] `tests/unit/TourTemplateStyles_v.test.res` - Updated CSS fallback expectations for portrait logo height.

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
The latest export artifact is using the current portrait logo path: it computes logo size from the stage area, clamps width/height for landscape, then shrinks portrait again using `LOGO_PORTRAIT_SCALE = 0.88`. For a wide logo on a narrow portrait stage, the width cap dominates, producing a very small mark. The clean fix is portrait-specific sizing variables in the export runtime rather than post-scaling the already-capped landscape result.

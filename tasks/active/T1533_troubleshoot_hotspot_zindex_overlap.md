# 🐛 TROUBLESHOOTING: Hotspot Action Menu Z-Index Overlap (T1533)

## 📋 Problem Description
The Hotspot Action Menu (Go, Manual/Auto, Move, Delete buttons) is being obscured by other scene elements such as waypoint lines (dashed orange) and link arrows (orange triangles). This occurs because the stacking context or z-index values are not correctly isolating the interactive builder UI from the decorative background guides.

## 🔬 Hypothesis (Ordered)
1. [x] **Stacking Context Isolation**: Parent containers (e.g., `.panorama-layer`) were capping the z-index of children, preventing them from rising above the SVG overlay layer. (Solution: Remove z-index from layers).
2. [x] **Layer Hierarchy Imbalance**: The "background guides" layer was using high z-index values (5000+) reserved for HUD, placing it physically on top of hotspots. (Solution: Demote guides to z=5~10).
3. [x] **Pannellum Internal Style Collision**: Pannellum forces inline z-index on hotspots which may override standard CSS. (Solution: Use `!important` on container elevations).
4. [x] **Partial Contributor - CSS Ownership Conflict**: Layer selectors were defined in both `viewer.css` and `ui.css`, which caused inconsistent layer behavior and confusion during debugging. (Solution: single source of truth for viewer layer stack).
5. [x] **True Root Cause - Hover Menu vs Persistent Guide Rendering**: The hotspot menu and the `arrow_{linkId}` / `hl_{linkId}` guide remain rendered simultaneously, and hit-testing confirms the SVG arrow can stay topmost at the menu center while expanded (reproduced with `A01` in `artifacts/x.zip`). (Solution: suppress that link's guide/arrow during hotspot hover and redraw on leave).

## 📝 Activity Log
- [x] Initial boost of hotspot hover z-index in `viewer-hotspots.css` and `PreviewArrow.res`.
- [x] Lowered `HotspotLayer` z-index in `HotspotLayer.res`.
- [x] Removed `z-index` from `.panorama-layer` in `viewer.css` to break stacking caps.
- [x] Defined explicit global layers (`#viewer-scene-elements-layer` and `#viewer-ui-layer`) in `viewer.css`.
- [x] Lowered all guide layers to baseline indices (5-10) and boosted hotspots to 100+ (baseline) and 15000+ (hover).
- [x] Reverted transient DOM move of `viewer-scene-elements-layer` in `App.res`.
- [x] Validated overlap screenshot indicates line/arrow layer bleeding into action menu, not a missing menu render.
- [x] Rolled back ineffective hotspot hover-elevation hacks and restored prior `PreviewArrow`, `HotspotLayer`, and `SnapshotOverlay` z-index values.
- [x] Consolidated layer ownership so `viewer.css` is authoritative and removed duplicate layer selectors from `ui.css`.
- [x] Verified CSS bundling passes via `npx rsbuild build` after layer-ownership refactor.
- [x] Added targeted E2E repro `tests/e2e/hotspot-overlap-a01.spec.ts` that loads `artifacts/x.zip`, selects scene index 1, hovers hotspot route `A01`, and probes overlay hit-testing.
- [x] Confirmed deterministic failure payload: `{"hasSvgOverlayOnTop":true,"overlayElementId":"arrow_A01","arrowDisplay":"block","lineDisplay":"block","arrowCenterInsideMenu":true,"menuButtonCount":4}`.
- [x] Implemented runtime suppression of `A01`-style guide overlays while the hotspot action menu is hovered, and restored overlays on hover exit.
- [x] Recompiled ReScript (`npm run res:build`) and reran repro E2E; test now passes.
- [x] Verified updated `PreviewArrow` contract via targeted unit test: `npx vitest tests/unit/PreviewArrow_v.test.bs.js`.

## 📜 Code Change Ledger
| File Path | Change Summary | Revert Note |
|-----------|----------------|-------------|
| `css/components/viewer-hotspots.css` | Set `.pnlm-hotspot.flat-arrow` to `z-index: 10 !important`, added hover elevation `15000 !important`. | Restore `z-index: 10` without `!important` and remove hover overrides. |
| `src/components/PreviewArrow.res` | Set container `z-index` to `[100]`. | Restore `z-index: [6000]`. |
| `src/components/HotspotLayer.res` | Set `viewer-hotspot-lines` to `z-index: [10]`. | Restore `z-index: [5000]`. |
| `src/components/SnapshotOverlay.res` | Removed explicit `z-index`, relying on parent layer. | Restore `z-index: [5000]`. |
| `css/components/viewer.css` | Commented out `z-index` on `.panorama-layer`. Added `#viewer-scene-elements-layer (z:5)` and `#viewer-ui-layer (z:100)`. | Re-enable `z-index: 2` on active layer and remove new layer rules. |
| `css/components/ui.css` | Removed duplicated `#viewer-scene-elements-layer` and `#viewer-ui-layer` selectors to prevent override conflicts with `viewer.css`. | Re-add selectors only if `viewer.css` ownership is intentionally moved. |
| `tests/e2e/hotspot-overlap-a01.spec.ts` | Added regression repro for `x.zip` hotspot `A01` overlap using SVG/menu hit-testing and navigation verification. | Remove file if overlap regression guard is no longer required. |
| `src/systems/HotspotLine/HotspotLineState.res` | Added `suppressedLinkId` runtime ref to control per-link guide suppression during hover menu interactions. | Remove ref and related suppression logic. |
| `src/systems/HotspotLine/HotspotLineUtils.res` | Re-exported `suppressedLinkId` to drawing facade. | Remove alias. |
| `src/systems/HotspotLine.res` | Added `setSuppressedLinkId` API for UI-triggered suppression. | Remove API and callers. |
| `src/systems/HotspotLine/HotspotLineDrawing.res` | Skip drawing/hide `hl_{linkId}` and `arrow_{linkId}` when `suppressedLinkId` matches current hotspot. | Remove suppression branch. |
| `src/components/PreviewArrow.res` | Added `linkId` prop + hover enter/leave handlers to suppress/restore matching guide overlays with forced redraw. | Remove prop and hover suppression hooks. |
| `src/components/HotspotManager.res` | Pass `hotspot.linkId` into `PreviewArrow`. | Remove prop wire-up if suppression removed. |
| `tests/unit/PreviewArrow_v.test.res` | Updated `<PreviewArrow />` test invocations with required `linkId` prop. | Remove prop if component contract is reverted. |

## 🔄 Rollback Check
- [x] (Confirmed CLEAN or REVERTED non-working changes).

## 🏁 Context Handoff
The overlap is now reproduced and guarded by E2E using real `x.zip` data and hotspot `A01`. The true issue was not only static z-index ordering; the link guide (`arrow_A01`/`hl_A01`) remained actively rendered during action-menu hover and could still become topmost at menu center. The current fix suppresses that link’s guide while hovered and restores it on leave, with `npm run res:build` and `npx playwright test tests/e2e/hotspot-overlap-a01.spec.ts --project=chromium` passing.

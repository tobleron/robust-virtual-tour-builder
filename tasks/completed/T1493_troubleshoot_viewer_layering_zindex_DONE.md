# T1493 Troubleshooting: Viewer Layering & Z-Index Conflict (Waypoints vs Builder UI)

## 🚨 Symptom
Waypoints and destination arrows (scene content) are overlaying builder-mode UI elements like the **Visual Pipeline**, causing a "dirty" UI where dashed lines pass over interactive squares and tooltips.

## 🔍 Context
- **Visual Pipeline**: Rendered in `VisualPipeline.res` with `z-index: 9000`.
- **Viewer UI Layer**: Rendered in `ViewerUI.res` wrapping `HotspotLayer` and `ViewerHUD`.
- **Z-Index Conflict**: `#viewer-ui-layer` in `ui.css` has `z-index: 16000`. Since `VisualPipeline` is outside this container (in `App.res`), the waypoints inside `HotspotLayer` inherit the 16000 context and appear on top of the 9000 pipeline.

## 🧠 Hypothesis (Ordered Expected Solutions)
1. [ ] **Stacking Context Split**: Move `HotspotLayer` (waypoints/arrows) out of the `16000` z-index container and into its own lower-priority layer (e.g., `z-index: 4000`).
2. [ ] **Visual Pipeline Promotion**: Increase `VisualPipeline` z-index to `17000`+ to ensure it clears the `viewer-ui-layer`.
3. [ ] **Unified Layering**: Integrate `VisualPipeline` into the `viewer-ui-layer` structure but ensure its internal z-index is lower than the HUD/Logo and higher than the HotspotLayer.

## 📝 Activity Log
- [x] Analysis: Identified `viewer-ui-layer` (16000) vs `VisualPipeline` (9000) conflict in `App.res`.
- [x] Implementation: Splitting `ViewerUI` into `ViewerSceneElements` (z:5000) and `ViewerUI` (z:16000).
- [x] Implementation: Updating `App.res` to correctly order these layers around `VisualPipeline`.

## 🧾 Code Change Ledger
- `src/components/ViewerSceneElements.res`: New component for low-priority indicators.
- `src/components/ViewerUI.res`: Removed `SnapshotOverlay` and `HotspotLayer`.
- `src/App.res`: Reordered layers: SceneElements (5000) < VisualPipeline (9000) < ViewerUI (16000).
- `css/components/ui.css`: Added `#viewer-scene-elements-layer` styling.

## ✅ Rollback Check
- [x] (Confirmed CLEAN or REVERTED non-working changes)


## 🏁 Context Handoff
Identified that `viewer-ui-layer` (z-index: 16000) is acting as a global stacking wall that puts everything in `ViewerUI.res` (including waypoints) on top of the `VisualPipeline` (z-index: 9000). The solution requires splitting the layers into "Scene Indicators" (Waypoints/Arrows) and "Builder UI" (Pipeline/Buttons).

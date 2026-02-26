# 🐛 TROUBLESHOOTING: Hotspot Waypoint Overlap (T1561)

## 📋 Problem Statement
The waypoint (orange dashed lines) and the orange arrow (at the beginning of the waypoint) appear **OVER** the hotspot interactive button. This makes the UI feel unpolished and can interfere with the visual weight of the interactive controls.

## 🔗 Related Context
- `src/components/ViewerManager.res`
- `src/components/HotspotLayer.res`
- `src/systems/HotspotLine/HotspotLineDrawing.res`
- `src/components/PreviewArrow.res`
- `src/Main.res` (DOM structure)

## 🎯 Objective
Ensure the hotspot interactive button (the orange button with chevrons) is always rendered **above** the visual guide elements (orange waypoint lines and arrows).

## ✅ Acceptance Criteria
- Hotspot buttons (center button, move/delete menu) are physically and visually on top of the waypoint lines.
- Guide lines/arrows do not obscure the hotspot icons or buttons.
- Hit testing for buttons remains reliable.
- `npm run build` passes.

## 🔬 Hypothesis (Ordered Expected Solutions)
- [x] **H1: CSS Stacking Context Issue**: Confirmed. Pannellum hotspots were trapped in a lower z-index stacking context than the SVG lines.
- [x] **H2: Layer Interleaving**: Fixed by moving hotspot rendering to a dedicated React layer (`ReactHotspotLayer`) inside the same stacking context as the SVG, but with a higher z-index.

## 🧪 Reproduction & Investigation Plan
1. [x] Verify the current DOM structure.
2. [x] Check the computed z-index.
3. [x] Experiment with moving the SVG layer container.
4. [x] Move hotspots to our own React layer for full control.

## 📝 Activity Log
- [x] Task initialized.
- [x] Root cause identified: Stacking context mismatch between Pannellum and React layers.
- [x] Implemented `ReactHotspotLayer.res` for independent hotspot management.
- [x] Updated `HotspotLayer.res` to include the new React hotspots.
- [x] Disabled Pannellum internal hotspot sync in `HotspotManager.res`.
- [x] Verified build success and correct layering.

## 📜 Code Change Ledger
| File Path | Change Summary | Revert Note |
|-----------|----------------|-------------|
| `src/components/ReactHotspotLayer.res` | New component for React-managed hotspot rendering. | Delete file |
| `src/components/HotspotLayer.res` | Integrated ReactHotspotLayer after SVG lines. | Remove component import |
| `src/components/HotspotManager.res` | Disabled Pannellum's internal hotspot renderer. | Uncomment sync loop |

## 🔄 Rollback Check
- [ ] Confirmed CLEAN.

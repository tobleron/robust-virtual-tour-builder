# Task: 811 - Test: Hotspot Management & Visuals (New + Update)

## Objective
Validate the creation, editing, and rendering of navigational hotspots.

## Merged Tasks
- 611_Test_HotspotActionMenu_Update.md
- 612_Test_HotspotLayer_Update.md
- 613_Test_HotspotManager_Update.md
- 614_Test_HotspotMenuLayer_Update.md
- 678_Test_HotspotLine_Update.md
- 679_Test_HotspotLineLogic_Update.md
- 680_Test_HotspotLineTypes_Update.md
- 659_Test_HotspotReducer_Update.md

## Technical Context
Hotspots are the primary interaction point. This group covers the editor UI (`HotspotManager`), the interactive layer (`HotspotLayer`), and the visual connectors (`HotspotLine`).

## Implementation Plan
1. **HotspotManager**: Test drag-and-drop placement and safe area constraints.
2. **Reducer**: Verify ADD, REMOVE, and UPDATE actions for hotspots.
3. **LineLogic**: Test the math for drawing lines between 3D points projected to 2D.
4. **Layers**: Smoke test the React rendering of SVG elements.

## Verification Criteria
- [ ] Hotspot coordinates are correctly updated in the reducer on move.
- [ ] Line logic correctly handles behind-camera visibility.

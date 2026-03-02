# T1788 - Refactor Hotspot Targeting to IDs

## Assignee: Gemini
## Capacity Class: B
## Objective
Switch hotspot targeting from array indices (`sceneIndex`, `hotspotIndex`) to unique IDs (`sceneId`, `hotspotId`) to ensure data stability during concurrent edits or reordering.

## Context
The current `retargetHotspot` state relies on array indices. If scenes are reordered or hotspots are deleted while the Link Modal is open, the index might point to the wrong item.

## Strategy
1.  **Update Draft**: Change `retargetHotspot` in `linkDraft` to use `sceneId` and `hotspotId`.
2.  **Update Logic**: Update `HotspotManager` and `LinkModal` to lookup the target hotspot by ID instead of index.
3.  **Migration**: Ensure existing drafts (if any) are handled or cleared.

## Boundary
- `src/core/Types.res`
- `src/components/LinkModal.res`
- `src/components/PreviewArrow.res`
- `src/components/HotspotManager.res`

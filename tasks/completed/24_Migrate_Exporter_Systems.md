# Task: Migrate Exporter Systems

## Objective
Migrate the tour export functionality (`Exporter.js` and `TourHTMLTemplate.js`) to ReScript.

## Context
This system generates the HTML, CSS, and JS structure for the downloadable virtual tour (ZIP package). It interfaces with the backend to bundle assets.

## Implementation Details

1.  **`TourTemplates.res`**:
    - Ported all HTML generation logic (HD, 2K, 4K templates).
    - Ported CSS generation (responsive styles).
    - Ported JS runtime scripts (hotspot rendering, auto-navigation) using `%raw` strings where appropriate to preserve logic.
    - Updated variable interpolation to use ReScript bindings.

2.  **`Exporter.res`**:
    - Implemented `exportTour` orchestration.
    - Implemented `fetchLib` with `Fetch` API.
    - Implemented `uploadAndProcess` using `%raw` wrapper for `XMLHttpRequest` (to support upload progress events).
    - Integrated with `GlobalStateBridge` and `DownloadSystem`.

3.  **Integration**:
    - Updated `Sidebar.res` to call `Exporter.exportTour` directly.
    - Removed legacy JS bindings.

## Verification
- [x] Project compiles successfully (`npm run res:build`).
- [x] Types match for `scenes` and `progress` callback.
- [x] JS implementation files deleted.

## Status
✅ **COMPLETE**

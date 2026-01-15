# Task: Implement Virtualization for SceneList

## Status
- **Priority:** HIGH
- **Estimate:** 4 hours
- **Category:** Performance

## Description
The current `SceneList.res` component renders all scene items eagerly using `Belt.Array.mapWithIndex`. While performant for small projects, it will cause DOM lag and memory pressure when projects exceed 50-100 scenes.

## Requirements
1.  **Integrate Virtualization:** Use a virtualization library (e.g., `react-window` or `react-virtuoso`) or implement a custom intersection-observer based lazy renderer.
2.  **Maintain Reorder Functionality:** Ensure that drag-and-drop reordering still works correctly within the virtualized list.
3.  **Fixed/Variable Heights:** Account for the fixed height of `SceneItem` components to optimize scroll calculations.
4.  **Scroll State:** Ensure the scroll position is maintained when switching between scenes or updating metadata.

## Expected Outcome
Smooth 60fps scrolling in the sidebar even with 200+ scenes loaded.

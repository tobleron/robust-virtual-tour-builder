# Task 274: Fix Hotspot Navigation Click

## Objective
Fix the issue where clicking a hotspot navigation chevron does not trigger scene transition. This was likely caused by the introduction of `pointer-events: none` on the tooltip container, which can interfere with `onclick` delegation.

## Technical Plan
1.  **Refactor `HotspotManager.res`**:
    *   Move click handling logic from the root `div` (delegation) to direct `addEventListener` calls on `deleteBtn`, `navBtn`, and `forwardBtn`.
    *   Maintain `pointer-events: none` on the root `div` to ensure clicks on transparent gaps pass through to the panorama (supporting drag/rotate).
    *   Ensure proper use of `stopPropagation` and `preventDefault` on each button to maintain clean interaction.
2.  **Verify**:
    *   Hotspot navigation works.
    *   Auto-forward toggle works.
    *   Delete button works (after hover delay).
    *   Panorama can still be dragged when clicking the empty space between hotspot chevrons.

## Realization
Identified that `pointer-events: none` on the hotspot tooltip container (added in v4.4.1) was preventing click event delegation from reaching the root handler. Refactored `HotspotManager.res` to attach event listeners directly to the interactive elements (`navBtn`, `deleteBtn`, `forwardBtn`) instead of relying on delegation. This ensures buttons remain functional while the container remains transparent to pointer events, allowing panorama rotation when clicking on gaps.

### Technical Changes
- Updated `HotspotManager.res` to use `ElementExt.setOnClick` on individual button elements.
- Removed the root `div` click listener.
- Maintained `pointer-events: none` on the root `div` for UX consistency.
- Verified build passes.

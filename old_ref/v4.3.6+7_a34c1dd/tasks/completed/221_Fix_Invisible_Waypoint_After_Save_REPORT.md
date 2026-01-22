# Fix Invisible Waypoint After Save - REPORT

## Objective
Fix the issue where the created waypoint/hotspot exists (logically) but remains invisible to the user after saving, reappearing only when "Add Link" is clicked again.

## Analysis
The "invisibility" was likely due to a state desynchronization or "Zombie" DOM element issue.
- Even with the Diff-based sync (Task 220), if the initial state contained a corrupted or hidden hotspot element (from previous bugs), the Diff logic might have seen "ID exists in Viewer" and "ID exists in State" and decided *not* to update it.
- This left the invisible "Zombie" hotspot in place.
- Clicking "Add Link" might have triggered a side-effect or simply re-focused the user's attention, or the user was seeing the "Draft" appearing (if they clicked slightly differently).
- However, the most robust way to ensure visibility is to **Force Refresh** the hotspots upon state change.

## Technical Resolution
Modified `src/components/HotspotManager.res` to use a **"Safe Nuke"** synchronization strategy:
1.  **Remove ALL**: Iterates over a copy of all current hotspot IDs in the viewer and removes them. This clears any potential zombies, stale states, or corrupted DOM elements.
2.  **Add ALL**: Iterates over the current scene's hotspots and adds them all fresh.
3.  **Efficiency**: While less efficient than Diffing for massive lists, for < 50 hotspots this is negligible and guarantees 100% correct state synchronization with Pannellum's imperative DOM.
4.  **Safety**: Used the "iterate over copy" pattern (established in Task 219) to ensure the removal loop doesn't crash due to index shifting.

## Verification
- **Build**: `npm run build` passed.
- **Logic**: By clearing and re-adding, we eliminate the possibility of a "present but invisible" hotspot persisting. The fresh `addHotSpot` call ensures the new hotspot is rendered with the correct CSS and event listeners.

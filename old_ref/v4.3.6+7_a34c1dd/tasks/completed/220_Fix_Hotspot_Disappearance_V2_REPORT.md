# Fix Hotspot Disappearance V2 - REPORT

## Objective
Address the persistent issue where all waypoints disappear exactly after saving a link, despite previous attempts to fix the removal loop.

## Analysis
The previous fix (Task 219) addressed unsafe iteration but did not address the potential ID collision or state synchronization issues inherent in the "Nuke and Rebuild" strategy with unstable IDs.
- `LinkModal` was initializing hotspots with an empty `linkId`, relying on `HotspotManager` to generate IDs based on array index (`hs_` + index).
- Because `removeHotSpot` and `addHotSpot` happened in the same tick (synchronous `syncHotspots`), removing `hs_0` and immediately adding `hs_0` (even with different content) likely caused Pannellum to malfunction (e.g., reusing a fading DOM element or internal map conflict).
- This resulted in the new hotspot failing to render, leading to "disappearance".

## Technical Resolution
1.  **Unique IDs**: Modified `LinkModal.res` to generate a unique `linkId` (using `TourLogic.generateLinkId`) when creating a new hotspot. This ensures every hotspot has a stable, unique identifier that persists across state updates.
2.  **Diff-based Sync**: Refactored `HotspotManager.res` `syncHotspots` to use a strict Diff-based approach instead of "Clear All and Add All".
    - Calculated `idsToRemove` (IDs in Viewer but not in State).
    - Calculated `idsToAdd` (IDs in State but not in Viewer).
    - Only removed the necessary IDs.
    - Only added the new IDs.
    - Existing hotspots (that match by ID) are left untouched, preventing any flicker or collision issues.
3.  **Config Update**: Updated `createHotspotConfig` to prefer `linkId` as the DOM ID, falling back to index only if empty (legacy support).

## Verification
- **Build**: `npm run build` passed.
- **Logic**: The diff-based approach is the standard solution for syncing declarative state (React/Redux) with imperative imperative APIs (Pannellum). By avoiding unnecessary removals/additions, we bypass the "Same Tick ID Reuse" bug entirely.

# Fix Hotspot Disappearance After Save - REPORT

## Objective
Fix the issue where the created waypoint/hotspot completely disappears after saving the link.

## Analysis
The disappearance was traced to a bug in `HotspotManager.res` within the `syncHotspots` function.
- The function attempts to remove all existing hotspots before adding the new set (to ensure synchronization).
- It iterated over the `hotSpots` array retrieved from `Viewer.getConfig(v)`.
- Inside the loop, it called `Viewer.removeHotSpot(v, id)`.
- **The Bug**: `removeHotSpot` modifies the internal `hotSpots` array *in place*. Iterating over an array while modifying it (removing elements) causes index shifting, leading to skipped elements or runtime errors (e.g., accessing an index that no longer exists).
- If the loop crashed or behaved unexpectedly due to this modification, the subsequent code to **add the new hotspot** (which runs after the removal loop) would either not execute or execute in an inconsistent state.

## Technical Resolution
Modified `src/components/HotspotManager.res`:
- Before iterating, created a copy of the hotspot IDs to be removed: `let idsToRemove = Belt.Array.map(hs, h => h["id"])`.
- Iterated over this *copy* (`idsToRemove`) to perform removals.
- This ensures the iteration is stable regardless of changes to the underlying `hotSpots` array.
- Added debug logging to `syncHotspots` to verify the count of hotspots being synced.

## Verification
- **Build**: `npm run build` passed.
- **Logic Check**: Safely removing elements by iterating a copy is a standard fix for "modification during iteration" bugs. This ensures the cleanup phase completes successfully, allowing the `Viewer.addHotSpot` calls (including the new waypoint) to execute reliably.

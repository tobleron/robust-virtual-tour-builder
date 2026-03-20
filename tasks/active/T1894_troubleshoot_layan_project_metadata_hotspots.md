# T1894 Troubleshoot Layan Project Metadata Hotspots

## Objective
Repair the saved Layan project metadata so hotspot rendering works from project data alone, then remove the temporary runtime viewer scene-id fallback that was added to keep older project loads visible.

## Hypothesis
- [ ] The saved Layan `.vt.zip` archives still use legacy scene IDs in the `hash_size` format, while the current builder/runtime expects the normalized pure-hash scene ID format.
- [ ] The older project metadata remains internally consistent enough to import, but the legacy ID shape causes the hotspot overlay scene matching to fail in current builds.
- [ ] Rewriting the archived project metadata to normalized scene IDs and all dependent references will let the project load correctly without keeping fallback logic in the app.

## Activity Log
- [x] Confirm the current checkpointed code state before touching the Layan project data.
- [x] Locate the actual Layan saved project archives instead of the raw image folder.
- [x] Inspect the saved `project.json` payload and compare its scene IDs with newer exported Layan/Kilany data.
- [x] Verify that trimming the legacy size suffix from the saved Layan scene IDs causes no collisions.
- [x] Rewrite the saved Layan archive metadata to normalized pure-hash scene IDs.
- [x] Remove the temporary viewer scene-id fallback from the runtime code.
- [x] Rebuild and verify the app after the fallback removal.
- [x] Reinspect the patched archive metadata to confirm all scene references were updated consistently.

## Code Change Ledger
- [x] `src/components/ReactHotspotLayer.res` - removed the temporary viewer scene-id fallback helper and restored metadata-only scene matching after the archive repair.
- [x] `src/components/ViewerManager/ViewerManagerHotspots.res` - removed the resolved-scene-id fallback path added for older projects.
- [x] `src/components/ViewerManager/ViewerManagerSceneLoad.res` - removed the active-scene reconciliation fallback path added for older projects.
- [x] `/Users/r2/Desktop/EXPORTS/Saved_RMX_layan_sabour_compound_231225_1544_v5.1.1_2026-03-01.vt.zip` - rewrote `project.json` scene IDs and dependent references from legacy `hash_size` to normalized pure-hash IDs.
- [x] `/Users/r2/Desktop/EXPORTS/Saved_RMX_layan_sabour_compound_231225_1544_v4.14.2_2026-02-28.vt.zip` - rewrote `project.json` scene IDs and dependent references from legacy `hash_size` to normalized pure-hash IDs.
- [x] Verification - `npm run build` is blocked by the active ReScript watcher PID `37850`; verified instead via updated `.bs.js` outputs and a successful `npx rsbuild build`.

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
The saved Layan builder archives in `/Users/r2/Desktop/EXPORTS/` use legacy scene IDs with a size suffix, while newer projects use pure-hash scene IDs. Current runtime code still contains a temporary fallback that reads the live viewer scene ID when metadata is missing; the user wants that removed after the data repair. The current autosave in Chrome is the Kilany project, so the Layan fix needs to happen in the saved `.vt.zip` archives, not the current IndexedDB session.

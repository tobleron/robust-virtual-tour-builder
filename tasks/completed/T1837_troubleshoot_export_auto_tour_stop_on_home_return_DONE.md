# T1837 Troubleshoot Export Auto-Tour Stop On Home Return

## Objective
Ensure the exported auto-tour stops automatically once playback returns to the very first scene, instead of looping indefinitely through the manifest/runtime traversal.

## Hypothesis (Ordered Expected Solutions)
- [ ] The manifest playback cursor is still finding another valid step after returning to the home scene, so auto-tour restarts instead of treating home return as completion.
- [ ] The runtime only completes on manifest exhaustion or explicit dead-end checks, and it is missing a dedicated "returned to first scene" completion condition.
- [ ] Auto-tour backtracking/return-link handling is advancing the cursor correctly but not checking whether the arrival scene is the first scene before scheduling the next hop.
- [ ] The smart manifest generation itself includes a loop back to home plus another forward step from home, so runtime needs an explicit guard rather than relying on manifest shape.

## Activity Log
- [x] Re-read repo context docs and task/debug workflows.
- [x] Inspect the exported auto-tour runtime entrypoints related to start/stop/completion and manifest cursor advancement.
- [x] Identify the root cause: when manifest playback had no next step, `resolveScenePlaybackHotspot` fell back to generic canonical navigation instead of completing the auto-tour.
- [x] Implement the smallest runtime guard that stops auto-tour when it comes back to the first scene after departure.
- [x] Verify with targeted export template test and full frontend build.
- [x] Update the completion routine so ending auto-tour forces looking mode off during the stop phase and still triggers the smart-engine home-scene pan when the countdown finishes while already on the first scene.
- [x] Re-verify the end-of-tour routine with `npm run res:build`, `npx vitest run tests/unit/TourTemplates_v.test.bs.js`, and `npm run build`.

## Code Change Ledger
- [x] `src/systems/TourTemplates/TourScriptNavigation.res` - Treat auto-tour manifest as authoritative: stop playback when returning to the home scene after departure, and do not fall back to generic navigation when no manifest step remains. Revert if this blocks legitimate initial home-scene start behavior.
- [x] `tests/unit/TourTemplates_v.test.res` - Added export template assertions for the new home-return and no-fallback auto-tour guards. Revert if the assertions become too coupled to render-script formatting.
- [x] `src/systems/TourTemplates/TourScriptUIMap.res` - Forced looking mode off during auto-tour completion and added a same-scene home-finish path that calls `animateSceneToPrimaryHotspot(...)` instead of no-op home navigation. Revert if this introduces an unwanted end-of-tour pan.

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
The exported auto-tour now uses a canonical precomputed manifest, but it was still looping because manifest playback fell back to generic canonical navigation once no manifest step remained for the current scene. The runtime now treats the manifest as authoritative during active auto-tour, and it returns `null` for playback once the tour comes back to the first scene after departure or there is no remaining manifest step. Verification passed with `npx vitest run tests/unit/TourTemplates_v.test.bs.js` and `npm run build`.

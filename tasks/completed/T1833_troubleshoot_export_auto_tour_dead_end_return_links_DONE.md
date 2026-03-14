# T1833 Troubleshoot Export Auto Tour Dead End Return Links

## Objective
Fix exported-tour auto-tour behavior so entering a dead-end room with only an `R` return link does not incorrectly terminate the tour and return home when a valid return traversal should continue the route, and preserve distinct authored hotspots when multiple same-destination links exist in a scene.

## Hypothesis (Ordered Expected Solutions)
- [ ] The exported auto-tour traversal selector is treating return links as exhausted/end-state candidates instead of valid fallback moves once non-return exits are unavailable.
- [ ] Auto-tour continuation depends on auto-forward metadata after arrival, so dead-end rooms without auto-forward exits are incorrectly classified as terminal scenes.
- [ ] The exported runtime is distinguishing manual shortcut return-link navigation from auto-tour traversal incorrectly, causing the room to look like a completed terminal visit during auto-tour.
- [ ] The visited-link or visited-scene bookkeeping is prematurely marking the return link unavailable on dead-end arrival, leaving the auto-tour with no legal continuation and triggering return-home logic.
- [ ] Export-time hotspot deduplication is collapsing authored same-destination hotspots too aggressively, so later sequence edges remain in runtime state while one visible hotspot disappears from the exported tour.

## Activity Log
- [x] Re-read project process/docs and inspected active export-tour runtime/test entrypoints.
- [x] Trace exported auto-tour runtime selection and completion logic for dead-end rooms with return links.
- [x] Patch the smallest exported runtime layer that restores continuation through valid return links.
- [x] Run targeted verification first, then full `npm run build`.
- [x] Update or add regression coverage for exported auto-tour dead-end return-link traversal.
- [x] Trace exported same-destination hotspot deduplication and confirm the merge behavior is intentional for same-scene targets, with the real issue living in runtime sequence handling rather than export visibility.
- [x] Revert the non-working export hotspot dedupe-key refinement so same-destination hotspots merge again in the exported tour.
- [x] Replace exported auto-tour scene-local traversal reconstruction with a precomputed canonical manifest derived from the smart simulation engine.
- [x] Thread the manifest through export HTML/runtime so active auto-tour follows the exact canonical route while manual navigation and visible sequence UI remain unchanged.
- [x] Re-run targeted export-template tests, full frontend unit tests, and full production build after the manifest migration.
- [ ] Continue tracing the runtime sequence-state bug for merged same-destination hotspots if needed after behavioral confirmation.

## Code Change Ledger
- [x] [src/systems/TourTemplates/TourScriptNavigation.res](src/systems/TourTemplates/TourScriptNavigation.res): split auto-tour backtrack handling from auto-forward loop guarding so dead-end return/backtrack hops do not incorrectly trigger `completeTourAndReturnHome()`.
- [x] [tests/unit/TourTemplates_v.test.res](tests/unit/TourTemplates_v.test.res): added export HTML/runtime assertions covering the new auto-tour backtrack guard path and playback-target metadata threading.
- [x] [src/systems/TourTemplateHtml.res](src/systems/TourTemplateHtml.res): reverted the non-working export dedupe-key change so same-destination hotspots merge again in exported tours.
- [x] [tests/unit/TourTemplates_v.test.res](tests/unit/TourTemplates_v.test.res): restored the intentional same-destination hotspot merge regression expectation after reverting the export-key change.
- [x] [src/systems/TourTemplates/TourData.res](src/systems/TourTemplates/TourData.res): added exported auto-tour manifest types/encoders so canonical route steps can be serialized alongside scene data.
- [x] [src/systems/TourTemplateHtml.res](src/systems/TourTemplateHtml.res): derived a canonical auto-tour manifest from `SimulationMainLogic.getNextMove(...)`, preserved merged visible hotspots, and embedded the manifest into exported HTML.
- [x] [src/systems/TourTemplates/TourScriptNavigation.res](src/systems/TourTemplates/TourScriptNavigation.res): switched active exported auto-tour playback to manifest-cursor routing instead of scene-local sequence heuristics, including sequence-cursor threading for arrivals.
- [x] [src/systems/TourTemplates/TourScriptUINav.res](src/systems/TourTemplates/TourScriptUINav.res): reset manifest playback state on auto-tour start/stop.
- [x] [src/systems/TourTemplates/TourScriptHotspots.res](src/systems/TourTemplates/TourScriptHotspots.res): bypassed the old scene-target revisit guard for manifest-driven auto-tour playback so merged same-destination routes do not terminate incorrectly.
- [x] [tests/unit/TourTemplates_v.test.res](tests/unit/TourTemplates_v.test.res): updated export-template regressions to assert manifest emission and the split between merged visible hotspots and logical auto-tour route data.

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
The confirmed fixes in this task now cover both the original dead-end backtrack bug and the broader auto-tour routing drift: exported auto-tour no longer reconstructs traversal scene-by-scene from `sequenceEdges`, but instead follows a precomputed canonical manifest generated from the smart simulation engine. Same-destination hotspot merging remains intentional in exported tours, while the manifest carries the logical authored step data needed for runtime playback without exposing duplicate numbers to the end user. If further issues remain, they should now be treated as manifest-generation/runtime-playback mismatches rather than export hotspot deduplication problems.

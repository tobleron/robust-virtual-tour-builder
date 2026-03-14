# T1829 Troubleshoot Export Revisit Sequence Context And Pan

## Objective
Fix exported-tour smart-engine behavior for repeated logical visits to the same visible scene so revisit/no-animation arrivals pick the correct next logical target and auto-pan to the best smart-engine destination.

## Hypothesis (Ordered Expected Solutions)
- [ ] The revisit/no-animation path is using a source-scene hotspot resolver that ignores return-link entry context, so repeated visits fail to establish the correct starting orientation before the smart pan.
- [ ] The smart-engine cursor is selecting the wrong logical sequence edge when multiple logical visits collapse into one visible hotspot, so revisits to scenes like `Ground Living Room` do not advance to the later sequence context.
- [ ] Post-arrival focus is using a scene-level preferred target without enough arrival-context weighting, so revisited scenes with duplicate logical targets do not pan to the correct next hotspot.
- [ ] The exported runtime is preserving the right sequence-edge data, but the hotspot-to-sequence remapping on click/re-entry is stale after deduped visible hotspots are visited once.

## Activity Log
- [x] Re-read project process/docs and inspected current export runtime files.
- [x] Reproduce the repeated-visible-scene logic in the runtime code path and identify the incorrect resolver.
- [x] Patch the smallest runtime layer that restores correct revisit/no-animation smart panning.
- [x] Run build-only verification (`npm run res:build`, `npx rsbuild build`).
- [x] Extend revisit/no-animation smart-pan behavior to interpolate pitch as well as yaw toward the chosen follow-up hotspot.
- [x] Add/update frontend regression assertions for the export runtime strings that enforce pitch-aware revisit focus behavior.
- [x] Trace the home-wrap sequence bug where a direct link from the last scene back to the first scene preserved the previous sequence cursor instead of resetting to home sequence `#1`.
- [x] Normalize pending arrival sequence context so any navigation targeting the home scene resets the room label to `#1`.
- [x] Re-verify affected export runtime behavior with `npm run res:build`, `npx vitest run tests/unit/TourTemplates_v.test.bs.js`, and `npm run build`.

## Code Change Ledger
- [x] [src/systems/TourTemplates/TourScriptNavigation.res](src/systems/TourTemplates/TourScriptNavigation.res): added `resolveArrivalReferenceHotspot(...)` so revisit logic can use either a forward or return-link reference to the source scene when available.
- [x] [src/systems/TourTemplates/TourScriptHotspots.res](src/systems/TourTemplates/TourScriptHotspots.res): changed revisit/no-animation behavior to always compute the smart-engine post-arrival target and pan toward it even when no source-scene hotspot exists; arrival context now only improves the starting orientation when available.
- [x] [src/systems/TourTemplates/TourScriptHotspots.res](src/systems/TourTemplates/TourScriptHotspots.res): upgraded the revisit smart-pan animation to track both yaw and pitch toward the resolved next-hotspot focus view instead of keeping pitch fixed.
- [x] [tests/unit/TourTemplates_v.test.res](tests/unit/TourTemplates_v.test.res): aligned export-runtime regression coverage with the new pitch-aware revisit focus animation.
- [x] [src/systems/TourTemplates/TourScriptNavigation.res](src/systems/TourTemplates/TourScriptNavigation.res): reset the tracked arrival sequence cursor to `0` whenever the navigation target is the home scene so the exported room label displays `#1` on wrap-back arrivals.

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
The exported smart engine now keeps revisit/no-animation smart-pan aligned with both yaw and pitch for the chosen follow-up hotspot. Arrival context still sets the starting yaw when a source-scene reference hotspot exists, but the actual focus target now comes from the resolved hotspot focus view. If more revisit issues remain, inspect `TourScriptNavigation.res`, `TourScriptHotspots.res`, and `tests/unit/TourTemplates_v.test.res` first because that is where preferred-target resolution and post-arrival focus behavior now converge.

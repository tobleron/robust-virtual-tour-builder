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

## Code Change Ledger
- [x] [src/systems/TourTemplates/TourScriptNavigation.res](src/systems/TourTemplates/TourScriptNavigation.res): added `resolveArrivalReferenceHotspot(...)` so revisit logic can use either a forward or return-link reference to the source scene when available.
- [x] [src/systems/TourTemplates/TourScriptHotspots.res](src/systems/TourTemplates/TourScriptHotspots.res): changed revisit/no-animation behavior to always compute the smart-engine post-arrival target and pan toward it even when no source-scene hotspot exists; arrival context now only improves the starting orientation when available.

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
The exported smart engine now handles most canonical-sequence flows correctly, but repeated logical visits to the same visible scene still break on revisit/no-animation. The likely failure is in how arrival context and deduped visible hotspots are mapped back onto logical sequence edges. If the session ends mid-fix, inspect `TourScriptNavigation.res` and `TourScriptHotspots.res` first because that is where preferred-target resolution and revisit auto-pan currently diverge.

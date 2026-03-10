# T1827 Troubleshoot Export Artifact Navigation Analysis

## Hypothesis (Ordered Expected Solutions)
- [ ] The latest exported artifact still has logical/runtime mismatches between visible hotspots and sequence-driven navigation state, causing end-user confusion even when authored scene order is correct.
- [ ] The glass-panel arrows, room label sequence numbers, and hotspot click behavior may disagree with each other inside the artifact because they are derived from different runtime sources.
- [ ] The exported artifact may contain stale or malformed per-scene navigation metadata that only becomes visible when inspecting the generated `index.html` rather than the source code.
- [ ] The exported tour may still contain sequence-context ambiguities on revisited scenes, so end users can reach a scene with correct ordering but receive the wrong next-direction guidance.

## Activity Log
- [x] Read `MAP.md`, `DATA_FLOW.md`, `tasks/TASKS.md`, `.agent/workflows/debug-standards.md`, and `.agent/workflows/rescript-standards.md` earlier in this session.
- [x] Identified the latest exported artifact on Desktop as `Export_RMX_kamel_al_kilany_080326_1528_v5.2.3 (9)`.
- [x] Inspect the generated export HTML/runtime data for sequence edges, visible hotspots, labels, and shortcut behavior.
- [x] Summarize artifact-level end-user navigation problems without changing code.
- [x] Patch the export source runtime so sequence positions, forward/back shortcuts, and visible hotspot numbers use one canonical model.
- [x] Verify the patched export source with `npx vitest tests/unit/TourTemplates_v.test.bs.js --run`, `npm run res:build`, and `npm run build`.

## Findings
- [x] The artifact still ships `EXPORT_TRAVERSAL_MODE = "legacy"` in `desktop/index.html`, so first-arrival playback selection is still driven by legacy hotspot ordering while shortcut labels and revisit context use sequence-edge state.
- [x] The start scene has no forward shortcut because `resolveNextForwardSequenceEdge()` requires `edge.sequenceNumber > currentCursor`; on the home scene both are `1`, so `ArrowUp` and the glass-panel forward row never appear.
- [x] Sequence numbering is inconsistent across surfaces: hotspot badges render `sequenceNumber + 1`, but room-label/map sequence rows use the raw `sequenceNumber`, producing a duplicate `1` mapping for both `Zoom Out View` and `Left side`.
- [x] Revisited-scene dedupe is only partially reflected in the UI: `Ground hall` has logical edges `4` and `14` collapsed into one visible hotspot, but the hotspot face text is derived from `hotSpots[].sequenceNumber`, so the visible badge stays on the earliest context instead of the current logical revisit context.
- [x] Previous-scene navigation is still history-based for non-dead-end scenes because `resolvePreviousSequenceTarget()` uses `currentSceneSourceSceneId` / `persistentFrom`, not the authored previous sequence edge. This can diverge from canonical sequence when the user deviates via map/home/manual paths.
- [x] Sequence-map/jump rows collapse revisited scenes to their earliest occurrence because `buildSceneSequenceRows()` stores the minimum sequence per scene. Later sequence contexts for repeated scenes are not directly represented in the exported navigation UI.

## Code Change Ledger
- [x] [src/systems/TourTemplateHtml.res](src/systems/TourTemplateHtml.res): switched generated exports to `canonical` traversal mode so first-arrival playback uses the same model as shortcut labels and revisit context.
- [x] [src/systems/TourTemplates/TourScriptNavigation.res](src/systems/TourTemplates/TourScriptNavigation.res): added canonical sequence-position maps, set the home scene default cursor to `0`, resolved previous-scene targets by sequence position, and changed canonical playback selection to use `resolveNextForwardSequenceEdge(...)`.
- [x] [src/systems/TourTemplates/TourScriptUINav.res](src/systems/TourTemplates/TourScriptUINav.res): fixed room-label numbering to display `currentCursor + 1`, rebuilt map/jump rows from exact sequence positions, and carried `sequencePosition` through direct scene jumps so repeated scenes can be entered in the right logical context.
- [x] [src/systems/TourTemplates/TourScriptHotspots.res](src/systems/TourTemplates/TourScriptHotspots.res): made visible hotspot badge numbers resolve from the active logical sequence edge instead of the static deduped hotspot payload.
- [x] [tests/unit/TourTemplates_v.test.res](tests/unit/TourTemplates_v.test.res): added regression coverage for canonical traversal mode, home cursor `0`, sequence-position maps, dynamic hotspot numbering, and sequence-position jump wiring.

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
- The initial artifact analysis found mismatches between legacy playback state and the newer sequence-edge UI/runtime.
- The export source is now patched so home scene progression, room labels, hotspot badge numbers, and previous-scene resolution all use canonical sequence positions.
- The next practical check is to generate a fresh export and validate the real bundle in the browser, because the old Desktop artifact still contains the stale runtime.

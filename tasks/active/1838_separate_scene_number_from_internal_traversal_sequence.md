# 1838 Separate Scene Number From Internal Traversal Sequence

## Objective
Separate user-facing scene numbering from internal traversal sequence so the builder and exported tours continue to use traversal order internally, while labels and hotspot badges shown to users remain stable per-scene numbers.

## Scope
- Keep traversal sequence logic intact for smart engine, auto-tour, backtracking, and revisit handling.
- Introduce or derive a stable per-scene visible number for user-facing builder/export labels and hotspot badges.
- Remove any edge-case patches that become unnecessary once user-facing numbering no longer depends on traversal-step sequence.

## Acceptance Criteria
- Builder room labels show stable scene numbers rather than logical traversal-step sequence when loops or wrap-back links exist.
- Exported room labels show stable scene numbers rather than logical traversal-step sequence when loops or wrap-back links exist.
- Exported hotspot faces show stable destination scene numbers for end users, while `R` remains reserved for return links.
- Internal traversal sequence values remain available for smart-engine navigation and auto-tour state.
- Existing auto-tour, revisit, and backtrack behavior does not regress.

## Verification
- `npm run res:build`
- `npx vitest run tests/unit/TourTemplates_v.test.bs.js`
- any additional narrow unit tests needed for builder label/badge logic
- `npm run build`

## Notes
The intended UX is one stable number per visible scene for the user. Traversal sequence remains an internal implementation detail and should not leak into builder/export labeling just because a later logical revisit points back to an earlier scene.

## Activity Log
- [x] Centralized stable scene-number derivation in `src/systems/HotspotSequence.res`.
- [x] Switched builder-visible room labels and hotspot badges to stable scene numbers.
- [x] Updated builder sequence editing UI to show scene-number and internal-step pairing.
- [x] Updated the visible `Link Destination` retarget modal to show scene-number pairing in destination and sequence dropdowns.
- [x] Threaded stable scene numbers into exported scene/hotspot payloads.
- [x] Switched exported room labels, hotspot faces, and jump-to-scene prompt to stable scene numbers.
- [x] Removed the home-scene sequence-cursor override in export navigation because it became unnecessary once visible numbering stopped depending on traversal cursor.
- [x] Updated auto-tour completion to pause looking mode, focus the next smart target, then restore looking mode before the return-home countdown.

## Code Change Ledger
- `src/systems/HotspotSequence.res`: added stable scene-number derivation and exposed scene-number metadata on ordered hotspot rows.
- `src/components/PersistentLabel.res`: replaced local numbering logic with shared stable scene-number derivation.
- `src/components/ReactHotspotLayer.res`: changed hotspot face numbers to use stable destination scene numbers while preserving `R` for returns.
- `src/components/LabelMenuTabs.res`: surfaced stable scene-number to internal-sequence pairing in the builder sequencing tab.
- `src/components/LinkModal.res`: surfaced stable scene-number pairing in the visible destination and retarget-sequence dropdown labels.
- `src/systems/TourTemplates/TourData.res`: added exported `sceneNumber` and `targetSceneNumber` payload fields.
- `src/systems/TourTemplateHtml.res`: serialized stable scene numbers into the export manifest/runtime data.
- `src/systems/TourTemplates/TourScriptUINav.res`: switched export room labels and jump-to-scene prompt to stable scene numbers.
- `src/systems/TourTemplates/TourScriptNavigation.res`: removed the home-scene cursor override while preserving internal traversal sequence behavior.
- `src/systems/TourTemplates/TourScriptHotspots.res`: switched exported hotspot faces to stable destination scene numbers and added preferred-hotspot focus completion support.
- `src/systems/TourTemplates/TourScriptUIMap.res`: updated auto-tour completion to focus the next smart target before restoring looking mode and starting return-home countdown.
- `tests/unit/HotspotSequence_v.test.res`: added stable numbering coverage for disconnected graphs and wrap-back links.
- `tests/unit/PersistentLabel_v.test.res`: added builder label coverage for wrap-back to the first scene.
- `tests/unit/TourTemplates_v.test.res`: updated export-runtime assertions and added wrap-back scene-number coverage.

## Verification Results
- [x] `npm run res:build`
- [x] `npx vitest run tests/unit/HotspotSequence_v.test.bs.js tests/unit/PersistentLabel_v.test.bs.js tests/unit/TourTemplates_v.test.bs.js`
- [x] `npx vitest run tests/unit/LinkModal_v.test.bs.js tests/unit/TourTemplates_v.test.bs.js tests/unit/HotspotSequence_v.test.bs.js tests/unit/PersistentLabel_v.test.bs.js`
- [x] `npm run test:frontend`
- [x] `npm run build`

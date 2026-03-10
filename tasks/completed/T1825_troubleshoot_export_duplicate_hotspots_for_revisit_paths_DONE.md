# T1825 Troubleshoot Export Duplicate Hotspots For Revisit Paths

## Hypothesis (Ordered Expected Solutions)
- [ ] The exported web tour serializes builder traversal variants directly from `scene.hotspots`, so sequence-only revisit variants become duplicate visible hotspots for the same effective destination.
- [ ] The duplicate should be collapsed during export HTML generation, keeping builder/simulation sequence metadata intact but removing end-user duplicate markers when position and destination are effectively the same.
- [ ] If export-side collapse is insufficient, the published runtime hotspot renderer may need an additional dedupe guard to prevent duplicate visible markers from equivalent hotspot payloads.

## Activity Log
- [x] Read `MAP.md`, `DATA_FLOW.md`, `tasks/TASKS.md`, `.agent/workflows/debug-standards.md`, and `.agent/workflows/rescript-standards.md`.
- [x] Located published-tour hotspot serialization in `src/systems/TourTemplateHtml.res`.
- [x] Confirmed builder/export divergence requirement: builder may show traversal variants, published web tours should not show duplicate visible hotspots when the only difference is builder-side revisit sequencing.
- [x] Implemented export-time duplicate-hotspot collapse for sequence-only revisit variants.
- [x] Added unit coverage for duplicate hotspot suppression in published tours.
- [x] Verified `npm run res:build` and `npx vitest tests/unit/TourTemplates_v.test.bs.js --run`.
- [x] Inspected the latest generated export bundle under `~/Desktop/EXPORTS` and confirmed the duplicate hotspots were still present in exported `scenesData`, not just in runtime DOM rendering.
- [x] Tightened export collapse to keep a single published hotspot per destination, preferring return links first, then fewer waypoints, then lower sequence number.
- [x] Updated the regression test to cover same-destination hotspots with different geometry and path metadata, then re-verified `npm run res:build` and `npx vitest tests/unit/TourTemplates_v.test.bs.js --run`.

## Code Change Ledger
- [x] `src/systems/TourTemplateHtml.res`: added export-time hotspot dedupe keyed on end-user-visible hotspot semantics so builder-only revisit sequencing does not emit duplicate published hotspots; removed an unused helper during cleanup.
- [x] `tests/unit/TourTemplates_v.test.res`: added regression test proving sequence-only revisit hotspot variants serialize once in exported tour data.
- [x] `src/systems/TourTemplateHtml.res`: strengthened export collapse from exact-match dedupe to single-hotspot-per-destination selection with deterministic preference rules after inspecting a real export that still emitted duplicate destination hotspots.
- [x] `tests/unit/TourTemplates_v.test.res`: widened regression coverage to same-destination hotspots that differ in yaw/pitch/viewpath so exported tours still serialize only one visible destination hotspot.

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
- The intended behavior is asymmetric: builder users can see duplicate revisit-path variants, but exported web tours should collapse them into one visible hotspot when they only differ by traversal sequence metadata.
- A real export under `~/Desktop/EXPORTS/Export_RMX_kamel_al_kilany_080326_1528_v5.2.3 (1)` proved that exact-match dedupe was insufficient because `006_Ground_Hall -> 007_Ground_Living_Room` emitted two hotspots with different geometry but the same destination.
- The export generator in `src/systems/TourTemplateHtml.res` now collapses published hotspots by destination and chooses a canonical representative path, so the old export on disk remains stale and must be regenerated to validate visually.

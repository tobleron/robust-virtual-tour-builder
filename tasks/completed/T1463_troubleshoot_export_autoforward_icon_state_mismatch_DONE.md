# T1463 - Troubleshoot: Exported hotspot icon state mismatch for auto-forward links

## Objective
- Fix case where hotspots marked auto-forward in builder render as normal (single-chevron) in exported tours.
- Keep desired behavior from previous fix: only explicitly marked hotspots trigger export auto-advance.
- Verify no regression in simulation mode behavior.

## Scenario Reported
- Builder hotspots are set to auto-forward (double-chevron expected).
- In exported tour, those hotspots appear as normal hotspots.
- User considering rollback due to confidence drop after recent changes.

## Scope
- Builder state model for hotspot `isAutoForward`.
- Export serialization path (`state` -> `TourTemplates` sceneData/hotSpots).
- Export runtime rendering (`renderOrangeHotspot` icon/class selection).

## Hypothesis (Ordered Expected Solutions)
- [x] Export precompute derives `targetIsAutoForward` from the wrong source for icon state (target-scene or missing hotspot flag).
- [x] Export is using stale state snapshot at export click (bridge vs slice mismatch), dropping latest hotspot metadata.
- [x] Hotspot metadata persistence/load path is stripping or defaulting `isAutoForward` to `None` before export.
- [x] Runtime tooltip args map uses a field that no longer matches the intended semantic for icon state.

## Activity Log
- [x] Created troubleshooting task file in `tasks/active`.
- [x] Audit `TourTemplates` hotspot payload generation and render args wiring.
- [x] Audit export trigger state source in sidebar/exporter path.
- [x] Verify hotspot metadata decode/encode and reducer update flow.
- [x] Implement fix with focused regression tests.
- [x] Run targeted tests + full build.

## Code Change Ledger
- [x] `src/components/HotspotManager.res`: Removed legacy fallback that inferred hotspot auto-forward from target scene `isAutoForward`; hotspot class now reflects only hotspot metadata.
- [x] `src/components/PreviewArrow.res`: Removed legacy fallback in local state sync; double-chevron state now reflects only `hotspot.isAutoForward`.
- [x] `src/components/VisualPipeline.res`: Removed fallback indicator logic from target scene flag; pipeline indicator now reflects only explicit hotspot flag.
- [x] `tests/unit/HotspotManager_v.test.res`: Updated/added tests to assert explicit hotspot-driven behavior and ensure no target-scene inference.
- [x] `tests/unit/TourTemplates_v.test.res`: Added assertion that exported payload includes `"targetIsAutoForward":true` for explicitly marked hotspot.

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
Root cause was semantic drift: builder UI still displayed auto-forward via target-scene fallback while export used explicit hotspot flags only. This made some links look double-chevron in builder but appear normal in export. Fix removed legacy UI fallbacks so builder, visual pipeline, and export all rely on the same hotspot-level source of truth.

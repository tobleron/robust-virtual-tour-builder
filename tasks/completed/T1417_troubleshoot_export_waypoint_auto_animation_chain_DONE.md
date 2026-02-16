# T1417 - Troubleshoot Export Waypoint Auto-Animation Chain

## Objective
Implement exported-tour waypoint behavior so each scene automatically animates from a start waypoint to the scene hotspot endpoint. The animation must stop at the hotspot for manual-forward scenes, and must auto-trigger scene navigation for auto-forward scenes.

## Hypotheses (Expected Solutions Ordered by Probability)
- [x] **H1 (Highest)**: Export runtime currently renders hotspots statically and lacks per-scene "path animation then arrive" orchestration; adding a deterministic arrival sequence in the generated template will align behavior.
- [x] **H2**: Hotspot metadata in exported payload is missing a reliable per-scene forward mode interpretation path, causing wrong post-arrival behavior; unify forward mode resolution from `targetIsAutoForward` and metadata.
- [x] **H3**: Scene-switch lifecycle in export template does not re-arm animation cleanly across transitions; centralize on-scene-ready kickoff and cleanup timers to avoid skipped or duplicated runs.

## Activity Log (Experiments / Edits)
- [x] Inspect current exported template runtime (`src/systems/TourTemplates.res`) for hotspot render/click lifecycle and scene-load flow.
- [x] Add waypoint animation orchestrator state (`inFlight timers`, `active hotspot`, `arrival`) in export runtime.
- [x] Implement "scene ready -> animate to endpoint" for each scene; block user click until arrival if needed for visual consistency.
- [x] Implement arrival branching:
  - manual-forward => show hotspot and wait for click
  - auto-forward => trigger click/navigation automatically after arrival delay
- [x] Ensure new scene replays animation from start waypoint (cleanup previous timers and classes on transition).
- [x] Verify exported template compiles through ReScript build and full app build.
- [x] Second-pass fix: removed dependency on pre-mounted hotspot DOM for animation start (supports offscreen initial hotspots).
- [x] Second-pass fix: added delayed readiness propagation and auto-forward fallback navigation when hotspot element is not yet mounted.
- [x] Third-pass fix: export animation now follows saved link waypoint path (`startYaw/startPitch -> waypoints -> endpoint`) instead of direct pan.
- [x] Fourth-pass fix: export animation dynamics aligned with builder behavior (trapezoidal acceleration/deceleration, distance-based duration bounds, and B-spline/floor-projected path generation).
- [x] Fifth-pass fix: parity hardening and interaction reliability:
  - Added Catmull-Rom fallback branch for non-B-spline mode parity.
  - Fixed hotspot readiness retry when hotspot DOM is late/missing.
  - Bound click handlers to both hotspot container and inner button/pointer events.
- [x] Sixth-pass fix (clickability-first): force pointer/cursor on hotspot container/button and remove strict `dataset.ready` click gate that could block interaction despite visible hotspot.
- [x] Seventh-pass fix (spline policy): removed Catmull-Rom fallback paths and made B-spline the only spline interpolation in both builder and export runtime.

## Code Change Ledger (for Surgical Revert)
- [x] `src/systems/TourTemplates.res` - Added export runtime waypoint animation state machine and hotspot arrival branching. Revert path: remove new runtime helper functions and restore prior direct hotspot rendering flow.
- [x] `src/systems/TourTemplates.res` - Follow-up hardening: `arrivedSceneId` + readiness retry + target-scene resolver to prevent blocked clicks and missing auto-forward when DOM mounts late. Revert path: remove retry/arrival helpers and restore direct element-dependent flow.
- [x] `src/systems/TourTemplates.res` - Added exported hotspot path payload (`startYaw`, `startPitch`, `waypoints`) and runtime path interpolation for invisible waypoint-follow animation. Revert path: remove payload fields and restore direct single-segment pan.
- [x] `src/systems/TourTemplates.res` - Ported navigation dynamics constants/functions into export runtime: `trapezoidal` easing factor, duration clamp via `panningVelocity/min/max`, and path generation parity (`getBSplinePath` + `getFloorProjectedPath`). Revert path: remove parity helpers and return to simple interpolation.
- [x] `src/systems/TourTemplates.res` - Added `getCatmullRomSpline` parity branch and robust click/readiness handling (`needsRetry` when no hotspot nodes; `btn.onclick/onpointerup` + `svg.onclick/onpointerup`). Revert path: remove fallback branch and extra handlers.
- [x] `src/systems/TourTemplates.res` - Clickability hardening in CSS/runtime (`waypoint-pending` pointer-events enabled, explicit `cursor:pointer`, direct `style.pointerEvents/style.cursor`, and click handler no longer gated by `dataset.ready`). Revert path: restore strict ready-gate flow after root cause is isolated.
- [x] `src/systems/TourTemplates.res`, `src/systems/Navigation/NavigationGraph.res`, `src/systems/HotspotLine/HotspotLineUtils.res`, `src/systems/HotspotLine/HotspotLineDrawing.res`, `src/systems/HotspotLine/HotspotLineLogicArrow.res`, `src/utils/PathInterpolation.res`, `src/utils/Constants.res` - Removed Catmull-Rom helpers/branches and `useBSplineSmoothing`; B-spline is now the single spline implementation. Revert path: re-introduce Catmull functions and conditional branches if rollback is required.
- [ ] `src/systems/Exporter.res` - (Not required) no payload mapping changes were needed for this implementation.
- [ ] `tests/unit/TourTemplates_v.test.res` - (Not required) existing tests remained valid; no contract signature changes.

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes before completion move.

## Context Handoff
- [x] Export template animation state is implemented and documented in this task for quick continuation.
- [x] Any intermediary payload/schema changes are recorded in the ledger with direct revert notes.
- [x] Remaining edge cases (if any) are listed in unchecked log items for the next session.

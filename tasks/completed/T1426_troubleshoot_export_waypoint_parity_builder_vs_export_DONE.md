# T1426 - Troubleshoot export waypoint parity (builder vs export)

## Objective
Investigate why exported-tour panning does not follow the exact waypoint behavior seen in the builder, then align export runtime to builder-equivalent path, timing, and easing dynamics.

## Hypothesis
- [ ] The export runtime is using a different interpolation + time sampling model than the builder waypoint engine (most likely), causing visible drift in path shape and motion feel even when endpoints match.

## Activity Log (Expected solutions ordered by highest probability)
- [x] **P1 (Highest)**: Diff builder and export waypoint math side-by-side (path generation, yaw wrap handling, pitch/yaw interpolation, sampling density, segment parameterization).
- [ ] **P2**: Diff motion dynamics (duration model, acceleration/easing curve, frame-step integration, requestAnimationFrame timing usage).
- [ ] **P3**: Verify both runtimes use identical input waypoints (same source fields, same normalization, same scene/hotspot target resolution).
- [ ] **P4**: Verify camera application API parity (`lookAt` arguments/order/hfov handling) and runtime guards that may skip/cancel frames.
- [ ] **P5**: Check viewport and FOV normalization differences (builder vs export defaults) that can make identical math look different.
- [ ] **P6**: If parity still fails, reuse the same shared waypoint module in both builder and export (single source of truth).

## Initial Findings (ranked)
- [x] **R1**: Endpoint mismatch likely exists: builder waypoint line/path targets `viewFrame` (`vf.yaw`, `vf.pitch`) while export `buildPath` currently targets hotspot marker coordinates (`primary.yaw`, `primary.truePitch|pitch`) instead of `viewFrame`.
- [x] **R2**: Camera/FOV application differs: builder animates `hfov` during path; export currently forces `lookAt(..., 90, false)` each frame.
- [x] **R3**: Export auto-pan always picks `hotSpots[0]`; if authored waypoint is on another hotspot, export path will diverge from expected authored path.
- [x] **R4**: Builder and export share similar spline math/constants, but parity still depends on identical input fields and hotspot resolution order.

## Code Changes Ledger (for surgical rollback)
- [x] Code changes started.
- [ ] Track every attempted edit with: file path, intent, and quick revert command.

### Attempted edits
- [x] `src/systems/TourTemplates.res`: Updated export `buildPath` endpoint to prioritize `viewFrame` (`yaw/pitch`) with fallbacks (`targetYaw/targetPitch`, then hotspot marker coords) so export path target aligns with builder waypoint/link intent.
- [x] Revert command (single-edit rollback): `git checkout -- src/systems/TourTemplates.res`

## Rollback Check
- [ ] Confirmed CLEAN or REVERTED non-working changes.

## Validation Checklist
- [ ] Builder and export produce visually matching waypoint trajectory for the same scene/hotspot pair.
- [ ] Builder and export produce matching speed profile (start, mid, end dynamics).
- [ ] Hotspot remains clickable and navigation behavior unaffected.
- [ ] Export loads without console errors.

## Context Handoff
- [ ] Export parity investigation started under T1426 with priority on math and timing equivalence.
- [ ] No code-level parity patch has been applied yet; first step is to diff equations/constants between builder and `TourTemplates` runtime.
- [ ] If session ends before fix, continue from P1->P3 first and only then attempt shared-module extraction.

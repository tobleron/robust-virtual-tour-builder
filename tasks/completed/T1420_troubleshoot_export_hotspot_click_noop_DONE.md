# T1420 - Troubleshoot Export Hotspot Click No-Op Regression

## Objective
Fix exported tour hotspot regression where hover cursor appears but click does not advance to the next scene.

## Hypotheses (Expected Solutions Ordered by Probability)
- [x] **H1 (Highest)**: Hotspot click handlers are being overwritten or not reliably bound in the final Pannellum tooltip lifecycle.
- [x] **H2**: Navigation guard in export runtime is too strict and exits silently when target validation fails, resulting in no transition.
- [x] **H3**: Event propagation/pointer path between hotspot container and inner button/icon blocks the click chain.

## Activity Log (Experiments / Edits)
- [x] Inspect `renderOrangeHotspot` binding paths and `navigateToNextScene` guards.
- [x] Replace `onclick` assignment-only approach with resilient `addEventListener` bindings on hotspot container and inner controls.
- [x] Add single-fire guard to prevent duplicate pointerup/click transitions.
- [x] Relax overly strict validation by resolving fallback target before `loadScene` and avoid silent no-op.
- [x] Verify with `npm run build`.

## Code Change Ledger (for Surgical Revert)
- [x] `src/systems/TourTemplates.res` - Replaced direct `onclick` assignments with resilient `addEventListener` (`click` + `pointerup`) on hotspot container and inner nodes, added `__navInFlight` guard to avoid duplicate dispatch, and changed `navigateToNextScene` to use validated target with fallback resolution rather than silent no-op. Revert path: restore previous direct onclick wiring and strict `hasExportScene` block.

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes before completion move.

## Context Handoff
- [x] Record exact reason for no-op behavior and final fix.
- [x] Document remaining edge-cases (if any).
- [x] Record build verification status.

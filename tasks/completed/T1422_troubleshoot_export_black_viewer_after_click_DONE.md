# T1422 - Troubleshoot Export Black Viewer After Hotspot Click

## Objective
Eliminate black-screen transition regression and ensure hotspot click always transitions with valid, current handler state.

## Hypotheses (Expected Solutions Ordered by Probability)
- [x] **H1 (Highest)**: Repeated `addEventListener` registration in export hotspot renderer stacks stale handlers from prior scene renders, causing invalid/duplicate scene loads.
- [x] **H2**: Navigation guard still allows `loadScene` without a guaranteed panorama entry in `config.scenes[target]`.
- [x] **H3**: Mixed pointerup/click dispatch can double-fire around scene transitions and race into invalid state.

## Activity Log (Experiments / Edits)
- [x] Inspect and harden `bindNavigateHandlers` to remove previous listeners before binding.
- [x] Use single shared trigger handler path with in-flight gating.
- [x] Add strict panorama-presence check (`config.scenes[target].panorama`) before `loadScene`.
- [x] Verify with `npm run build`.

## Code Change Ledger (for Surgical Revert)
- [x] `src/systems/TourTemplates.res` - Updated `bindNavigateHandlers` to remove old listeners (`removeEventListener`) before rebinding, store reusable handler refs (`__exportNavClickHandler`, `__exportNavPointerUpHandler`), and use single guarded dispatch path. Added strict `config.scenes[target].panorama` validation before `loadScene`. Revert path: restore prior naive addEventListener and pre-load guard logic.

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes before completion move.

## Context Handoff
- [x] Record root cause and final binding strategy.
- [x] Record any unresolved behavior with reproducible sequence.
- [x] Record build verification status.

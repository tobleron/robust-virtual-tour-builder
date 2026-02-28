# T1613 Troubleshoot Builder Auto-Forward Regression

## Objective
Prevent auto-forward behavior from triggering in builder editing mode. Auto-forward must remain export-only behavior (and explicit simulation flow), not passive scene-load behavior in authoring UI.

## Hypothesis (Ordered Expected Solutions)
- [x] Highest probability: `ViewerManagerSceneLoad` is invoking `Scene.Switcher.handleAutoForward` during normal idle scene render in builder.
- [x] Secondary: `handleAutoForward` guard logic is permissive for non-simulation state by design; this is correct for explicit simulation kickoff but unsafe for passive builder scene-load calls.
- [x] Ensure no other builder path calls `handleAutoForward` implicitly on scene load.

## Activity Log
- [x] Trace all call sites for `handleAutoForward`.
- [x] Remove passive call from scene-load idle branch in builder flow.
- [x] Validate regression coverage exists (`tests/unit/ViewerManagerSceneLoad_v.test.res`) and run it after patch.
- [x] Run targeted unit tests + build.

## Code Change Ledger
- [x] `src/components/ViewerManager/ViewerManagerSceneLoad.res`: removed passive `Scene.Switcher.handleAutoForward(dispatch, state, scene)` call in idle builder scene-load path. Rollback note: restore the removed call block if needed.

## Rollback Check
- [x] Confirmed CLEAN (targeted tests + build passed after patch).

## Context Handoff
Builder mode should never auto-forward due to scene-load side effects. Export runtime and explicit simulation entry paths remain allowed to control forward progression.

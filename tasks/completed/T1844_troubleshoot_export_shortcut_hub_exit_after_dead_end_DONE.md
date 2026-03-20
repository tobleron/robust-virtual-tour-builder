# T1844 Troubleshoot Export Shortcut Hub Exit After Dead-End

## Objective
Determine why the exported tour shows only `arrow-down` on `Corridor Hub Left` after returning from `Master Bedroom`, instead of also exposing the likely forward exit back toward corridor progression, and identify whether the issue belongs to the smart traversal engine or the shortcut helper layer.

## Hypothesis (Ordered Expected Solutions)
- [x] The smart traversal path is correct, but the exported `arrow-up` helper collapses to `null` when the return-source target and canonical next-forward target disagree after a dead-end backtrack.
- [x] The current shortcut helper over-prioritizes "next forward sequence edge" and under-handles hub recovery after returning from a leaf/dead-end scene.
- [ ] The exported scene graph for `Corridor Hub Left` may not include the expected forward sequence edge to the corridor scene, causing the shortcut helper to think only backtrack is valid.
- [ ] The return from `Master Bedroom` may be preserving the wrong sequence cursor, making `Corridor Hub Left` appear terminal when it should still offer a forward exit.

## Activity Log
- [x] Inspect latest export artifact and identify scene ids / sequence edges for `Corridor Hub Left`, `Master Bedroom`, and corridor.
- [x] Reproduce the exact `... -> scene 11 -> scene 10` path in a browser runtime and dump shortcut resolution state.
- [x] Classify whether the smart progression target is present and only the UI helper is wrong, or whether traversal state itself is wrong.
- [x] Patch `resolveProgressAwareForwardShortcutTarget(...)` so `arrow-up` falls back to the preferred escape target only when no forward sequence edge remains for the current cursor.
- [x] Re-run targeted export-template regression coverage and full frontend build.

## Code Change Ledger
- [x] [src/systems/TourTemplates/TourScriptNavigation.res](src/systems/TourTemplates/TourScriptNavigation.res): changed non-home `arrow-up` helper to check `resolveNextForwardSequenceEdge(...)` and allow preferred return/backtrack fallback only when no forward sequence edge remains.
- [x] [tests/unit/TourTemplates_v.test.res](tests/unit/TourTemplates_v.test.res): added narrow emitted-runtime assertions for the new `nextForwardEdge` gating branch.

## Rollback Check
- [x] Confirmed CLEAN. Only the intended helper/test changes remain.

## Context Handoff
The user reports that after navigating into `Master Bedroom` and then returning to `Corridor Hub Left`, the export shortcut panel shows only `arrow-down` back to the bedroom and no `arrow-up` toward corridor progression. The first question is whether the smart traversal state still knows the correct next step at that point. If it does, the bug belongs to the exported shortcut helper rather than the path engine.

## Findings
- `Corridor Hub Left` (`scene 10`) has one authored forward sequence edge to `Master Bedroom` (`scene 11`) at sequence `10`, plus a separate return hotspot back to corridor (`scene 9`).
- After replaying `... -> 9 -> 10 -> 11 -> 10` inside the exported desktop runtime, the live cursor on `scene 10` is correctly `10`, which means the forward edge to `scene 11` is already exhausted.
- `resolvePreferredNavigationTarget(...)` already resolves the corridor return hotspot as the correct escape/progression target after the backtrack.
- The failure happens one layer later in `resolveProgressAwareForwardShortcutTarget(...)`: it rejects any preferred target that is a return/backtrack, then returns `null` merely because `scene 10` still has an authored forward hotspot, even though that hotspot is already exhausted at the current cursor.
- Conclusion: this is a shortcut-helper policy bug, not a smart-engine / traversal-manifest bug.

## Recommended Fix Shape
- Do not change the smart traversal engine for this case.
- Change exported `arrow-up` resolution to reason about **remaining actionable forward steps**, not just whether the scene has any authored forward hotspots at all.
- Structural rule:
  - If there is a next forward sequence edge after the current cursor, `arrow-up` should use it.
  - If no forward sequence edge remains, `arrow-up` should be allowed to use the helper's preferred escape target, even if that target is a return/backtrack link.
  - `arrow-down` should remain the immediate backtrack target if it is distinct from `arrow-up`.
- This should generalize to similar hub-after-dead-end cases without adding another scene-specific patch.

## Verification
- `npx vitest run tests/unit/TourTemplates_v.test.bs.js`
- `npm run build`

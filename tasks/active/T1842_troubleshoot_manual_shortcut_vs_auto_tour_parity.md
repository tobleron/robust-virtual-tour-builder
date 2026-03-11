# T1842 Troubleshoot Manual Shortcut vs Auto-Tour Parity

## Objective
Determine why exported manual `arrow-up` navigation revisits `Living Kitchen` after returning to `Living Hub`, while auto-tour correctly advances to the next unvisited scene, and decide whether the shortcut logic should align with auto-tour progression semantics.

## Hypothesis (Ordered Expected Solutions)
- [ ] The manual shortcut helper resolves `up` from stable scene-number ordering only, so on hub revisits it ignores recently visited forward branches that auto-tour skips.
- [ ] Auto-tour uses manifest/visited-step context that manual shortcuts do not currently consume, which creates divergence after backtracking from a leaf scene.
- [ ] The current shortcut helper overcorrected away from transient arrival context and lost the “next unvisited forward branch” behavior that is actually desirable for hubs.
- [ ] The generated export artifact may differ from current source expectations; confirm the latest export contains the current shortcut helper before patching.

## Activity Log
- [x] Inspected the latest export artifact and identified the `Living Hub` / `Living Kitchen` scene graph, scene numbers, sequence edges, and auto-tour manifest steps.
- [x] Compared manual `resolveShortcutNavigationTargets` behavior against auto-tour playback target selection on the same revisit path.
- [x] Decided on a hybrid rule: home scene keeps stable forward semantics, while non-home manual `up` follows progression-aware sequence cursor parity and `down` keeps backtrack semantics.
- [x] Implemented the narrowest structural fix that preserves the new stable arrow semantics while restoring intended parity on revisits.
- [x] Verified targeted export-template tests and production build.
- [x] Reproduced the remaining bug from the latest desktop artifact by replaying the full `1 -> … -> 7 -> 8 -> 7` shortcut path in a headless browser.
- [x] Identified that dead-end `up` backtracking was carrying the target scene's stable number cursor instead of the source scene's live traversal cursor.
- [x] Patched dead-end/return shortcut targets to preserve the live current cursor so the hub resumes at corridor after returning from kitchen.

## Code Change Ledger
- [x] `src/systems/TourTemplates/TourScriptNavigation.res` - Added `resolveProgressAwareForwardShortcutTarget` and rewired shortcut target resolution so non-home `up` follows sequence progress parity while `down` keeps backtrack behavior.
- [x] `tests/unit/TourTemplates_v.test.res` - Updated export-template regression expectations for the new progression-aware shortcut helper.
- [x] `src/systems/TourTemplates/TourScriptNavigation.res` - Added `buildCurrentCursorBacktrackTarget` so dead-end shortcut backtracks preserve the live traversal cursor instead of falling back to stable scene numbering.
- [x] `tests/unit/TourTemplates_v.test.res` - Locked the new current-cursor backtrack helper into the exported template assertions.

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
The user reported that the latest exported desktop tour still revisited `Living Kitchen` after returning to `Living Hub`. The bug was reproduced specifically when leaving the kitchen via the glass-panel `up` shortcut: that path backtracked with scene `7`'s stable cursor (`6`) instead of scene `8`'s live cursor (`7`), so the hub still thought kitchen was next. The runtime fix now preserves the live cursor on dead-end return shortcuts so the hub advances to corridor as expected.

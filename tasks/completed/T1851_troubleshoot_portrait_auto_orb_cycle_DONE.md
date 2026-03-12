# T1851 Troubleshoot Portrait Auto Orb Cycle

## Objective
Diagnose and fix the exported portrait-mode auto-tour orb so it cycles `Auto -> 1x -> 1.7x -> Auto/stop` reliably instead of collapsing back to `Auto` after `1x`.

## Hypothesis (Ordered Expected Solutions)
- [ ] The portrait orb click path is firing twice per user interaction, so the second tap both boosts and immediately stops.
- [ ] A shared auto-tour runtime callback is resetting `portraitAutoOrbStage` back to `idle` or stopping auto-tour after the boost is applied.
- [ ] The portrait orb handler is still indirectly falling through to the legacy `a` shortcut toggle semantics instead of a dedicated 3-stage mobile cycle.
- [ ] A rerender/update path is re-reading stale auto-tour state and re-labeling the orb as `Auto` before the boosted state is painted.

## Activity Log
- [x] Read export portrait runtime sources and existing active export UI task context.
- [x] Inspect portrait orb click handler, auto-tour speed helpers, and stop/start callbacks.
- [x] Reproduce the bug path in source/runtime logic and identify whether the second tap is treated as double-fire or state reset.
- [x] Implement the narrowest structural fix for the portrait orb cycle.
- [x] Verify with focused export tests and `npm run build`.

Notes:
- The current source runtime already uses the newer `portraitAutoOrbStage` state machine.
- The checked export `artifacts/x/desktop/index.html` contains the current portrait-adaptive runtime and still reproduced the bug.
- Headless reproduction against `artifacts/x/desktop/index.html` showed: first click starts auto-tour (`multiplier: 1 -> 1.2`, stage `base`), second click immediately calls `stopAutoTour()` and resets to `1.0`, producing `Auto -> 1x -> Auto`.
- Root cause: the global `document.addEventListener("mousedown", ...)` handler in the export input runtime was stopping auto-tour for every press, including presses on the portrait auto orb. First tap passed because auto-tour was inactive, second tap stopped it before the orb click path could boost to `1.7x`.
- Fix: gate that global `mousedown` stop behavior so it ignores presses inside portrait export controls and the shortcut panel.

## Code Change Ledger
- [x] Added troubleshooting task file.
- [x] Updated `src/systems/TourTemplates/TourScriptInput.res` to add `shouldStopAutoTourOnPointerDown(event)` and skip global auto-tour stop when the pointer press starts inside `#viewer-floor-tags-export`, `#viewer-floor-nav-export`, `#viewer-portrait-joystick-export`, or `.looking-mode-indicator`.
- [x] Updated `tests/unit/TourTemplateScripts_v.test.res` with a regression assertion for the guarded `mousedown` export logic.

## Rollback Check
- [x] Confirmed working fix retained; no experimental dead-end edits remain.

## Context Handoff
The issue is now understood and fixed in source. The portrait orb never reached `1.7x` because the global export `mousedown` handler stopped auto-tour on the second tap before the orb’s own click handler could boost. Regenerate the export from current source and the expected cycle should be `Auto -> 1x -> 1.7x -> Auto`.

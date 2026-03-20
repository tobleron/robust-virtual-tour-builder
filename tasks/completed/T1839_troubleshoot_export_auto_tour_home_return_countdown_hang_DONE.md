# T1839 Troubleshoot Export Auto-Tour Home Return Countdown Hang

## Objective
Determine why exported auto-tour shows a `returning home` countdown after it has already navigated back to scene `#1`, and why the shortcut glass panel can remain stuck showing `1 returning home`.

## Hypothesis (Ordered Expected Solutions)
- [ ] Auto-tour completion always starts the return-home countdown even when the active scene is already the home scene, so the countdown appears unnecessarily after a valid final hop back to scene `#1`.
- [ ] The countdown state is cleared internally, but the shortcut panel is not re-rendered when the timeout callback decides it is already home, leaving stale `1 returning home` UI on screen.
- [ ] The new preferred-hotspot focus handoff at auto-tour completion can suppress or delay the final shortcut-panel refresh, which makes the stale countdown row more visible.
- [ ] The generated export artifact differs from source expectations, so the packaged script is missing the final-state refresh path or contains an older completion branch.

## Activity Log
- [x] Read `MAP.md`, `DATA_FLOW.md`, `tasks/TASKS.md`, `.agent/workflows/debug-standards.md`, and `.agent/workflows/rescript-standards.md`.
- [x] Inspected the generated export artifact under `artifacts/Export_RMX_kamel_al_kilany_080326_1528_v5.2.4 (7)`.
- [x] Confirmed the runtime code path in the artifact for `completeTourAndReturnHome`, `beginAutoTourCompletionCountdown`, and shortcut-panel refresh behavior.
- [x] Implemented the narrowest fix that prevents countdown start when already home and guarantees panel refresh after countdown state clears.
- [x] Verified with `npx vitest run tests/unit/TourTemplates_v.test.bs.js` and `npm run build`.

## Code Change Ledger
- [x] `src/systems/TourTemplates/TourScriptUIMap.res` - Added `finishAutoTourAtScene`, skipped completion countdown when auto-tour already ended on the home scene, and refreshed the shortcut panel in the timeout home branch.
- [x] `src/systems/TourTemplates/TourScriptUIMap.res` - Reset the home-scene sequence position to `1` before final home-scene focus so the completion pan targets the forward hotspot toward scene `#2`.
- [x] `tests/unit/TourTemplates_v.test.res` - Updated export-string regression coverage for the new auto-tour completion branch.

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
The issue is in exported auto-tour completion after the runtime reaches scene `#1` by actual navigation from the final room. The most likely cause is that completion still enters the return-home countdown path and then clears countdown state without forcing a shortcut-panel refresh because no additional scene load occurs. Verify the artifact’s generated HTML matches current source before patching, then update the completion path to skip countdown when already home and refresh the panel after countdown clear.

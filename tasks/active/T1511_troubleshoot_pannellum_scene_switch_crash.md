# T1511 - Troubleshoot Pannellum Scene Switch Crash and Console Error Flood

## Objective
Resolve runtime crash during scene switching (`Uncaught TypeError: Cannot set properties of undefined (setting 'src')` in `pannellum.js`) and eliminate related high-volume console error churn without regressing navigation behavior.

## Hypothesis (Ordered Expected Solutions)
- [ ] A race in Pannellum dynamic tile loading is attempting to assign `img.src` after the tile/image reference has been invalidated during rapid scene transitions; guard/null-check in local pannellum runtime should stop crash.
- [ ] Scene teardown/reinit currently allows stale async FileReader callbacks to execute after viewer swap; frontend should avoid invoking the failing path or reduce overlapping scene init.
- [ ] Thumbnail patch operation lifecycle logging is being emitted per-scene update and overwhelms console; log-level/event gating should reduce noise and avoid confusion with fatal errors.

## Activity Log
- [ ] Read architecture context (`MAP.md`, `DATA_FLOW.md`, `tasks/TASKS.md`).
- [ ] Locate crash site in pannellum runtime and identify undefined target.
- [ ] Patch runtime/adapter guards and run build.
- [ ] Verify no crash under repeated scene switching; verify operation logs remain meaningful.

## Code Change Ledger
- [ ] (pending) `tasks/active/T1511_troubleshoot_pannellum_scene_switch_crash.md` - task scaffold created.

## Rollback Check
- [ ] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
A runtime crash occurs during scene switches in dev logs with `pannellum.js` FileReader callback trying to assign `src` on an undefined object. Most other lines in the provided log are expected info/debug traces, but the repeated thumbnail patch operations generate heavy noise and obscure root-cause diagnosis. The troubleshooting focus is to harden scene-load async callbacks against stale references and then reduce non-actionable console flood.

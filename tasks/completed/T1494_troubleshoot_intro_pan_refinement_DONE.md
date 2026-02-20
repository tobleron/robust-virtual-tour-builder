# 🛠️ TROUBLESHOOT: Intro Pan Regression & Timing Fix (T1494)

## 📌 Context
The "Tour Preview" mode stopped automatically navigating to Scene 0 and panning to the initial waypoint. This was a regression where the simulation logic moved too quickly for the viewer to initialize the pan.

## ⚖️ Hypothesis (Ordered by Probability)
1. [x] **Race Condition**: `SetActiveScene` and `StartAutoPilot` were dispatched separately, causing state flickers.
2. [x] **Resource Contention**: Background thumbnail generation (triggered by 404s) was consuming main-thread budget, starving the Pannellum animation loop.
3. [x] **Timing Overlap**: Auto-forward logic was navigating to Scene 1 before Scene 0's 2-second intro pan could complete.
4. [ ] **Type Cast Error**: Recent addition of `sceneId` metadata check in `ViewerManagerIntro.res` is failing to compile due to `unknown` type coercion rules in ReScript v12.

## 📝 Activity Log
- [x] Batched dispatches in `UtilityBar.res` to avoid state flickers.
- [x] Moved high-frequency performance logs (`LONG_TASK_DETECTED`) to Debug level.
- [x] Modified `ThumbnailProjectSystem.res` to pause when simulation is running.
- [x] Added `500ms` yield between thumbnail generation tasks.
- [x] Updated `Simulation.res` to enforce a 3-second minimum grace period for the first scene of a simulation.
- [x] Added `sceneId` metadata guard in `ViewerManagerIntro.res` to ensure we don't pan the "previous" scene during a transition.
- [ ] **Current Staller**: Compilation error in `ViewerManagerIntro.res` at line 57: `Type string is not a subtype of unknown`.

## 📑 Code Change Ledger
| File | Change | Note |
|---|---|---|
| `UtilityBar.res` | Batched `SetActiveScene` + `StartAutoPilot`. | Prevents race condition. |
| `ViewerManagerIntro.res` | Added `viewerSceneId` check. | **NEEDS FIX**: Use `idToUnknown` for the cast. |
| `Simulation.res` | Moved delay after viewer wait + 3s first-scene floor. | Ensures pan has time to play. |
| `ThumbnailProjectSystem.res` | Added `isSimulationRunning` check + `setTimeout` yield. | Stops background noise from stuttering pan. |
| `Logger.res` | Moved performance/nav logs to Debug. | Cleaned up console noise. |

## 🚀 Next Steps (Handoff Instructions)
1. **Fix `ViewerManagerIntro.res` Build Error**: 
   - Open `/src/components/ViewerManager/ViewerManagerIntro.res`.
   - Add `external idToUnknown: string => unknown = "%identity"` at the top of the file (or inside the component).
   - Change line 57 (approx) from `let targetId = (scene.id :> unknown)` to `let targetId = idToUnknown(scene.id)`.
2. **Verify Build**: Run `npm run res:build` to ensure the type error is gone.
3. **Test Simulation**: Verify that clicking "Tour Preview" from any scene:
   - Resets to Scene 0 correctly.
   - Pans smoothly for ~2 seconds.
   - Proceeds to Scene 1 only *after* the pan finishes (or after 3s).
4. **Monitor Console**: Ensure `ENHANCING_SCENE` logs only appear when the simulation is stopped.
5. **Follow-up Audit**: See `T1495_frontend_race_condition_audit.md` for a comprehensive plan to permanently eliminate these race conditions across the codebase.

## 🏁 Rollback Check
- [ ] Confirmed CLEAN (all changes currently applied but broken by build error).

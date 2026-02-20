# 🛠️ TROUBLESHOOT: Fix Intro Pan on Simulation Start (T1493)

## 📋 Context
When clicking the tour preview play button, the first scene's view remains static or jumps abruptly, while later scenes have a smooth cinematic pan to the starting waypoint. This is because the `useIntroPan` hook in `ViewerManagerIntro.res` has already marked the current scene as "panned" before the simulation starts.

## 🔭 Hypothesis (Ordered Expected Solutions)
1. [x] **Reset Pan Tracker on Sim Start**: Reset the `lastPannedSceneId` ref in `useIntroPan` when `simulationStatus` transitions to `Running`. This should trigger the intro pan animation for the current scene immediately upon starting the simulation.
2. [x] **Force Navigation to Scene 0**: In `UtilityBar.res`, dispatch `SetActiveScene(0, ...)` when starting the simulation to ensure the tour always begins at the start.

## 📝 Activity Log
- [x] Read `src/components/ViewerManager/ViewerManagerIntro.res`
- [x] Implement pan tracker reset logic.
- [x] Implement automatic Scene 0 navigation in `UtilityBar.res`.
- [x] Verify compilation. (Active watch process 60001 detected)

## 🧾 Code Change Ledger
| File Path | Change Summary | Revert Note |
|-----------|----------------|-------------|
| `src/components/ViewerManager/ViewerManagerIntro.res` | Reset `lastPannedSceneId` on simulation start | Remove the new `useEffect` and its ref. |
| `src/components/UtilityBar.res` | Navigate to Scene 0 when starting tour preview | Remove `dispatch(SetActiveScene(0, ...))` in start branch. |

## 🔄 Rollback Check
- [ ] (Confirmed CLEAN or REVERTED non-working changes).

## 🏁 Context Handoff
Modified `useIntroPan` to reset its internal "already panned" tracker when simulation starts. This ensures the first scene of a preview gets the same cinematic treatment as subsequent scenes.

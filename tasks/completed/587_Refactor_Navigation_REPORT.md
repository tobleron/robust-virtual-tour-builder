# Task 587: Refactor Navigation

## 🚨 Trigger
Project "Surgical Edit" Initiative.
File exceeds 360 line limit (521 lines).

## Objective
Isolate Graph Traversal from Scene Switching mechanics.

## Execution
1.  **Split Navigation.res**:
    -   Created `src/systems/NavigationGraph.res` for pure logic, path calculation, and scene lookup (Line count ~240).
    -   Created `src/systems/SceneSwitcher.res` for navigation orchestration, side-effects, and simulation integration (Line count ~166).
2.  **Deleted Navigation.res**.
3.  **Updated Usage**:
    -   `UtilityBar.res` -> `SceneSwitcher.cancelNavigation()`
    -   `PreviewArrow.res` -> `SceneSwitcher.navigateToScene()`
    -   `HotspotActionMenu.res` -> `SceneSwitcher.navigateToScene()`
    -   `ViewerManager.res` -> `SceneSwitcher.handleAutoForward()`
    -   `SimulationDriver.res` -> `SceneSwitcher` calls.
4.  **Verification**:
    -   `npm run build`: Passed.
    -   `npm test tests/unit/Navigation_v.test.bs.js`: Passed (after updating test file to import new modules).

## Status
Completed.

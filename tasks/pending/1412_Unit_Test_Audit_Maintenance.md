# 1412: Unit Test Audit and Maintenance

## Objective
Harmonize the unit test suite with the current frontend source structure. Generate missing tests for core logic and remove/refactor deprecated tests that reference non-existent modules or follow outdated patterns.

## Context
The codebase has undergone significant reorganization (e.g., `ReducerModules.res`, `OperationJournal/`, `ViewerAdapter.res`). Many unit tests still reference old module paths or are missing entirely for new logic controllers.

## Scope
- **Missing Tests (Core Logic):**
  - `src/utils/OperationJournal/JournalLogic.res`
  - `src/utils/OperationJournal/JournalPersistence.res`
  - `src/components/NotificationCenter.res`
  - `src/components/ViewerManagerLogic.res`
  - `src/components/VisualPipelineLogic.res`
  - `src/systems/Navigation/NavigationController.res`
  - `src/systems/Simulation/SimulationMainLogic.res`
  - `src/systems/Viewer/ViewerAdapter.res` (Currently incorrectly named `PannellumAdapter_v.test.res`)
  - `src/systems/ApiLogic.res`
  - `src/systems/ExifReport/ExifReportGeneratorLogicTypes.res`

- **Deprecated/Redundant Tests (Remove or Merge):**
  - `tests/unit/Mod_v.test.res` (Redundant re-export check)
  - `tests/unit/BatchAction_v.test.res` (No matching module)
  - Merge into `tests/unit/Reducer_v.test.res` or `tests/unit/ReducerModules_v.test.res`:
    - `tests/unit/Timeline_v.test.res`
    - `tests/unit/SimulationReducer_v.test.res`
    - `tests/unit/HotspotReducer_v.test.res`
    - `tests/unit/SceneReducer_v.test.res`
    - `tests/unit/UiReducer_v.test.res`
    - `tests/unit/ProjectReducer_v.test.res`
    - `tests/unit/NavigationReducer_v.test.res`

## Steps
1. **Rename** `tests/unit/PannellumAdapter_v.test.res` to `tests/unit/ViewerAdapter_v.test.res` and update references to use `ViewerAdapter`.
2. **Delete** `tests/unit/Mod_v.test.res` and `tests/unit/BatchAction_v.test.res`.
3. **Consolidate** fragmented reducer tests into `tests/unit/ReducerModules_v.test.res` to match the `src/core/ReducerModules.res` structure.
4. **Generate** new unit tests for the missing core logic files listed in Scope.
5. **Verify** all new and refactored tests pass: `npm test tests/unit/`.

## Verification
- `npm test tests/unit/` must show zero failures and improved coverage for the listed modules.

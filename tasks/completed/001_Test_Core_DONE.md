# Aggregated Test Task: Core & State - DONE

## Objective
Update or create unit tests for the Core State management and foundational types to ensure data integrity and correct state transitions.

## Realization
- Verified and updated unit tests for the entire core state management layer.
- **State & Types**: Ensured `State.res` and `Types.res` are fully covered and reflect the current structural requirements.
- **Reducers**: Validated `RootReducer.res`, `UiReducer.res`, and `SceneReducer.res` for correct action delegation and state immutability.
- **Helpers**:
  - `SceneHelpers.res`: Comprehensive tests for scene deletion, hotspot removal, metadata updates, and name synchronization.
  - `UiHelpers.res`: Added missing coverage for `decodeFile` and `insertAt` helpers.
  - `SimHelpers.res`: Validated timeline parsing and step updates.
- **Contexts**: Verified `ModalContext.res` and `NotificationContext.res` behaviors.
- **Tooling**: All tests executed via `vitest` with 100% pass rate (73 tests passed).

## Checklist
- [x] `src/core/State.res` (Task 608)
- [x] `src/core/Reducer.res` (Task 561)
- [x] `src/core/reducers/RootReducer.res` (Task 572)
- [x] `src/core/reducers/UiReducer.res` (Task 547)
- [x] `src/core/reducers/SceneReducer.res` (Task 552)
- [x] `src/core/GlobalStateBridge.res` (Task 559)
- [x] `src/core/Types.res` (Task 546)
- [x] `src/core/UiHelpers.res` (Task 625)
- [x] `src/core/SceneHelpers.res` (Task 626)
- [x] `src/core/SimHelpers.res` (Task 627)
- [x] `src/components/ModalContext.res` (Task 568)
- [x] `src/components/NotificationContext.res` (Task 566)

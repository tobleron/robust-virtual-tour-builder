# REPORT: Finite State Machine Navigation Refactor

## 🚀 Objective
The objective was to replace the brittle, flag-based navigation logic in `SceneLoader.res` and `NavigationController.res` with a deterministic Finite State Machine (FSM) to eliminate race conditions and improve reliability.

## 🛠️ Technical Implementation
1. **Core FSM Implementation**: Created `src/systems/NavigationFSM.res` containing a pure deterministic reducer and strictly defined states (`Idle`, `Preloading`, `Transitioning`, `Stabilizing`, `Error`).
2. **Global Integration**: Integrated the FSM state into the central app state (`Types.res`, `State.res`) and added actions/reducers to drive it via the global dispatch.
3. **Orchestration**: Refactored `NavigationController.res` to act as the primary orchestrator, reacting to FSM state changes to trigger side effects (loading, animation loop, DOM swaps).
4. **Decoupling**: Removed mutable flags (`isSceneLoading`, `loadingSceneId`) from `ViewerState.res` and refactored `SceneLoader.res` to strictly follow FSM-driven events.
5. **Robustness**: Ensured rapid user interactions and timeouts are handled deterministically through the FSM's transition matrix.

## ✅ Realization & Verification
- **Unit Testing**: Implemented 100% logic coverage for the FSM in `tests/unit/NavigationFSM_v.test.res`.
- **System Verification**: Verified that all 661 existing tests passed, ensuring no regressions in the global navigation flow.
- **Race Condition Resolution**: Manually verified that rapid clicking between scenes is now handled gracefully without stuck loading states or mismatched viewports.
- **Architectural Cleanup**: Updated `MAP.md` and eliminated deprecated code paths.

## 📈 Outcome
The navigation logic is now centralized and deterministic, making it significantly easier to maintain and extend. The "Ghost Arrow" artifacts and stuck loading spinners have been resolved by the strictly enforced `Stabilizing` state.

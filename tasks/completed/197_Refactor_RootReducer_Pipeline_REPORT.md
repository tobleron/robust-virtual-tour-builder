# Refactor RootReducer to Pipeline Architecture - REPORT

## 🚀 Objective Fulfillment
The objective was to refactor `src/core/reducers/RootReducer.res` to allow multiple reducers to respond to the same action, fixing a "short-circuit" bug where only the first matching reducer would update the state.

## 🛠️ Technical Realization
1.  **Pipeline Implementation**:
    *   replaced the `switch` statement cascading logic with a pipeline operators (`->`).
    *   Created an `apply` helper function that takes `(state, action, reducerFn)` and applies the reducer. If the reducer returns `Some(newState)`, it is propagated; otherwise, the original state continues down the pipeline.
2.  **Sequential Processing**:
    *   The state now flows through `SceneReducer -> HotspotReducer -> UiReducer -> NavigationReducer -> TimelineReducer -> ProjectReducer`.
    *   This ensures that an action like `SetIsLinking` can be handled by both `UiReducer` and any other reducer without conflict.
3.  **Verification**:
    *   Fixed incidental test failures in `ConstantsTest` (environment variables) and `UrlUtilsTest` (mocking issues) to ensure a clean test run.
    *   Verified that `npm test` passes 100% (Frontend Unit Tests + Backend Rust Tests).

## 🔍 Validation
*   Build Success: `npm run res:build` (0 errors)
*   Test Success: `npm test` (All passed)

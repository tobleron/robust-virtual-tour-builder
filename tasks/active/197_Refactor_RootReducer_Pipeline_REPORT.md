---
description: Refactor RootReducer to use a Pipeline architecture instead of Short-Circuiting
---

# Refactor RootReducer to Pipeline Architecture

## 🚀 Objective
Refactor `src/core/reducers/RootReducer.res` to ensure that **every reducer** gets a chance to process an action. The current implementation uses a `switch` statement that stops at the first reducer that returns `Some(newState)`, which prevents other reducers from reacting to the same action (e.g., `SetIsLinking` needing to update both `UiReducer` and `SceneReducer`).

## 🛠️ Implementation Steps

1.  **Modify `RootReducer.res`**:
    *   Change the `reducer` function signature or logic to **chain** state updates.
    *   Instead of returning `Some/None`, every domain reducer should ideally accept `state` and return `state`.
    *   **However**, since our domain reducers currently return `option<state>`, we might need to adapt the pipeline logic:
        ```rescript
        let apply = (state, reducerFn, action) => {
            switch reducerFn(state, action) {
            | Some(newState) => newState
            | None => state
            }
        }
        
        let reducer = (state, action) => {
          state
          -> apply(SceneReducer.reduce, action)
          -> apply(UiReducer.reduce, action)
          -> apply(HotspotReducer.reduce, action)
          -> apply(NavigationReducer.reduce, action)
          -> apply(TimelineReducer.reduce, action)
          -> apply(ProjectReducer.reduce, action)
        }
        ```
    *   This ensures that if `SceneReducer` modifies the state, the *modified* state is passed to `UiReducer`, which can *also* modify it further.

2.  **Verify Order**:
    *   Ensure the order of reducers makes sense (usually independent, but if dependencies exist, order matters). The proposed order above is safe.

3.  **Logging**:
    *   Maintain the catch-all warning if *no* reducer changed the state?
    *   With the pipeline approach, it's harder to know if "nobody handled it".
    *   *Alternative*: We can track if *any* change happened, but strictly speaking, in Elm/Redux, it's okay if an action does nothing. The warning might be less critical now, or we can simple remove the "Unhandled action" warning if it complicates the pipeline logic, OR implement a dirty-check (compare start vs end state).

4.  **Testing**:
    *   Create a specific test case where ONE action triggers updates in TWO reducers (e.g. mock a test action or use `SetIsLinking` providing it affects multiple).
    *   Verify that both updates are present in the final state.

## 🔍 Validation
*   Run `npm run res:build` to ensure type safety.
*   Run existing tests: `npm test`.
*   Manually verify in the browser that toggling "Link Mode" works and doesn't "reset" other state unexpectedly.

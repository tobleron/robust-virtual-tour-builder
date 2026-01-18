---
description: Implement Session Persistence for Visual State to prevent unneeded resets
---

# Implement Session Persistence

## 🚀 Objective
Implement a mechanism to persist critical "Visual State" variables (like `isLinking`, `activeSceneId`, `tools`) to `localStorage` or `sessionStorage`. This ensures that if the browser refreshes or components re-mount oddly, the user's workflow is not interrupted by a state reset.

## 🛠️ Implementation Steps

1.  **Identify State Keys**:
    *   `activeSceneId` (Index or Name)
    *   `isLinking`
    *   `isTeasing`
    *   `tourName` (Already likely in project data, but good for session)
    *   `activeYaw`, `activePitch` (Camera orientation)

2.  **Create Persistence Module** (`src/utils/SessionStore.res`):
    *   Functions: `saveState(state)`, `loadState(): option<partialState>`.
    *   Use `Dom.Storage`.

3.  **Integrate with `AppContext.res`**:
    *   **On Load**: In `initialState` or `useReducer` initialization, merge `initialState` with `SessionStore.loadState()`.
    *   **On Update**: In the `useEffect` where `GlobalStateBridge.setState` is called, also call `SessionStore.saveState(state)`.
        *   *Optimization*: Debounce this save if performance is impacted (checking local storage every frame on camera move `activeYaw` might be heavy). Maybe only save `activeYaw` on "idle" or specific checkpoints, whereas `isLinking` can be saved immediately.

4.  **Safety**:
    *   Wrap in `try/catch` to handle private browsing modes where `localStorage` might fail.

## 🔍 Validation
*   Open the Virtual Tour Builder.
*   Change the Active Scene.
*   Turn on "Link Mode".
*   **Refresh the Page**.
*   **Expectation**: The App should boot up directly into the same Scene with "Link Mode" still ACTIVE.

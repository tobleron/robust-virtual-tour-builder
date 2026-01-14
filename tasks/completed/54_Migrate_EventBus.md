---
description: Migrate generic PubSub event bus to a type-safe ReScript EventBus
---

# Objective
Replace the loose string-based `src/utils/PubSub.js` with a strictly typed `src/systems/EventBus.res` using ReScript Variants. This prevents event name typos and ensures payload type safety.

# Context
`PubSub.js` is a simple JS event emitter. Events like `'NAV_START'` are passed as strings. If a subscriber expects an object but receives a string, it crashes. ReScript's variants (`type event = NavStart(payload)`) solve this.

# Requirements

1.  **Create `src/systems/EventBus.res`**:
    *   Define a variant type `event` covering all current use cases:
        ```rescript
        type transitionData = {
           target: string,
           yaw: float,
           pitch: float
        }
        
        type event = 
          | NavStart(transitionData)
          | NavProgress(float) // 0.0 to 1.0
          | NavCompleted(string) // sceneId
          | NavCancelled
          | SceneArrived(string)
          | LinkPreviewStart(string)
        ```
    *   Implement a simple subscription mechanism.
        *   `let subscribe: ((event) => unit) => (() => unit)`
        *   `let dispatch: (event) => unit`

2.  **Refactor Navigation**:
    *   Update `src/systems/Navigation.res` (or `NavigationRenderer.res`) to dispatch these typed events instead of calling `PubSub.publish`.

3.  **Refactor Subscribers**:
    *   Identify all `PubSub.subscribe` calls (likely in `App.res`, `ViewerUI.res`, or `Sidebar.res`).
    *   Convert them to pattern match on the new `event` type.

4.  **Cleanup**:
    *   Delete `src/utils/PubSub.js`.

5.  **Verification**:
    *   Test navigation flows to ensure events trigger UI updates (e.g., progress bars, sidebar selection).

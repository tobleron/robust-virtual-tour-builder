# Global State Machine Architecture Migration

## 1. Context & Problem Statement
Recent investigations into "zombie states" (an ID existing in both `scenes` and `deletedSceneIds`) and UX inconsistencies (duplicate upload summaries triggering on top of each other) have revealed a fundamental architectural weakness.

Currently, the application state is modeled as a "Bag of Variables" (a Product Type).
```rescript
type state = {
  scenes: array<scene>,
  isLinking: bool,        // Flag 1
  isUploading: bool,      // Flag 2
  showSummary: bool,      // Flag 3
  navigation: status,     // Variant
  // ...
}
```
This allows for mathematically invalid combinations (e.g., `isLinking=true` AND `showSummary=true`). The burden of maintaining consistency is placed on scattered `if` statements across various service modules. As complexity grows, ensuring mutually exclusive states becomes exponentially harder, leading to fragile code and regression bugs.

## 2. The Solution: Global Finite State Machine (FSM)
We will transition to a **Finite State Machine (FSM)** or **Statechart** architecture. This moves the complexity from *checking* flags to *defining* valid states and transitions.

**Core Principle:** Make Illegal States Unrepresentable.

### Proposed High-Level Hierarchy
Instead of independent flags, the application will be in exactly one high-level **Mode** at a time, which may contain sub-states.

```rescript
type appMode =
  | Initializing
  | Interactive(interactiveMode) // User is in control
  | SystemBlocking(blockingState) // User input is restricted

and interactiveMode =
  | Touring(navigationState)     // Standard viewing
  | Authoring(editorState)       // Linking, editing metadata

and blockingState =
  | Uploading({progress: float})
  | ModalDialog({type_: dialogType, data: JSON.t})
  | CriticalError(string)
```

## 3. Impact Analysis & Refactoring Targets

### A. `src/core/Types.res`
*   **Target:** The huge `state` record.
*   **Change:** Deprecate and remove boolean flags (`isLinking`, `isTeasing`, etc.) in favor of the unified `appMode` variant.

### B. `src/systems/InteractionQueue.res`
*   **Decision:** **ELIMINATE.**
*   **Reasoning:** The current queue relies on DOM polling ("is the spinner visible?") to determine app stability. This is an anti-pattern and creates fragile dependencies on UI implementation details.
*   **Replacement strategy:**
    *   The FSM's `SystemBlocking` states (e.g., `Transitioning`, `Loading`) serve the same purpose but robustly.
    *   If the FSM is in `Loading`, user events are inherently ignored or buffered by the transition logic, eliminating the need for an external "stability check" loop.
    *   **Action:** Systematically replace queue dispatch calls with direct FSM events. Once the FSM handles the blocking states, delete `InteractionQueue.res`.

### C. `src/core/SceneMutations.res`
*   **Current Role:** Low-level state updates.
*   **Change:** Mutation functions should become "Transition Handlers". They should only be callable if the FSM is in a valid state for that mutation.

### D. `FingerprintService.res` & `UploadProcessorLogic.res`
*   **Issue:** Currently contain dispersed logic for handling duplicates and restores.
*   **Change:** These should become inputs to the FSM (e.g., `Event.FileDropped`). The FSM determines if an upload can start (e.g., `Idle -> Uploading`) or if it's blocked (e.g., `SummaryDialog -> Ignore`).

## 4. Implementation Plan

### Phase 1: Audit & Design
1.  **Inventory:** List all boolean flags and independent state trackers in `Types.res`.
2.  **Matrix:** Map out which combinations are valid vs. invalid.
3.  **Prototype:** Define the `AppFSM.res` module with the initial top-level types.

### Phase 2: The "Guard" Module
Implement the central transition function:
`let transition = (currentMode, event) => nextMode`
This function will serve as the single source of truth for app logic.

### Phase 3: Vertical Slice (Upload Flow)
Migrate the **Upload -> Processing -> Summary** flow first.
*   Define `Uploading` and `Summary` states.
*   Ensure that dropping files while in `Summary` state is explicitly handled (either ignored or queues a new action properly).
*   Remove `lastUploadReport` from the generic state bag and move it into the `Summary` variant data.

### Phase 4: Cleanup
*   Remove replaced boolean flags.
*   Delete `InteractionQueue.res` and remove all references.

## 5. Success Criteria
*   **Zero "Impossible" Bugs:** Situations like "Zombie Scenes" or "Overlapping Modals" are compilation errors or handled by the default `Ignore` case in the FSM.
*   **Simplified Logic:** Components don't check `if (!isUploading && !isLinking && ...)`—they just check `switch appMode { | Authoring => ... }`.
*   **Removal of Polling:** No more `setInterval` checks for UI stability.

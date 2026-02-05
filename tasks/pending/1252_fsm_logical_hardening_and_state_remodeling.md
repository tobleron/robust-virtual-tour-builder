# FSM Logical Hardening and State Model Refactoring

## 1. Objective
Comprehensively resolve the logical inconsistencies identified in the Global FSM proposal and harden the underlying data model to prevent "zombie states" and interaction race conditions by design.

## 2. Core Architectural Changes

### A. Unified Scene Source of Truth
*   **Problem:** `scenes: array<scene>` and `deletedSceneIds: array<string>` allow an ID to exist in both, creating "zombie" states.
*   **Solution:** Refactor `Types.res` to use a single collection.
    ```rescript
    type sceneStatus = Active | Deleted(float) // timestamp of deletion
    type sceneEntry = {
      scene: scene,
      status: sceneStatus
    }
    type state = {
      inventory: Map.String.t<sceneEntry>, // Single source of truth
      order: array<string> // Sequential IDs for the UI list
    }
    ```
*   **Impact:** Mutations must update one place. Deleting a scene changes its status; restoring it reverts it. The ID never moves between different data structures.

### B. Parallel FSM States (Navigation + UI Mode)
*   **Problem:** Touring and Authoring are not strictly mutually exclusive; you navigate while you edit.
*   **Solution:** Use a "Product State" or "Parallel State" for Interactive mode.
    ```rescript
    type interactiveState = {
      uiMode: [ #Viewing | #EditingHotspots | #EditingMetadata ],
      navigation: NavigationFSM.distinctState // Reflects the existing sub-FSM
    }
    ```

### C. Modal vs. Background Distinction
*   **Problem:** Heavy tasks (Uploads) shouldn't always block the entire UI (Authoring).
*   **Solution:** Define two categories of blocking in the Global FSM:
    1.  **Modal Blocking:** (e.g., `LoadingProject`, `CriticalError`). User input is strictly ignored/buffered.
    2.  **Ambient/Background:** (e.g., `Uploading`, `GeneratingPreviews`). UI remains interactive, but specific actions (like deleting the scene currently being uploaded) are "guarded" by the FSM.

### D. Semantic Event Buffering (Replacing InteractionQueue)
*   **Problem:** We need a way to handle clicks that happen while the app is "busy" without relying on DOM polling.
*   **Solution:** Implement "Next Action" slots in the FSM state.
    ```rescript
    | Loading({targetId, pendingAction: option<event>})
    ```
    If a user clicks "Edit" while a project is loading, the FSM saves the "Edit" intent and executes it immediately upon entering the `Idle/Interactive` state.

## 3. Implementation Steps

### Phase 1: Data Model Migration
1.  Update `Types.res` with the new `inventory` Map structure.
2.  Update `SceneMutations.res` to work with the Map.
3.  Ensure `deletedSceneIds` is removed and all logic uses `status == Deleted`.

### Phase 2: Global Guard (The FSM)
1.  Create `src/core/AppFSM.res`.
2.  Implement the `transition` function that handles Parallel states (UI Mode + Navigation).
3.  Implement the logic for Modal vs. Ambient task separation.

### Phase 3: InteractionQueue Decommissioning
1.  Map all `InteractionQueue.dispatch` calls to `AppFSM.send`.
2.  Replace "Stability Polling" with explicit state transitions (e.g., `NavigationComplete` event from `NavigationFSM` triggers the "Pending Action" in `AppFSM`).

## 4. Success Criteria
*   **Physical Impossibility:** No ID can be "Active" and "Deleted" simultaneously.
*   **No Polling:** `InteractionQueue.res` is deleted; no code uses `setInterval` or `setTimeout` to check for "stability".
*   **Predictable Interaction:** Clicking during a transition results in a deterministic "queued" action or an explicit "ignored" log, never a race condition.

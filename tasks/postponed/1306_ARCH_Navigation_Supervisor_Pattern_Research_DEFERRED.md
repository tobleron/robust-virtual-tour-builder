# [1306] Research and Implement Navigation Supervisor Pattern

## Context
The current system relies on a **Distributed Locking Mechanism** (`TransitionLock.res`) combined with **Reactive Side Effects** (React Hooks triggering `SceneLoader`). While functional, this architecture is susceptible to **Deadlocks** (as seen recently) and **Race Conditions** because the synchronization logic is scattered across multiple decoupled components.

## Objective
To achieve **Enterprise-Grade Robustness (10/10)**, migrate the navigation system to a **Structured Concurrency Supervisor** pattern. This shifts the control flow from "Distributed Locks" to a "Centralized Coordinator."

## Requirements

### 1. The Proposed Pattern: "Navigation Supervisor"
Implement a **Single-Threaded Supervisor (Actor Model)** that owns the lifecycle of scene transitions.

#### Core Principles
1.  **Intent-Based**: Components dispatch **Intents** (e.g., `REQUEST_NAVIGATE`), not direct commands.
2.  **Single Active Task**: The Supervisor ensures only **one** transition task runs at a time.
3.  **Automatic Cancellation**: When a new Intent arrives, the Supervisor **automatically cancels** the running task. The Task itself handles cleanup in its `finally` block (Structured Concurrency).
4.  **No Locks**: There is no "Lock" to acquire/release. The "Busy" state is simply `supervisor.currentTask != None`.

### 2. Implementation Steps
1.  Create a new module `src/systems/Navigation/NavigationSupervisor.res`.
2.  Implement the Supervisor Logic (see example below).
3.  Refactor `SceneLoader` to accept `AbortSignal` for structured concurrency.
4.  Refactor `SceneTransition` to accept `AbortSignal`.
5.  Refactor `NavigationFSM.res` to delegate to the Supervisor.
6.  Remove `TransitionLock` usage entirely.
7.  Ensure all side effects are in *one file*.

### 3. Verification
- Verify that "rapid fire" clicks automatically cancel previous loads without deadlocks.
- Verify that resources are cleaned up correctly upon cancellation.
- Run `npm run build` to ensure no regressions.

## Technical Notes

### Example Implementation Strategy (ReScript)

```rescript
type task = {
  id: string,
  cancel: unit => unit, // usage of AbortController
}

let currentTask = ref(None)

let processNavigationRequest = (targetSceneId) => {
  // 1. AUTO-CANCEL: Robustness by design
  // We don't ask for permission (Lock). We command order.
  currentTask.contents->Option.forEach(t => t.cancel())

  // 2. CREATE TASK
  let controller = AbortController.make()
  let taskId = UUID.make()
  
  // 3. START WORK (The "Saga")
  let promise = async () => {
    try {
      // Step A: Load
      await SceneLoader.load(targetSceneId, ~signal=controller.signal)
      
      // Step B: Swap
      await SceneTransition.swap(~signal=controller.signal)
      
      dispatch(NavigationSuccess)
    } catch {
      | AbortError => 
          // 4. CLEANUP (Implicit)
          // Resources are cleaned automatically when the promise chain aborts
          ViewerPool.recycle(targetSceneId)
      | Error(e) => 
          dispatch(NavigationError(e))
    }
  }

  currentTask := Some({id: taskId, cancel: () => controller.abort()})
  promise()
}
```

## Benefits
1.  **Zero Deadlocks**: There is no "Lock" to get stuck. A task either finishes or is replaced.
2.  **Performance**: "Rapid fire" clicks automatically cancel previous loads (saving bandwidth) without complex logic.
3.  **Testability**: The Supervisor Logic is pure orchestration. It can be unit-tested without a DOM.
4.  **Maintainability**: All Side Effects are in *one file*, not scattered across `Loader`, `Transition`, and `Hooks`.

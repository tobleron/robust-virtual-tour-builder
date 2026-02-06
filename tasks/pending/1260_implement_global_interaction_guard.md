# Implement Global Interaction Guard System (Enterprise Pattern)

## Context
The application currently suffers from race conditions due to rapid user interactions (e.g., "spam clicking" scenes, hotkeys, or buttons). Current mitigations are scattered (manual timestamp checks in `SceneList`) or non-existent (`SceneSwitcher`, `SidebarActions`), leading to:
-   **Resource Thrashing:** Redundant WebGL context creation/destruction.
-   **Data Integrity Risks:** Concurrent "Save" or "Delete" operations.
-   **Inconsistent UX:** Some actions are protected, others are not.

## Goal
Implement a **centralized, policy-driven Interaction Guard** system. This system will act as middleware for user actions, enforcing throttling, debouncing, and mutex (locking) logic globally. This ensures scalability, maintainability, and a "commercial-grade" robust user experience.

## Technical Architecture

### 1. Core Module: `InteractionGuard`
A singleton or context-based module responsible for tracking active interactions and enforcing policies.

**Key Features:**
-   **Registry:** Maps `InteractionID` -> `State` (Last execution time, Active promise, Call count).
-   **Guard Function:** `attempt(actionId, policy, callback) -> Result<unit, reason>`
-   **Telemetry:** Automatically logs throttled/blocked attempts for performance analysis.

### 2. Policy Definitions (`InteractionPolicies.res`)
Centralized configuration file defining behavior for each action type. Avoids hardcoding magic numbers in UI components.

**Policy Types:**
-   **`Throttle(ms, Leading|Trailing)`**: Allow max 1 call per `ms`. (Good for: Window resize, Mouse move, Scene Switching).
-   **`Debounce(ms)`**: Wait for silence for `ms` before executing. (Good for: Search inputs, Auto-save).
-   **`Mutex(Scope)`**: Prevent execution if *any* instance of this action is currently running (requires returning a Promise). (Good for: Save Project, Delete Scene, Export).
    -   `Scope`: `Global` (Block all) or `Keyed(id)` (Block only for this specific item).

### 3. React Hook: `useInteraction`
A standardized hook for UI components to easily integrate protection.

```rescript
// Example Usage
let (handleClick, isPending) = useInteraction(
  ~policy=Policies.SceneSwitch,
  ~action=() => dispatch(SetActiveScene(index))
)

<button onClick=handleClick disabled=isPending />
```

## Implementation Plan

### Phase 1: Foundation (Core Logic)
1.  [ ] Create `src/core/InteractionGuard.res`.
    -   Implement the state tracking map.
    -   Implement `check(policy, history)` logic.
2.  [ ] Create `src/core/InteractionPolicies.res`.
    -   Define the `policy` variant.
    -   Define standard policies:
        -   `SceneNavigation`: `Throttle(300ms, Leading)`.
        -   `ProjectMutation`: `Mutex(Global)`.
        -   `HeavyCompute`: `Debounce(100ms)`.

### Phase 2: React Integration
1.  [ ] Create `src/hooks/useInteraction.res`.
    -   Should return a wrapper function and state (`isPending`, `wasThrottled`).
    -   Handle unmounting cleanup (cancel pending debounces).

### Phase 3: Adoption (Refactoring)
1.  [ ] **Scene Switching (Critical):**
    -   Refactor `SceneList.res` to use `useInteraction` with `SceneNavigation` policy.
    -   Refactor `SceneSwitcher.res` (Hotspots) to use `InteractionGuard.attempt` directly (for non-React calls).
    -   Remove manual `lastSwitchTime` logic from `ViewerState` and `SceneList`.
2.  [ ] **Project Actions:**
    -   Wrap "Save", "Export", and "Delete" in `SidebarActions.res` with `Mutex` policy.
    -   Ensure visual feedback (spinners/disabled states) is driven by the guard state.

### Phase 4: Cleanup & Integration (Crucial)
1.  [ ] **Remove Ghost Modules:**
    -   Remove `src/core/InteractionQueue.res` from `MAP.md` (file does not exist).
2.  [ ] **Integrate `RateLimiter`:**
    -   Review `src/utils/RateLimiter.res`. If `InteractionGuard` implements similar logic, deprecate `RateLimiter` or make `InteractionGuard` use it internally.
    -   Update `ViewerSnapshot.res` to use the new standard `InteractionGuard` instead of raw `RateLimiter`.

### Phase 5: Validation
1.  [ ] Add Unit Tests for `InteractionGuard` (simulating time/concurrency).
2.  [ ] Verify "spam click" protection on Scene List (should execute once per 300ms).
3.  [ ] Verify "double save" protection (second click should be blocked while first is pending).

## Benefits
-   **Robustness:** mathematically impossible to trigger race conditions if policies are correct.
-   **Maintainability:** Change throttle timings in one file (`InteractionPolicies`) to tune global feel.
-   **Observability:** centralized logging of "user frustration" (high throttle counts).

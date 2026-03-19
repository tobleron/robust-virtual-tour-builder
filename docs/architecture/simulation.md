# Simulation Architecture

**Status:** Redesign Proposed  
**Last Updated:** March 19, 2026  
**Related Files:** `src/systems/Simulation/`, `src/core/State.res`, `src/systems/Navigation/`

---

## 1. Overview

This document defines the redesigned architecture for the tour simulation (auto-forward) system. The new architecture eliminates race conditions, introduces explicit state machine semantics, and provides deterministic behavior across all browsers.

**Scope:**
- Simulation/auto-forward traversal
- Scene transition coordination
- Waypoint animation timing
- Navigation lifecycle integration

---

## 2. Current Architecture Issues

### 2.1 Mixed Concerns

The current `Simulation.res` component handles:
- State management (via refs)
- Navigation coordination
- Timing/animation control
- Event subscription
- Operation lifecycle

**Problem:** Violates single responsibility principle and creates tight coupling.

### 2.2 Race Conditions

Multiple refs can get out of sync:
- `advancingForSceneId`
- `navigationCompleteRef`
- `retryCountRef`
- `runIdRef`

**Problem:** No single source of truth; refs can become inconsistent.

### 2.3 Implicit State Machine

State transitions are implicit through ref mutations.

**Problem:** Makes it hard to:
- Debug state issues
- Ensure deterministic behavior
- Handle edge cases exhaustively

### 2.4 Event Timing Dependencies

Relies on `SimulationAdvanceComplete` event arriving at the exact right time.

**Problem:** If the event arrives before the listener is set up or after it's been cleared, the simulation stalls.

### 2.5 No Initialization Phase

Simulation starts without confirming the viewer is ready.

**Problem:** Leads to timeout failures when viewer isn't initialized.

### 2.6 Tight Coupling to NavigationFSM

Direct dependency on `navigationState.navigationFsm == IdleFsm`.

**Problem:** Creates fragility; simulation behavior tied to navigation internals.

---

## 3. Proposed Deterministic Architecture

### 3.1 Design Principles

1. **Explicit State Machine:** All states and transitions are explicitly defined
2. **Single Source of Truth:** One FSM state ref, no scattered state
3. **Initialization Handshake:** Wait for viewer ready before starting
4. **Event-Driven Transitions:** State changes trigger actions, not polls
5. **Decoupled Coordination:** Simulation doesn't depend on NavigationFSM internals
6. **Deterministic Timing:** Based on events and explicit timers, not race conditions

### 3.2 State Machine Design

```
┌─────────────┐
│    Idle     │ ← Simulation not running
└──────┬──────┘
       │ StartSimulation({startSceneIndex})
       ▼
┌─────────────┐
│ Initializing│ ← Waiting for viewer to be ready
└──────┬──────┘
       │ ViewerReady
       ▼
┌─────────────┐
│   Running   │ ← Simulation active, ready to advance
└──────┬──────┘
       │ ShouldAdvance → [Calculate Next Move] → NavigationRequested
       ▼
┌─────────────────────┐
│ AwaitingTransition  │ ← Waiting for scene transition to complete
└──────────┬──────────┘
           │ NavigationCompleted({sceneIndex})
           ▼
┌─────────────┐
│  Animating  │ ← Waypoint animation in progress
└──────┬──────┘
       │ WaypointAnimationComplete (after delay)
       └───────────────┐
                       │
                       ▼
                  (back to Running)
```

### 3.3 State Definitions

```rescript
type simulationState =
  | IdleFsm
  | InitializingFsm({startSceneIndex: int, viewerReadyPollCount: int})
  | RunningFsm({
      currentSceneIndex: int,
      visitedLinkIds: array<string>,
      shouldAdvance: bool
    })
  | AwaitingTransitionFsm({
      fromSceneIndex: int,
      toSceneIndex: int,
      navigationRequested: bool
    })
  | AnimatingFsm({
      sceneIndex: int,
      animationStartTime: int,
      delayMs: int
    })
  | ErrorFsm({
      code: string,
      message: string,
      recoveryAction: option<recoveryAction>
    })
```

### 3.4 Event Definitions

```rescript
type simulationEvent =
  | StartSimulation({startSceneIndex: int})
  | StopSimulation
  | ViewerReady
  | NavigationRequested({fromSceneId: string, toSceneId: string})
  | NavigationCompleted({sceneIndex: int, linkId: string})
  | NavigationFailed({reason: string})
  | AnimationTimerExpired
  | ViewerNotReady
```

---

## 4. Module Structure

```
src/systems/Simulation/
├── Simulation.res           # Entry point, operation lifecycle only
├── SimulationFSM.res        # Pure state machine (no side effects)
├── SimulationDriver.res     # Orchestrator with timers and coordination
├── SimulationMainLogic.res  # Next move calculation (unchanged)
└── SimulationNavigation.res # Link finding (unchanged)
```

### 4.1 Module Responsibilities

**Simulation.res** (Facade)
- Operation lifecycle (start/stop)
- UI integration
- Error boundary

**SimulationFSM.res** (Pure Core)
- State type definitions
- Pure reducer function: `(state, event, appState) => (newState, option<action>)`
- Fully testable in isolation

**SimulationDriver.res** (Orchestrator)
- Timer management
- Initialization handshake (viewer polling)
- Event subscription for navigation completion
- Side effects coordination

**SimulationMainLogic.res** (Business Logic - Unchanged)
- Next move calculation
- Visited tracking
- Skip logic

**SimulationNavigation.res** (Utilities - Unchanged)
- Link finding
- Scene graph traversal helpers

---

## 5. Key Improvements

### 5.1 Initialization Phase

```rescript
let initializeSimulation = (startSceneIndex: int) => {
  // 1. Set FSM to Initializing
  // 2. Poll viewer readiness (max 6 seconds)
  // 3. On ready: transition to Running and start first animation
  // 4. On timeout: transition to Error and stop
}
```

**Benefits:**
- Prevents premature starts
- Explicit timeout handling
- Clear error states

### 5.2 Deterministic Animation Timing

```rescript
let startAnimationTimer = (sceneIndex, visitedLinkIds) => {
  let delay = calculateDelay(sceneIndex, visitedLinkIds, skipAutoForward)
  // Single timer, cleared on state change
  // No polling, no race conditions
}
```

**Benefits:**
- Single timer per animation
- Timer cleared on state transition
- No polling overhead

### 5.3 Event-Driven Navigation Coordination

```rescript
// SimulationDriver subscribes to SimulationAdvanceComplete
// When received: transition from AwaitingTransition → Animating
// No dependency on NavigationFSM state
```

**Benefits:**
- Decoupled from navigation internals
- Reliable event handling
- Clear transition triggers

### 5.4 Pure FSM Reducer

```rescript
let reduce = (state, event, appState): (simulationState, option<action>) => {
  // Pure function - no side effects
  // Returns new state AND optional action to dispatch
  // Fully testable in isolation
}
```

**Benefits:**
- Testable without mocks
- Predictable behavior
- Easy debugging

---

## 6. Implementation Plan

### Phase 1: Core FSM (Low Risk)

**Tasks:**
- [ ] Create `SimulationFSM.res` with state definitions
- [ ] Implement pure reducer function
- [ ] Add unit tests for all transitions

**Files:**
- `src/systems/Simulation/SimulationFSM.res` (new)
- `tests/unit/SimulationFSM_v.test.res` (new)

**Risk Level:** Low (new code, no existing behavior changed)

### Phase 2: Driver Component (Medium Risk)

**Tasks:**
- [ ] Create `SimulationDriver.res` with timer management
- [ ] Implement initialization handshake
- [ ] Add event subscription for navigation completion

**Files:**
- `src/systems/Simulation/SimulationDriver.res` (new)
- `src/systems/Simulation/Simulation.res` (updated)

**Risk Level:** Medium (coordinates existing systems)

### Phase 3: Integration (Higher Risk)

**Tasks:**
- [ ] Replace `Simulation.res` content with thin wrapper
- [ ] Keep existing `SimulationMainLogic` and `SimulationNavigation`
- [ ] Test with edge.zip project

**Files:**
- `src/systems/Simulation/Simulation.res` (major update)

**Risk Level:** Higher (replaces core simulation logic)

### Phase 4: Cleanup (No Risk)

**Tasks:**
- [ ] Remove old ref-based code
- [ ] Remove diagnostic logging
- [ ] Update documentation

**Files:**
- Various (cleanup only)

**Risk Level:** No risk (removal only)

---

## 7. Testing Strategy

### 7.1 Unit Tests

**FSM Reducer:**
```rescript
describe("SimulationFSM", () => {
  test("transitions from Idle to Initializing on StartSimulation", t => {
    let state = IdleFsm
    let event = StartSimulation({startSceneIndex: 0})
    let (nextState, action) = SimulationFSM.reduce(state, event, mockAppState)

    t->expect(nextState)->Expect.toMatchPattern(InitializingFsm(_))
  })

  test("transitions from Initializing to Running on ViewerReady", t => {
    // ...
  })

  test("transitions from Running to AwaitingTransition on ShouldAdvance", t => {
    // ...
  })

  test("transitions from AwaitingTransition to Animating on NavigationCompleted", t => {
    // ...
  })

  test("transitions to ErrorFsm on timeout", t => {
    // ...
  })
})
```

### 7.2 Integration Tests

**Driver Component:**
- Mock viewer readiness
- Mock navigation events
- Verify timer behavior
- Verify state transitions

### 7.3 E2E Tests

**Full Simulation:**
- Run with edge.zip project
- Verify complete tour traversal
- Verify visited tracking
- Verify skip logic
- Test in both Firefox and Chromium

### 7.4 Manual Testing Checklist

- [ ] Start simulation from first scene
- [ ] Start simulation from middle scene
- [ ] Stop simulation mid-tour
- [ ] Resume simulation after stop
- [ ] Navigate manually during simulation
- [ ] Test with all skip options enabled
- [ ] Test with dense scene graph (many links per scene)
- [ ] Test with sparse scene graph (few links)
- [ ] Verify no race conditions under rapid start/stop

---

## 8. Benefits

### 8.1 Reliability

- ✅ No race conditions (single state ref)
- ✅ Explicit initialization prevents premature starts
- ✅ Event-driven coordination eliminates timing dependencies

### 8.2 Debuggability

- ✅ State transitions logged explicitly
- ✅ Pure FSM easily testable
- ✅ Clear separation of concerns

### 8.3 Maintainability

- ✅ Each module has single responsibility
- ✅ Pure functions easier to reason about
- ✅ Well-defined interfaces between modules

### 8.4 Determinism

- ✅ Same input always produces same output
- ✅ No hidden state or timing dependencies
- ✅ Predictable behavior across browsers

---

## 9. Rollback Plan

If issues arise:

1. **Keep old implementation:** Rename `Simulation.res` to `SimulationOld.res`
2. **Switch import:** Temporarily import from old implementation
3. **Debug in isolation:** Test new implementation without affecting users
4. **Incremental rollout:** Re-enable new implementation module by module

---

## 10. Performance Considerations

### Memory

- Single state ref vs multiple refs: **Neutral** (same memory footprint)
- Timer management: **Improved** (single timer, no polling)

### CPU

- FSM reducer: **Improved** (pure function, optimized pattern matching)
- Event handling: **Improved** (event-driven vs polling)

### Rendering

- State transitions: **Improved** (explicit transitions, no ref sync overhead)

---

## 11. Related Documents

- [NavigationFSM](./navigation_fsm.md) (if exists)
- [State Management](../project/mechanics.md)
- [Testing Strategy](../project/testing_strategy.md)
- [Runbook & Audits](../project/runbook_and_audits.md)

---

## 12. Appendix: Current vs Proposed Comparison

| Aspect | Current | Proposed |
|---|---|---|
| State Management | Multiple refs | Single FSM ref |
| State Transitions | Implicit (ref mutations) | Explicit (reducer) |
| Initialization | None | Explicit handshake |
| Navigation Coordination | Polling + refs | Event-driven |
| Timer Management | Multiple timers | Single timer per state |
| Testability | Low (tightly coupled) | High (pure functions) |
| Debuggability | Low (implicit state) | High (logged transitions) |
| Browser Consistency | Variable | Deterministic |

---

**Document History:**
- March 19, 2026: Initial architecture proposal from simulation redesign

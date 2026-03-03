# Simulation/Tour Preview Architecture Redesign

## Current Architecture Issues

### 1. **Mixed Concerns**
The current `Simulation.res` component handles:
- State management (via refs)
- Navigation coordination
- Timing/animation control
- Event subscription
- Operation lifecycle

This violates single responsibility principle and creates tight coupling.

### 2. **Race Conditions**
Multiple refs can get out of sync:
- `advancingForSceneId`
- `navigationCompleteRef`
- `retryCountRef`
- `runIdRef`

### 3. **Implicit State Machine**
State transitions are implicit through ref mutations, making it hard to:
- Debug state issues
- Ensure deterministic behavior
- Handle edge cases

### 4. **Event Timing Dependencies**
Relies on `SimulationAdvanceComplete` event arriving at the exact right time. If the event arrives before the listener is set up or after it's been cleared, the simulation stalls.

### 5. **No Initialization Phase**
Simulation starts without confirming the viewer is ready, leading to timeout failures.

### 6. **Tight Coupling to NavigationFSM**
Direct dependency on `navigationState.navigationFsm == IdleFsm` creates fragility.

---

## Proposed Deterministic Architecture

### **Design Principles**

1. **Explicit State Machine**: All states and transitions are explicitly defined
2. **Single Source of Truth**: One FSM state ref, no scattered state
3. **Initialization Handshake**: Wait for viewer ready before starting
4. **Event-Driven Transitions**: State changes trigger actions, not polls
5. **Decoupled Coordination**: Simulation doesn't depend on NavigationFSM internals
6. **Deterministic Timing**: Based on events and explicit timers, not race conditions

### **State Machine Design**

```
States:
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

### **Module Structure**

```
src/systems/Simulation/
├── Simulation.res           # Entry point, operation lifecycle only
├── SimulationFSM.res        # Pure state machine (no side effects)
├── SimulationDriver.res     # Orchestrator with timers and coordination
├── SimulationMainLogic.res  # Next move calculation (unchanged)
└── SimulationNavigation.res # Link finding (unchanged)
```

### **Key Improvements**

#### 1. **Initialization Phase**
```rescript
let initializeSimulation = (startSceneIndex: int) => {
  // 1. Set FSM to Initializing
  // 2. Poll viewer readiness (max 6 seconds)
  // 3. On ready: transition to Running and start first animation
  // 4. On timeout: transition to Error and stop
}
```

#### 2. **Deterministic Animation Timing**
```rescript
let startAnimationTimer = (sceneIndex, visitedLinkIds) => {
  let delay = calculateDelay(sceneIndex, visitedLinkIds, skipAutoForward)
  // Single timer, cleared on state change
  // No polling, no race conditions
}
```

#### 3. **Event-Driven Navigation Coordination**
```rescript
// SimulationDriver subscribes to SimulationAdvanceComplete
// When received: transition from AwaitingTransition → Animating
// No dependency on NavigationFSM state
```

#### 4. **Pure FSM Reducer**
```rescript
let reduce = (state, event, appState): (simulationState, option<action>) => {
  // Pure function - no side effects
  // Returns new state AND optional action to dispatch
  // Fully testable in isolation
}
```

### **Implementation Plan**

#### Phase 1: Core FSM (Low Risk)
- Create `SimulationFSM.res` with state definitions
- Implement pure reducer function
- Add unit tests for all transitions

#### Phase 2: Driver Component (Medium Risk)
- Create `SimulationDriver.res` with timer management
- Implement initialization handshake
- Add event subscription for navigation completion

#### Phase 3: Integration (Higher Risk)
- Replace `Simulation.res` content with thin wrapper
- Keep existing `SimulationMainLogic` and `SimulationNavigation`
- Test with edge.zip project

#### Phase 4: Cleanup (No Risk)
- Remove old ref-based code
- Remove diagnostic logging
- Update documentation

### **Testing Strategy**

1. **Unit Tests**: FSM reducer with all state/event combinations
2. **Integration Tests**: Driver component with mocked viewer
3. **E2E Tests**: Full simulation with edge.zip project
4. **Manual Testing**: Both Firefox and Chromium

### **Rollback Plan**

If issues arise:
1. Keep old `Simulation.res` as `SimulationOld.res`
2. Switch import back to old implementation
3. Debug new implementation in isolation

---

## Benefits

### **Reliability**
- No race conditions (single state ref)
- Explicit initialization prevents premature starts
- Event-driven coordination eliminates timing dependencies

### **Debuggability**
- State transitions are logged explicitly
- Pure FSM is easily testable
- Clear separation of concerns

### **Maintainability**
- Each module has single responsibility
- Pure functions are easier to reason about
- Well-defined interfaces between modules

### **Determinism**
- Same input always produces same output
- No hidden state or timing dependencies
- Predictable behavior across browsers

---

## Next Steps

1. **Review this architecture document**
2. **Approve or request changes**
3. **Implement in phases** (start with Phase 1)
4. **Test thoroughly with edge.zip**
5. **Deploy when confident**

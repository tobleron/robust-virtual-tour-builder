# Task 63: Refactor SimulationSystem Mutable State to Functional Pattern

**Status:** Pending  
**Priority:** MEDIUM  
**Category:** Frontend Code Quality  
**Estimated Effort:** 2-3 hours

---

## Objective

Refactor `SimulationSystem.res` to eliminate mutable state fields and follow pure functional programming principles using the builder pattern and immutable state updates.

---

## Context

**Current Implementation:**
`SimulationSystem.res` uses a mutable `simulationState` type with 7 mutable fields:
- `mutable isAutoPilot: bool`
- `mutable visitedScenes: array<int>`
- `mutable stoppingOnArrival: bool`
- `mutable skipAutoForwardGlobal: bool`
- `mutable lastAdvanceTime: float`
- `mutable pendingAdvanceId: option<int>`
- `mutable autoPilotJourneyId: int`

**Why This Matters:**
1. **Predictability:** Mutable state makes it harder to track changes
2. **Debugging:** State mutations can occur anywhere, not just in reducer
3. **Standards Compliance:** Violates functional programming workflow
4. **Testing:** Harder to test state transitions in isolation

**Functional Alternative:**
Use immutable records with spread syntax (`...state`) for updates, managed through a central reducer or builder pattern.

---

## Requirements

### Functional Requirements
1. Convert `simulationState` type to immutable record
2. Replace direct field mutations with function calls that return new state
3. Centralize state updates in a reducer pattern
4. Maintain exact same functionality
5. Ensure no regression in simulation behavior

### Technical Requirements
1. Use ReScript record spread syntax for updates
2. Follow Elm architecture (State → Action → Update → New State)
3. Add type-safe actions for each state change
4. Keep transition animations reference for mutable fields
5. Document migration of each mutable field

---

## Implementation Steps

### Step 1: Define Immutable State Type

Replace current mutable type (lines 5-13):

**Before:**
```rescript
type simulationState = {
  mutable isAutoPilot: bool,
  mutable visitedScenes: array<int>,
  mutable stoppingOnArrival: bool,
  mutable skipAutoForwardGlobal: bool,
  mutable lastAdvanceTime: float,
  mutable pendingAdvanceId: option<int>,
  mutable autoPilotJourneyId: int,
}
```

**After:**
```rescript
type simulationState = {
  isAutoPilot: bool,
  visitedScenes: array<int>,
  stoppingOnArrival: bool,
  skipAutoForwardGlobal: bool,
  lastAdvanceTime: float,
  pendingAdvanceId: option<int>,
  autoPilotJourneyId: int,
}

// Helper to create initial state
let makeInitialState = (): simulationState => {
  isAutoPilot: false,
  visitedScenes: [],
  stoppingOnArrival: false,
  skipAutoForwardGlobal: false,
  lastAdvanceTime: 0.0,
  pendingAdvanceId: None,
  autoPilotJourneyId: 0,
}
```

### Step 2: Define Action Types for State Updates

```rescript
type simulationAction =
  | StartAutoPilot(int) // journey ID
  | StopAutoPilot
  | AddVisitedScene(int)
  | ClearVisitedScenes
  | SetStoppingOnArrival(bool)
  | SetSkipAutoForward(bool)
  | UpdateAdvanceTime(float)
  | SetPendingAdvance(option<int>)
  | IncrementJourneyId
```

### Step 3: Implement Reducer Function

```rescript
let reduceSimulation = (state: simulationState, action: simulationAction): simulationState => {
  switch action {
  | StartAutoPilot(journeyId) => {
      ...state,
      isAutoPilot: true,
      autoPilotJourneyId: journeyId,
      visitedScenes: [],
    }
  | StopAutoPilot => {
      ...state,
      isAutoPilot: false,
      pendingAdvanceId: None,
    }
  | AddVisitedScene(sceneIdx) => {
      ...state,
      visitedScenes: Belt.Array.concat(state.visitedScenes, [sceneIdx]),
    }
  | ClearVisitedScenes => {
      ...state,
      visitedScenes: [],
    }
  | SetStoppingOnArrival(value) => {
      ...state,
      stoppingOnArrival: value,
    }
  | SetSkipAutoForward(value) => {
      ...state,
      skipAutoForwardGlobal: value,
    }
  | UpdateAdvanceTime(time) => {
      ...state,
      lastAdvanceTime: time,
    }
  | SetPendingAdvance(id) => {
      ...state,
      pendingAdvanceId: id,
    }
  | IncrementJourneyId => {
      ...state,
      autoPilotJourneyId: state.autoPilotJourneyId + 1,
    }
  }
}
```

### Step 4: Refactor State Management in Module

Current pattern:
```rescript
let state = ref({
  mutable isAutoPilot: false,
  // ...
})

// Usage:
state.contents.isAutoPilot = true  // ❌ Direct mutation
```

New pattern:
```rescript
let state = ref(makeInitialState())

// Helper function to dispatch actions
let dispatch = (action: simulationAction): unit => {
  state := reduceSimulation(state.contents, action)
}

// Usage:
dispatch(StartAutoPilot(123))  // ✅ Immutable update
```

### Step 5: Update All State Mutations

Find and replace each mutation pattern:

#### Pattern 1: `state.contents.isAutoPilot = true`
**Before:**
```rescript
state.contents.isAutoPilot = true
state.contents.autoPilotJourneyId = journeyId
state.contents.visitedScenes = []
```

**After:**
```rescript
dispatch(StartAutoPilot(journeyId))
```

#### Pattern 2: `state.contents.isAutoPilot = false`
**Before:**
```rescript
state.contents.isAutoPilot = false
state.contents.pendingAdvanceId = None
```

**After:**
```rescript
dispatch(StopAutoPilot)
```

#### Pattern 3: Adding visited scenes
**Before:**
```rescript
let _ = Js.Array.push(currentIdx, state.contents.visitedScenes)
```

**After:**
```rescript
dispatch(AddVisitedScene(currentIdx))
```

#### Pattern 4: Updating advance time
**Before:**
```rescript
state.contents.lastAdvanceTime = Date.now()
```

**After:**
```rescript
dispatch(UpdateAdvanceTime(Date.now()))
```

### Step 6: Handle Transition Animations (Lines 533-549)

The `transitionState` type also uses mutable fields for animation:

**Before:**
```rescript
type transitionState = {
  mutable yaw: float,
  mutable pitch: float,
  // ...
  mutable transitionTarget: option<transitionTarget>,
  mutable arrivalView: arrivalView,
}
```

**Decision:** Keep these as mutable for performance
- Animation frames update ~60 times/second
- Creating new objects each frame causes GC pressure
- This is an acceptable use case for mutation (local animation state)

**Document with comment:**
```rescript
// Note: transitionState uses mutable fields for animation performance
// This is acceptable as it's scoped to animation frames and not app state
type transitionState = {
  mutable yaw: float,
  mutable pitch: float,
  // ... rest stays the same
}
```

### Step 7: Add Logging for State Transitions

Add debug logging to reducer:
```rescript
let reduceSimulation = (state: simulationState, action: simulationAction): simulationState => {
  Logger.debug(
    ~module_="Simulation",
    ~message="STATE_TRANSITION",
    ~data=Obj.magic({"action": action, "prevState": state}),
    ()
  )
  
  let newState = switch action {
    // ... existing cases ...
  }
  
  Logger.debug(
    ~module_="Simulation",
    ~message="STATE_UPDATED",
    ~data=Obj.magic({"newState": newState}),
    ()
  )
  
  newState
}
```

---

## Testing Criteria

### Unit Tests

Create test file: `tests/SimulationSystem_test.res`

```rescript
open RescriptMocha

describe("SimulationSystem Reducer", () => {
  it("StartAutoPilot sets isAutoPilot to true", () => {
    let initial = makeInitialState()
    let updated = reduceSimulation(initial, StartAutoPilot(42))
    
    Assert.equal(updated.isAutoPilot, true)
    Assert.equal(updated.autoPilotJourneyId, 42)
    Assert.equal(Array.length(updated.visitedScenes), 0)
  })
  
  it("StopAutoPilot resets state", () => {
    let initial = {...makeInitialState(), isAutoPilot: true, pendingAdvanceId: Some(5)}
    let updated = reduceSimulation(initial, StopAutoPilot)
    
    Assert.equal(updated.isAutoPilot, false)
    Assert.equal(updated.pendingAdvanceId, None)
  })
  
  it("AddVisitedScene appends to array", () => {
    let initial = {...makeInitialState(), visitedScenes: [1, 2]}
    let updated = reduceSimulation(initial, AddVisitedScene(3))
    
    Assert.deepEqual(updated.visitedScenes, [1, 2, 3])
  })
  
  it("IncrementJourneyId increments", () => {
    let initial = {...makeInitialState(), autoPilotJourneyId: 5}
    let updated = reduceSimulation(initial, IncrementJourneyId)
    
    Assert.equal(updated.autoPilotJourneyId, 6)
  })
})
```

Run tests:
```bash
npm run test
```

### Integration Tests

1. **Auto-pilot simulation:**
   - Start auto-pilot
   - Verify state transitions through multiple scenes
   - Stop auto-pilot
   - Verify state reset

2. **Manual navigation:**
   - Navigate manually
   - Verify visited scenes tracked
   - Verify advance timing

### Manual Testing

1. Open app
2. Load project with 10+ scenes
3. Start auto-pilot simulation
4. Observe smooth scene transitions
5. Check browser console for state transition logs
6. Stop simulation
7. Verify no errors in console

---

## Expected Impact

**Code Quality:**
- ✅ Pure functional state management
- ✅ Predictable state transitions
- ✅ Easier to debug (state changes logged)
- ✅ Better testability (reducer is pure function)

**Maintainability:**
- ✅ Clear separation of state and actions
- ✅ Centralized update logic
- ✅ Self-documenting code (actions describe intent)

**Performance:**
- ⚠️ Minimal impact - ReScript optimizes record updates
- ⚠️ Animation state kept mutable for 60fps performance

---

## Migration Checklist

Track each state mutation replacement:

- [ ] `isAutoPilot` mutations → `StartAutoPilot`/`StopAutoPilot` actions
- [ ] `visitedScenes` mutations → `AddVisitedScene`/`ClearVisitedScenes` actions
- [ ] `stoppingOnArrival` mutations → `SetStoppingOnArrival` action
- [ ] `skipAutoForwardGlobal` mutations → `SetSkipAutoForward` action
- [ ] `lastAdvanceTime` mutations → `UpdateAdvanceTime` action
- [ ] `pendingAdvanceId` mutations → `SetPendingAdvance` action
- [ ] `autoPilotJourneyId` mutations → `IncrementJourneyId` action

---

## Dependencies

None - standalone refactor

---

## Rollback Plan

If issues arise:
1. Git revert the commit
2. Functionality unchanged (mutations restored)

---

## Related Files

- `src/systems/SimulationSystem.res` (main refactor)
- `tests/SimulationSystem_test.res` (new test file)

---

## Success Metrics

- ✅ All tests pass
- ✅ `grep "mutable" SimulationSystem.res` shows only animation state
- ✅ State transitions logged with clear action names
- ✅ No behavior regressions (simulation works identically)
- ✅ Reducer function < 100 lines (clear and concise)

# Task 80: Add Frontend Unit Tests

## Priority: 🟡 IMPORTANT

## Context
The backend has 7 unit tests covering critical logic (pathfinder, similarity, serialization). The frontend has **zero** automated tests. This makes refactoring risky and regressions likely.

## Goals
1. Set up a testing framework for ReScript
2. Add tests for critical business logic modules
3. Establish testing patterns for future development

## Recommended Setup

### Testing Framework Options

**Option A: ReScript Native Testing (Recommended)**
Use `rescript-test` or write tests as regular ReScript files that run with Node:

```rescript
// tests/ReducerTest.res
let () = {
  // Test: SetActiveScene within bounds
  let state = State.initialState
  let action = Actions.SetActiveScene(0, 0.0, 0.0, None)
  let newState = Reducer.reducer(state, action)
  assert(newState.activeIndex == 0)
  Js.log("✓ SetActiveScene within bounds")
}
```

**Option B: Jest with ReScript**
```json
// package.json
{
  "devDependencies": {
    "@glennsl/rescript-jest": "^0.11.0",
    "jest": "^29.0.0"
  }
}
```

## Modules to Test (Priority Order)

### 1. Reducer.res (Highest Priority)
Most critical - all state mutations flow through here.

Test cases:
- [ ] `SetActiveScene` within bounds
- [ ] `SetActiveScene` out of bounds (should not crash)
- [ ] `AddScene` adds to scenes array
- [ ] `DeleteScene` removes and updates activeIndex
- [ ] `LoadProject` parses valid JSON
- [ ] `LoadProject` handles malformed JSON gracefully
- [ ] `syncSceneNames` updates hotspot targets after rename

### 2. TourLogic.res
Test cases:
- [ ] Floor ordering logic
- [ ] Category toggling
- [ ] Label generation

### 3. GeoUtils.res
Test cases:
- [ ] Distance calculation between coordinates
- [ ] Bearing calculation
- [ ] Edge cases (same point, antipodal points)

### 4. PathInterpolation.res
Test cases:
- [ ] Linear interpolation
- [ ] Easing functions
- [ ] Boundary values (t=0, t=1)

### 5. Simulation modules
Test cases:
- [ ] Chain skipping logic
- [ ] Path generation
- [ ] Navigation state transitions

## Directory Structure

```
tests/
├── unit/
│   ├── ReducerTest.res
│   ├── TourLogicTest.res
│   ├── GeoUtilsTest.res
│   └── PathInterpolationTest.res
├── integration/
│   └── UploadFlowTest.res (future)
└── TestRunner.res
```

## Acceptance Criteria
- [ ] Testing framework configured
- [ ] At least 10 unit tests written
- [ ] Tests can run via `npm test`
- [ ] All tests pass
- [ ] README updated with testing instructions

## NPM Script
Add to `package.json`:
```json
{
  "scripts": {
    "test:frontend": "node lib/bs/tests/TestRunner.bs.js"
  }
}
```

## Files to Create/Modify
- `rescript.json` (add test files to sources)
- `package.json` (add test script)
- `tests/` directory with test files

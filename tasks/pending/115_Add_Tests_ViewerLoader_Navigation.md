# Task 115: Add Tests for ViewerLoader and Navigation Modules

## Priority: HIGH

## Context
The `ViewerLoader.res` (516 lines) and `Navigation.res` (487 lines) are critical core modules that handle the panorama viewer initialization and scene navigation. Currently, these modules lack unit tests, creating a regression risk for core viewer functionality.

## Objective
Add comprehensive unit tests for `ViewerLoader.res` and `Navigation.res` to protect critical viewer functionality.

## Acceptance Criteria

### ViewerLoader Tests (`tests/unit/ViewerLoaderTest.res`)
- [ ] Test `loadPannellum` lazy-loading behavior
- [ ] Test `initializeViewer` with valid configuration
- [ ] Test `destroyViewer` cleanup
- [ ] Test error handling for missing container
- [ ] Test error handling for invalid panorama URL
- [ ] Verify mock Pannellum API bindings work correctly

### Navigation Tests (`tests/unit/NavigationTest.res`)
- [ ] Test `navigateToScene` with valid scene index
- [ ] Test `navigateToScene` with out-of-bounds index (edge case)
- [ ] Test `getNextScene` logic
- [ ] Test `getPreviousScene` logic
- [ ] Test `findSceneByName` utility
- [ ] Test transition calculation (yaw/pitch interpolation)
- [ ] Test circular navigation (last → first scene)

## Implementation Notes

1. **Create mock bindings** for Pannellum viewer API since it's a third-party library
2. **Use the existing test pattern** from `ReducerTest.res` and `SimulationSystemTest.res`
3. **Focus on pure function logic** - avoid testing DOM interactions
4. **Register tests** in `tests/TestRunner.res`

## Example Test Structure

```rescript
// tests/unit/ViewerLoaderTest.res
let testSuite = () => {
  Logger.info("ViewerLoaderTest", "Starting ViewerLoader tests", None)
  
  // Test: loadPannellum returns promise
  let testLoadPannellum = () => {
    // Mock or verify lazy loading behavior
  }
  
  // Test: initializeViewer creates viewer object
  let testInitializeViewer = () => {
    // Test with mock container and config
  }
  
  testLoadPannellum()
  testInitializeViewer()
  
  Logger.info("ViewerLoaderTest", "All ViewerLoader tests passed", None)
}
```

## Verification
1. `npm run res:build` compiles without errors
2. `npm run test:frontend` shows new tests passing
3. `npm test` passes all tests

## Estimated Effort
4-6 hours

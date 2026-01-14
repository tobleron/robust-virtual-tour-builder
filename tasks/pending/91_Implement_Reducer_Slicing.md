# Task 91: Implement Reducer Slicing Pattern

## Priority
**MEDIUM** - Code organization and maintainability

## Context
The `Reducer.res` module is the central brain of the application, handling all state transitions through a large switch statement. While `ReducerHelpers.res` has successfully offloaded complex parsing logic, the main reducer still handles everything from UI state to data validation in a single 262-line file.

## Current State

`Reducer.res` handles diverse concerns:
- Scene management (Add, Delete, Reorder)
- Hotspot operations (Add, Remove, Update)
- UI state (Linking, Teasing, Preloading)
- Navigation state (Simulation, Journey tracking)
- Timeline operations (Add, Remove, Reorder, Update)
- Project operations (Load, Reset, Sync)
- Metadata updates

This creates several issues:
1. **Cognitive Load**: Understanding all state transitions requires reading the entire file
2. **Testing Complexity**: Testing specific domains requires setting up full state
3. **Merge Conflicts**: Multiple features touching the same file increases conflict risk
4. **Discoverability**: Finding the logic for a specific domain is harder

## Goals

1. **Split Reducer by Domain**: Create focused reducer slices for different state domains
2. **Maintain Type Safety**: Ensure all slices are properly typed
3. **Preserve Functionality**: No behavioral changes, only reorganization
4. **Improve Testability**: Enable testing individual slices in isolation
5. **Keep Performance**: Ensure no performance regression from the split

## Implementation Steps

### Step 1: Analyze Current Reducer Actions

Group actions by domain:

**Scene Domain**:
- `AddScenes`
- `DeleteScene`
- `ReorderScenes`
- `SetActiveScene`
- `SyncSceneNames`
- `UpdateSceneMetadata`

**Hotspot Domain**:
- `AddHotspot`
- `RemoveHotspot`
- `ClearHotspots`
- `UpdateHotspotTargetView`
- `UpdateHotspotReturnView`
- `ToggleHotspotReturnLink`

**UI Domain**:
- `SetIsLinking`
- `SetIsTeasing`
- `SetLinkDraft`
- `SetPreloadingScene`

**Navigation Domain**:
- `SetSimulationMode`
- `SetNavigationStatus`
- `SetIncomingLink`
- `AddToAutoForwardChain`
- `ResetAutoForwardChain`
- `SetPendingReturnSceneName`
- `IncrementJourneyId`
- `SetCurrentJourneyId`
- `NavigationCompleted`

**Timeline Domain**:
- `AddToTimeline`
- `RemoveFromTimeline`
- `ReorderTimeline`
- `UpdateTimelineStep`
- `SetActiveTimelineStep`

**Project Domain**:
- `SetTourName`
- `LoadProject`
- `Reset`
- `SetExifReport`
- `RemoveDeletedSceneId`
- `ApplyLazyRename`

### Step 2: Create Reducer Slice Modules

Create `src/core/reducers/SceneReducer.res`:

```rescript
open Types
open Actions

/**
 * SceneReducer - Handles all scene-related state transitions
 * 
 * Responsibilities:
 * - Adding/removing scenes
 * - Reordering scenes
 * - Setting active scene
 * - Updating scene metadata
 * - Syncing scene names
 */

let handleAddScenes = (state: state, scenesData): state => {
  ReducerHelpers.handleAddScenes(state, scenesData)
}

let handleDeleteScene = (state: state, index: int): state => {
  ReducerHelpers.handleDeleteScene(state, index)
}

let handleReorderScenes = (state: state, fromIndex: int, toIndex: int): state => {
  if fromIndex != toIndex {
    let scenes = state.scenes
    switch Belt.Array.get(scenes, fromIndex) {
    | Some(movedItem) =>
      let rest = Belt.Array.keepWithIndex(scenes, (_, i) => i != fromIndex)
      let newScenes = Reducer.insertAt(rest, toIndex, movedItem)

      let newActiveIndex = if state.activeIndex == fromIndex {
        toIndex
      } else if state.activeIndex > fromIndex && state.activeIndex <= toIndex {
        state.activeIndex - 1
      } else if state.activeIndex < fromIndex && state.activeIndex >= toIndex {
        state.activeIndex + 1
      } else {
        state.activeIndex
      }

      {...state, scenes: ReducerHelpers.syncSceneNames(newScenes), activeIndex: newActiveIndex}
    | None => state
    }
  } else {
    state
  }
}

let handleSetActiveScene = (
  state: state,
  index: int,
  yaw: float,
  pitch: float,
  transition: option<transitionState>
): state => {
  if index >= 0 && index < Belt.Array.length(state.scenes) {
    let newTransition = switch transition {
    | Some(t) => t
    | None => {type_: None, targetHotspotIndex: -1, fromSceneName: None}
    }
    {...state, activeIndex: index, activeYaw: yaw, activePitch: pitch, transition: newTransition}
  } else {
    state
  }
}

let handleUpdateSceneMetadata = (state: state, index: int, metaJson): state => {
  ReducerHelpers.handleUpdateSceneMetadata(state, index, metaJson)
}

let handleSyncSceneNames = (state: state): state => {
  {...state, scenes: ReducerHelpers.syncSceneNames(state.scenes)}
}

let handleApplyLazyRename = (state: state, index: int, name: string): state => {
  let newScenes = Belt.Array.mapWithIndex(state.scenes, (i, s) => {
    if i == index {
      {...s, label: name}
    } else {
      s
    }
  })
  {...state, scenes: ReducerHelpers.syncSceneNames(newScenes)}
}

/**
 * Main scene reducer - delegates to specific handlers
 */
let reduce = (state: state, action: action): option<state> => {
  switch action {
  | AddScenes(scenesData) => Some(handleAddScenes(state, scenesData))
  | DeleteScene(index) => Some(handleDeleteScene(state, index))
  | ReorderScenes(fromIndex, toIndex) => Some(handleReorderScenes(state, fromIndex, toIndex))
  | SetActiveScene(index, yaw, pitch, transition) => 
      Some(handleSetActiveScene(state, index, yaw, pitch, transition))
  | UpdateSceneMetadata(index, metaJson) => Some(handleUpdateSceneMetadata(state, index, metaJson))
  | SyncSceneNames => Some(handleSyncSceneNames(state))
  | ApplyLazyRename(index, name) => Some(handleApplyLazyRename(state, index, name))
  | _ => None // Not handled by this reducer
  }
}
```

Create similar files for other domains:
- `src/core/reducers/HotspotReducer.res`
- `src/core/reducers/UiReducer.res`
- `src/core/reducers/NavigationReducer.res`
- `src/core/reducers/TimelineReducer.res`
- `src/core/reducers/ProjectReducer.res`

### Step 3: Create Root Reducer Combiner

Create `src/core/reducers/RootReducer.res`:

```rescript
open Types
open Actions

/**
 * RootReducer - Combines all domain-specific reducers
 * 
 * This follows the "reducer composition" pattern where each domain
 * reducer handles its own slice of actions and returns None for
 * actions it doesn't handle.
 */

let reducer = (state: state, action: action): state => {
  // Try each domain reducer in sequence
  // First one to return Some(newState) wins
  
  switch SceneReducer.reduce(state, action) {
  | Some(newState) => newState
  | None =>
    switch HotspotReducer.reduce(state, action) {
    | Some(newState) => newState
    | None =>
      switch UiReducer.reduce(state, action) {
      | Some(newState) => newState
      | None =>
        switch NavigationReducer.reduce(state, action) {
        | Some(newState) => newState
        | None =>
          switch TimelineReducer.reduce(state, action) {
          | Some(newState) => newState
          | None =>
            switch ProjectReducer.reduce(state, action) {
            | Some(newState) => newState
            | None =>
              // No reducer handled this action - return state unchanged
              Logger.warn(
                ~module_="RootReducer",
                ~message="Unhandled action",
                ~data=Some({"action": Obj.magic(action)}),
                ()
              )
              state
            }
          }
        }
      }
    }
  }
}
```

### Step 4: Update Reducer.res

Replace the current implementation with:

```rescript
open Types
open Actions

// Re-export the root reducer
let reducer = RootReducer.reducer

// Keep utility functions that are used by slice reducers
let insertAt = (arr, index, item) => {
  let before = Belt.Array.slice(arr, ~offset=0, ~len=index)
  let after = Belt.Array.slice(arr, ~offset=index, ~len=Belt.Array.length(arr) - index)
  Belt.Array.concatMany([before, [item], after])
}
```

### Step 5: Create Reducer Index Module

Create `src/core/reducers/mod.res` (or update rescript.json to expose the folder):

```rescript
// Re-export all reducers for easy importing
module Scene = SceneReducer
module Hotspot = HotspotReducer
module Ui = UiReducer
module Navigation = NavigationReducer
module Timeline = TimelineReducer
module Project = ProjectReducer
module Root = RootReducer
```

### Step 6: Update Tests

Create domain-specific test files:
- `tests/unit/SceneReducerTest.res`
- `tests/unit/HotspotReducerTest.res`
- `tests/unit/NavigationReducerTest.res`

Example `SceneReducerTest.res`:

```rescript
open Types
open Actions

let testAddScenes = () => {
  let initialState = State.initialState
  let scenesData = [
    {"label": "Scene 1", "file": "scene1.webp", "hotspots": []},
    {"label": "Scene 2", "file": "scene2.webp", "hotspots": []}
  ]
  
  let newState = SceneReducer.reduce(initialState, AddScenes(scenesData))
  
  switch newState {
  | Some(state) =>
    if Belt.Array.length(state.scenes) == 2 {
      Console.log("✓ testAddScenes passed")
    } else {
      Console.error("✗ testAddScenes failed: expected 2 scenes")
    }
  | None => Console.error("✗ testAddScenes failed: reducer returned None")
  }
}

let testDeleteScene = () => {
  // Create state with 3 scenes
  let state = {
    ...State.initialState,
    scenes: [
      {label: "Scene 1", name: "scene-1", file: "s1.webp", hotspots: [], metadata: None},
      {label: "Scene 2", name: "scene-2", file: "s2.webp", hotspots: [], metadata: None},
      {label: "Scene 3", name: "scene-3", file: "s3.webp", hotspots: [], metadata: None},
    ],
    activeIndex: 1
  }
  
  let newState = SceneReducer.reduce(state, DeleteScene(1))
  
  switch newState {
  | Some(state) =>
    if Belt.Array.length(state.scenes) == 2 && state.activeIndex == 0 {
      Console.log("✓ testDeleteScene passed")
    } else {
      Console.error("✗ testDeleteScene failed")
    }
  | None => Console.error("✗ testDeleteScene failed: reducer returned None")
  }
}

let runTests = () => {
  Console.log("Running SceneReducer tests...")
  testAddScenes()
  testDeleteScene()
}
```

### Step 7: Update AppContext

Ensure `AppContext.res` uses the new root reducer:

```rescript
let (state, dispatch) = React.useReducer(Reducer.reducer, State.initialState)
```

## Verification

### Build Verification
```bash
npm run res:build
```
Should complete without errors.

### Test Verification
```bash
npm run test:frontend
```
All existing tests should pass, plus new domain-specific tests.

### Functional Verification
1. **Scene Operations**:
   - Upload images → scenes added
   - Delete scene → scene removed, active index adjusted
   - Reorder scenes → order changes correctly

2. **Hotspot Operations**:
   - Create link → hotspot added
   - Delete link → hotspot removed
   - Update target view → hotspot updated

3. **Navigation**:
   - Enable simulation mode → state updates
   - Navigate between scenes → journey tracking works
   - Auto-forward chain → chain builds correctly

4. **Timeline**:
   - Add timeline step → step added
   - Reorder steps → order changes
   - Update step → step data updated

### Performance Verification
Use React DevTools Profiler to ensure no performance regression from the split.

## Success Criteria

- [ ] All domain reducers created (Scene, Hotspot, UI, Navigation, Timeline, Project)
- [ ] Root reducer combines all domain reducers
- [ ] `Reducer.res` delegates to `RootReducer`
- [ ] All existing functionality preserved
- [ ] `npm run res:build` succeeds
- [ ] All tests pass
- [ ] No performance regression
- [ ] Code is more maintainable and discoverable
- [ ] Each reducer file is under 200 lines
- [ ] Domain-specific tests added

## Migration Notes

### For Future Development

When adding new actions:

1. **Identify the domain**: Determine which reducer slice should handle it
2. **Add to the slice**: Implement the handler in the appropriate domain reducer
3. **Test in isolation**: Write tests for just that slice
4. **Verify integration**: Ensure it works in the full app

### Rollback Plan

If issues arise:
1. The old `Reducer.res` logic is preserved in git history
2. Simply revert the changes to `Reducer.res`
3. Remove the new `reducers/` folder
4. Rebuild and test

## Benefits

1. **Easier to Understand**: Each file focuses on one domain
2. **Easier to Test**: Test individual domains in isolation
3. **Easier to Extend**: Clear place to add new functionality
4. **Reduced Conflicts**: Multiple developers can work on different domains
5. **Better Performance**: Potential for future optimizations (e.g., memoization per slice)

## Notes

- This is a pure refactoring - no behavioral changes
- The pattern follows Redux Toolkit's "slice" pattern
- Each reducer returns `option<state>` to indicate if it handled the action
- The root reducer tries each slice in sequence
- Unhandled actions are logged as warnings for debugging

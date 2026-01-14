# Task 86: Refactor Reducer Module (552 lines → <450)

## Priority: 🟡 IMPORTANT

## Context
`Reducer.res` is at 552 lines and growing with each new feature. The reducer is central to the application and adding cases increases its size. Proactive refactoring will keep it maintainable.

## Current Structure

The reducer handles:
- Scene management (add, delete, reorder, update)
- Navigation state (active scene, viewing angles)
- Project loading/parsing
- Hotspot management
- Simulation state
- Timeline management
- Upload reports

## Refactoring Strategy

### Strategy A: Extract Sub-Reducers by Domain

**1. SceneReducer.res (~100 lines)**
```rescript
// SceneReducer.res
let handleSceneAction = (state: Types.state, action): Types.state => {
  switch action {
  | Actions.AddScene(scene) => ...
  | Actions.DeleteScene(index) => ...
  | Actions.ReorderScene(from, to_) => ...
  | Actions.UpdateSceneMetadata(index, meta) => ...
  | _ => state // Pass through unhandled
  }
}
```

**2. NavigationReducer.res (~80 lines)**
```rescript
// NavigationReducer.res
let handleNavigationAction = (state: Types.state, action): Types.state => {
  switch action {
  | Actions.SetActiveScene(...) => ...
  | Actions.SetNavigation(...) => ...
  | Actions.NavigationCompleted(...) => ...
  | _ => state
  }
}
```

**3. HotspotReducer.res (~60 lines)**
```rescript
// HotspotReducer.res
let handleHotspotAction = (state: Types.state, action): Types.state => {
  switch action {
  | Actions.AddHotspot(...) => ...
  | Actions.DeleteHotspot(...) => ...
  | Actions.ClearHotspots(...) => ...
  | _ => state
  }
}
```

**4. ProjectReducer.res (~100 lines)**
```rescript
// Contains parseProject, parseScene, parseHotspots
// And LoadProject action handler
```

**Composed Reducer.res (~200 lines)**
```rescript
// Reducer.res
open SceneReducer
open NavigationReducer
open HotspotReducer
open ProjectReducer

let reducer = (state: Types.state, action: Actions.action): Types.state => {
  // Simple actions handled inline
  switch action {
  | SetPreloadingScene(index) => {...state, preloadingSceneIndex: index}
  | SetLinkDraft(draft) => {...state, linkDraft: draft}
  // ... other simple setters
  | _ => 
    // Delegate to domain reducers
    state
    ->SceneReducer.handleSceneAction(action)
    ->NavigationReducer.handleNavigationAction(action)
    ->HotspotReducer.handleHotspotAction(action)
    ->ProjectReducer.handleProjectAction(action)
  }
}
```

### Strategy B: Group by Complexity

Keep simple one-liners in main reducer:
```rescript
| SetIsLinking(val) => {...state, isLinking: val}
| SetTeasing(val) => {...state, isTeasing: val}
```

Extract complex handlers:
```rescript
| DeleteScene(index) => ReducerHelpers.handleDeleteScene(state, index)
| LoadProject(json) => ReducerHelpers.parseProject(json)
```

## Recommended Approach: Hybrid

1. Keep Reducer.res as the main file with simple actions
2. Create `ReducerHelpers.res` for complex transformations
3. Move parsing functions to `ReducerHelpers.res`

This maintains the existing pattern while reducing line count.

## Task Steps

1. [ ] Identify action handlers that are >10 lines
2. [ ] Move parsing functions (parseProject, parseScene, parseHotspots) to ReducerHelpers
3. [ ] Move complex handlers (DeleteScene, LoadProject) to helpers
4. [ ] Keep simple setters inline
5. [ ] Verify all state transitions work correctly
6. [ ] Confirm line count is under 450

## Acceptance Criteria
- [ ] `Reducer.res` is under 450 lines
- [ ] Helper modules created as needed
- [ ] All actions dispatch correctly
- [ ] State mutations are correct
- [ ] `npm run res:build` succeeds
- [ ] Application works unchanged

## Files to Create
- `src/core/ReducerHelpers.res`

## Files to Modify
- `src/core/Reducer.res`

## Testing
1. Build the project
2. Perform each action type:
   - Add scene (upload image)
   - Delete scene
   - Reorder scenes (drag-drop)
   - Add hotspot link
   - Delete hotspot
   - Load project
   - Save project
   - Toggle simulation
3. Verify state changes correctly in all cases

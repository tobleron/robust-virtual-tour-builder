# Extract Business Logic from ViewerManager.res

## Overview
ViewerManager.res currently contains 320+ lines of mixed UI and business logic, violating the architecture principle that business logic should reside in the systems layer. This task involves extracting coordinate calculations, linking logic, and state management into pure functions in a new ViewerLinkingSystem.

## Current Issues
- Mouse event handling, coordinate calculations, and linking logic embedded in React component
- Direct `GlobalStateBridge.getState()` calls bypassing centralized store pattern
- Side effects (DOM manipulations, event listeners) mixed with pure calculations
- Component violates single responsibility principle

## Implementation Steps

### 1. Create ViewerLinkingSystem.res
Location: `/src/systems/ViewerLinkingSystem.res`

**Required Functions:**
```rescript
// Pure function for mouse coordinate normalization
let normalizeMouseCoordinates = (x: float, y: float, rect: Dom.domRect): (float, float) => {
  let xNorm = x /. rect.width *. 2.0 -. 1.0
  let yNorm = y /. rect.height *. 2.0 -. 1.0
  (xNorm, yNorm)
}

// Pure function for link draft creation
let createLinkDraft = (
  mouseCoords: (float, float),
  currentScene: option<scene>,
  viewer: option<Viewer.t>
): result<linkDraft, string> => {
  // Implementation to be extracted from ViewerManager lines 98-105
}

// Pure function for draft validation
let validateLinkTarget = (draft: linkDraft, scenes: array<scene>): result<linkDraft, string> => {
  // Validation logic
}

// Pure function for hotspot position calculation
let calculateHotspotPosition = (draft: linkDraft): (float, float) => {
  // Coordinate calculation logic
}
```

### 2. Extract Coordinate Logic
Move lines 48-49 from ViewerManager.res:
```rescript
// Before: Inline in component
React.useEffect1(() => {
  let handleMouseMove = (e) => {
    let rect = Dom.getBoundingClientRect(canvas)
    let x = Obj.magic(e)["clientX"] -. rect.left
    let y = Obj.magic(e)["clientY"] -. rect.top
    let xNorm = x /. rect.width *. 2.0 -. 1.0
    let yNorm = y /. rect.height *. 2.0 -. 1.0
    // ... rest of mouse handling
  }
  // ...
}, [canvas])

// After: Delegate to system
React.useEffect1(() => {
  let handleMouseMove = (e) => {
    let rect = Dom.getBoundingClientRect(canvas)
    let x = Obj.magic(e)["clientX"] -. rect.left
    let y = Obj.magic(e)["clientY"] -. rect.top
    let (xNorm, yNorm) = ViewerLinkingSystem.normalizeMouseCoordinates(x, y, rect)
    // ... rest of mouse handling
  }
  // ...
}, [canvas])
```

### 3. Extract Linking Draft Creation
Move lines 98-105 from ViewerManager.res:
```rescript
// Before: Inline creation in component
let initialDraft = Some({
  yaw,
  pitch,
  camYaw,
  camPitch,
  camHfov: hfov,
  intermediatePoints: None,
})

// After: System function call
switch ViewerLinkingSystem.createLinkDraft((yaw, pitch), currentScene, viewer) {
| Ok(draft) => dispatch(Actions.SetLinkDraft(Some(draft)))
| Error(msg) => Logger.error(~module_="ViewerManager", ~message=msg, ())
}
```

### 4. Replace GlobalStateBridge Calls
Replace all direct global state access with store-based access:
```rescript
// Before: Direct global access
let currentScene = GlobalStateBridge.getState().scenes[state.activeIndex]

// After: Store pattern
let currentScene = Belt.Array.get(state.scenes, state.activeIndex)
```

### 5. Update ViewerManager.res Structure
Restructure ViewerManager to only handle:
- UI rendering and event binding
- Dispatching actions to the centralized store
- Delegating all business logic to ViewerLinkingSystem

## Testing Requirements
- Add unit tests for all ViewerLinkingSystem functions
- Test coordinate normalization with various input ranges
- Test link draft creation with valid/invalid inputs
- Test validation logic with edge cases
- Ensure ViewerManager component tests still pass

## Completion Criteria
- [ ] ViewerLinkingSystem.res created with all required functions
- [ ] All coordinate and linking logic extracted from ViewerManager
- [ ] No direct GlobalStateBridge.getState() calls remain
- [ ] ViewerManager only handles UI concerns
- [ ] All existing functionality preserved
- [ ] Tests pass for both new system and updated component
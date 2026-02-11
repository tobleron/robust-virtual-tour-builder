# [1336] Replace GlobalStateBridge With React Context

## Priority: P2 (Medium)

## Context
`GlobalStateBridge.res` is a global module-level singleton that exposes `dispatch()` and `getState()` to any module — including non-React code. While convenient, it:
- **Breaks unidirectional data flow**: Any module can mutate state without going through the React tree
- **Cannot be mocked in tests**: Unit tests require `%raw` hacks to inject test state
- **Creates hidden coupling**: `DATA_FLOW.md` shows unidirectional flow, but `GlobalStateBridge` enables backdoor dispatching from 10+ modules

### Current Consumers (from grep)

Modules that call `GlobalStateBridge.dispatch(...)`:
- `SceneLoader.res`
- `SceneTransition.res`
- `NavigationController.res`
- `ViewerSystem.res`
- And potentially others

Modules that call `GlobalStateBridge.getState()`:
- `SceneLoader.res` (reads scenes, activeIndex)
- `SceneTransition.res` (reads transition.type_)
- `NavigationGraph.res` (reads viewer state)

## Objective
Replace `GlobalStateBridge.dispatch(...)` and `GlobalStateBridge.getState()` with context-injected alternatives:

1. **For React components**: Use `AppContext.useAppDispatch()` and `AppContext.useAppState()`
2. **For non-React modules** (called from hooks): Pass `dispatch` and `state` as function parameters

## Implementation

### Phase 1: Audit Usage
```bash
grep -r "GlobalStateBridge\." src/ --include="*.res" -c
```
Categorize each usage as:
- **A**: Called from a React component/hook → migrate to Context
- **B**: Called from pure logic module → add `dispatch`/`state` parameter

### Phase 2: Refactor Category B (Pure Logic Modules)

Example for `SceneLoader.loadNewScene`:
```rescript
// OLD:
let loadNewScene = (~targetSceneId, ...) => {
  let state = GlobalStateBridge.getState()
  // ...
  GlobalStateBridge.dispatch(DispatchNavigationFsmEvent(...))
}

// NEW:
let loadNewScene = (~targetSceneId, ~state, ~dispatch, ...) => {
  // state and dispatch are now explicit parameters
  dispatch(DispatchNavigationFsmEvent(...))
}
```

### Phase 3: Refactor Category A (React Components)
Components already have access to `AppContext.useAppDispatch()`. Replace any `GlobalStateBridge.dispatch(...)` calls.

### Phase 4: Deprecate GlobalStateBridge
After all consumers are migrated:
- Add deprecation comment to `GlobalStateBridge.res`
- Optionally delete if zero remaining imports

## Key Constraint
**This task has a dependency on Task 1332** (Remove TransitionLock from Navigation). Many `GlobalStateBridge` calls are in `SceneLoader` and `SceneTransition`, which are being refactored as part of the Navigation Supervisor migration. It's most efficient to do both in the same pass.

## Verification
- [ ] `grep -r "GlobalStateBridge\." src/ --include="*.res"` shows only the definition file
- [ ] `npm run build` passes cleanly
- [ ] All E2E tests pass
- [ ] Unit tests can inject mock dispatch/state without `%raw`

## Estimated Effort: 2 days

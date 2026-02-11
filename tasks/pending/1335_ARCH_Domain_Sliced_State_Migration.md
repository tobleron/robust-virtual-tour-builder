# [1335] Domain-Sliced State Migration — Break Up the God Object

## Priority: P2 (Medium)

## Context
`Types.res` defines a single `state` record with 23+ fields (line 284-313). Every state change passes through the 441-line `Reducer.res`. Every component that subscribes to state via `AppContext.useAppState()` receives the **entire** object, causing:
- **Excessive re-renders**: `ViewerHUD`, `LockFeedback`, and other lightweight components re-render on unrelated state changes (e.g., a tour name change re-renders the navigation indicator)
- **Testing friction**: The reducer is coupled to all domains — testing navigation logic requires constructing a full state with upload, simulation, and timeline fields
- **Maintenance burden**: `Reducer.res` at 441 LOC and drag score 5.50 is already flagged by the dev-system

## Objective
Split the monolithic `state` into **domain slices**, each with its own sub-reducer. Components subscribe only to the slices they need.

### Proposed State Structure

```rescript
type state = {
  // Domain Slices
  project: ProjectState.t,        // tourName, scenes, inventory, sceneOrder, timeline, etc.
  viewer: ViewerState.t,          // activeIndex, activeYaw, activePitch, transition, preloadingSceneIndex
  navigation: NavigationState.t,  // navigation, navigationFsm, currentJourneyId, incomingLink, autoForwardChain
  simulation: SimulationState.t,  // simulation record (already exists!)
  editor: EditorState.t,          // isLinking, linkDraft, pendingReturnSceneName
  app: AppState.t,                // appMode, sessionId, isTeasing
}
```

### Proposed Selector Hooks

```rescript
// Instead of:
let state = AppContext.useAppState()  // All 23+ fields, re-renders on ANY change

// Use:
let projectState = AppContext.useProjectState()      // Only project fields
let viewerState = AppContext.useViewerState()         // Only viewer fields
let navState = AppContext.useNavigationState()        // Only navigation fields
```

## Implementation Strategy: Incremental Migration

**DO NOT** attempt a big-bang refactor. Migrate one slice at a time.

### Phase 1: Extract `NavigationState` (Smallest, most self-contained)
1. Create `src/core/NavigationState.res` with type + sub-reducer
2. Move `navigation`, `navigationFsm`, `currentJourneyId`, `incomingLink`, `autoForwardChain` out of `state`
3. Add `navigation: NavigationState.t` to `state`
4. Create `NavigationState.reducer` and call it from `Reducer.res`
5. Add `AppContext.useNavigationState()` selector hook

### Phase 2: Extract `ViewerState` slice
1. Move `activeIndex`, `activeYaw`, `activePitch`, `transition`, `preloadingSceneIndex`

### Phase 3: Extract `EditorState` slice
1. Move `isLinking`, `linkDraft`, `pendingReturnSceneName`

### Phase 4: Extract `ProjectState` slice (Largest, most impactful)
1. Move `tourName`, `scenes`, `inventory`, `sceneOrder`, `timeline`, `exifReport`, `deletedSceneIds`, `lastUsedCategory`

### Phase 5: Update all components to use selector hooks

## Key Constraints
- `simulation` already has `SimulationState` type in `Types.res` — just needs extraction
- `AppContext.useAppState()` must continue to work during migration (returns the full composed state)
- Each phase must pass `npm run build` independently
- The dev-system might flag new modules — that's expected

## Verification
- [ ] `Reducer.res` LOC drops below 300 (target from dev-system)
- [ ] Components using selector hooks re-render less frequently
- [ ] `npm run build` passes cleanly after each phase
- [ ] All E2E tests pass after final phase

## Estimated Effort: 5 days (incrementally across sprints)

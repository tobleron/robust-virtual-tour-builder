# 1610 - Investigate AppStateBridge Update Lag Impact

## Priority: LOW-MEDIUM
## Category: State Stability Investigation

## Objective
Audit all side-channel state reads via `AppStateBridge.getState()` during active state transitions and determine if the asynchronous bridge update (via `React.useEffect1`) creates observable bugs.

## Problem
`AppContext.res` lines 265-269:
```rescript
React.useEffect1(() => {
  stateBridgeRef := state
  AppStateBridge.updateState(state)
  None
}, [state])
```

`useEffect` fires after render, creating a window where:
- React has reduced to state N
- Components render with state N
- But `AppStateBridge.stateValueRef` still holds state N-1
- Side-channel consumers reading during this window get stale data

Key consumers of `AppStateBridge.getState()` / `AppContext.getBridgeState()`:
1. `NavigationSupervisor.dispatchInternal` → reads state implicitly
2. `SceneTransition.finalizeSwap` → calls `getState()` to check `activeIndex`
3. `ViewerManagerSceneLoad.handleMainSceneLoad` → uses `getState()` bridge
4. `ViewerManagerLifecycle.useLinkingAndSimUI` → calls `getState()` for current state
5. Various `HotspotLine.updateLines` calls → uses bridge state

## Investigation Steps
1. Add timing instrumentation: log timestamps when `dispatchRaw` fires vs when `AppStateBridge.updateState` fires
2. Measure the gap in realistic scenarios (navigation, upload, simulation)
3. Identify if any consumer makes a decision during this gap that produces a visible bug
4. Assess whether moving the bridge update to synchronous (in the reducer or dispatch wrapper) causes React performance issues

## Potential Solutions
- **Option A (Minimal)**: Keep async update but add `dispatchRaw` wrapper that synchronously updates the bridge ref before React re-renders
- **Option B (Safer)**: Remove `AppStateBridge` entirely and pass `getState` functions to all side-channel systems
- **Option C (Pragmatic)**: Accept the lag but add guards in critical path consumers (e.g., `SceneTransition.finalizeSwap` already receives `getState` explicitly)

## Files to Investigate
- `src/core/AppContext.res` — bridge update timing
- `src/core/AppStateBridge.res` — consumer API
- `src/systems/Scene/SceneTransition.res` — uses `getState` parameter (safe)
- `src/components/ViewerManager/ViewerManagerSceneLoad.res` — uses `getState` parameter (safe)
- `src/systems/Navigation/NavigationSupervisor.res` — uses `AppStateBridge.dispatch` (may be affected)

## Verification
- Instrument and run E2E: `rapid-scene-switching.spec.ts`
- Check if state mismatch logs appear during rapid scene clicks

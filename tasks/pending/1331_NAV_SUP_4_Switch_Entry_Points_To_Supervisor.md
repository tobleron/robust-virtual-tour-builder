# 1331: [NAV-SUP 4/6] Switch Entry Points to Supervisor

## Parent Task
[1306_ARCH_Navigation_Supervisor_Pattern](./1306_ARCH_Navigation_Supervisor_Pattern.md)

## Objective
Route all navigation initiation points through `NavigationSupervisor.requestNavigation()` instead of directly dispatching `DispatchNavigationFsmEvent(UserClickedScene(...))`. This is the "flip the switch" moment — after this task, all scene transitions flow through the Supervisor.

## Context
Currently, navigation is initiated by dispatching an action to the reducer, which updates `navigationFsm` in state, which triggers a `useEffect` in `NavigationController`, which calls `SceneLoader`. The Supervisor model simplifies this:

```
BEFORE: SceneSwitcher → dispatch(FSM Event) → Reducer → State → useEffect → SceneLoader
AFTER:  SceneSwitcher → NavigationSupervisor.requestNavigation() → SceneLoader (directly)
```

The FSM state (`navigationFsm`) in the reducer is still updated (for UI reactivity), but the **control flow** is owned by the Supervisor.

## Implementation

### [MODIFY] `src/systems/Scene/SceneSwitcher.res`

**Update `navigateToScene` to call Supervisor:**
```rescript
// After building the actions array and before dispatch(Batch(actions)):

// Trigger Supervisor FIRST (this auto-cancels any previous navigation)
state.scenes[targetIdx]->Option.forEach(ts => {
  NavigationSupervisor.requestNavigation(ts.id)
})

// Then dispatch state updates (for UI)
dispatch(Batch(actions))
```

**Remove redundant `DispatchNavigationFsmEvent(UserClickedScene(...))` from actions array** — the Supervisor will coordinate the FSM events instead.

### [MODIFY] `src/systems/Navigation/NavigationController.res`

**Update `useNavigationFSM` hook:**

The `Preloading` case should now check if Supervisor initiated the navigation:
```rescript
| Preloading({targetSceneId, isAnticipatory}) =>
    // Only call SceneLoader if NOT already managed by Supervisor
    if !NavigationSupervisor.isBusy() || isAnticipatory {
      Scene.Loader.loadNewScene(~sourceSceneId?, ~targetSceneId, ~isAnticipatory)
      // ... timeout logic
    }
    // If Supervisor is managing, do nothing — it's already calling SceneLoader
```

**Alternatively (cleaner)**: Have the Supervisor call `SceneLoader.loadNewScene` directly inside `requestNavigation`, removing the need for the `useEffect` in `NavigationController` to trigger loading at all. The `useEffect` would then only handle UI side-effects (stabilizing, journey completion).

### [MODIFY] `src/components/SceneList/SceneItem.res`
If scene items dispatch `UserClickedScene` directly (instead of going through `SceneSwitcher`), update them to call `NavigationSupervisor.requestNavigation()` as well.

### [MODIFY] `src/systems/Simulation/SimulationNavigation.res`
Simulation autopilot uses `SceneSwitcher.navigateToScene` — verify it inherits the Supervisor flow automatically.

## Key Decisions
1. **FSM remains for UI state**: The `navigationFsm` field in state is still updated (via `DispatchNavigationFsmEvent`) so that `LockFeedback`, `ViewerHUD`, and other UI components continue to react to loading/transitioning states.
2. **Supervisor owns the control flow**: The Supervisor decides when to call `SceneLoader` and `SceneTransition`. The FSM reducer just reflects what the Supervisor reports.
3. **InteractionGuard still applies**: `SceneSwitcher.navigateToScene` still runs through `InteractionGuard.attempt` before calling the Supervisor.

## Verification
- [ ] Clicking a scene in the sidebar triggers navigation via Supervisor
- [ ] Clicking a hotspot triggers navigation via Supervisor
- [ ] Simulation autopilot navigates via Supervisor
- [ ] Rapid-fire clicks: only the last scene loads (previous cancelled)
- [ ] `NavigationFSM` state updates still drive UI changes
- [ ] `npm run build` passes cleanly
- [ ] E2E: `rapid-scene-switching.spec.ts` passes
- [ ] E2E: `simulation-teaser.spec.ts` passes

## Files Modified
- `src/systems/Scene/SceneSwitcher.res` (~15 lines changed)
- `src/systems/Navigation/NavigationController.res` (~20 lines changed)
- `src/components/SceneList/SceneItem.res` (verify, ~5 lines)
- `src/systems/Simulation/SimulationNavigation.res` (verify, ~0-5 lines)

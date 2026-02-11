# 1330: [NAV-SUP 3/6] Wire SceneLoader & SceneTransition to Supervisor

## Parent Task
[1306_ARCH_Navigation_Supervisor_Pattern](./1306_ARCH_Navigation_Supervisor_Pattern.md)

## Objective
Refactor `SceneLoader.res` and `SceneTransition.res` to operate under the Supervisor's coordination instead of managing `TransitionLock` directly. Each function receives an `AbortSignal` and a `taskId` so it can:
1. Check for cancellation before proceeding with expensive operations
2. Report phase transitions to the Supervisor (not to TransitionLock)

## Why This Is The Hardest Task
`SceneLoader.res` (390 LOC) is the most tightly coupled to `TransitionLock`. It calls `acquire`, `preempt`, `release`, and `transition` in multiple code paths. This task replaces those calls with Supervisor-coordinated equivalents while preserving the exact same externally observable behavior.

## Implementation

### Strategy: Dual-Mode Transition Period
To avoid a "big bang" refactor, add `AbortSignal` as an **optional parameter** so existing callers continue to work. The Supervisor path is activated when `signal` is provided.

### [MODIFY] `src/systems/Scene/SceneLoader.res`

**1. Update `loadNewScene` signature:**
```rescript
let rec loadNewScene = (
  ~sourceSceneId: option<string>=?,
  ~targetSceneId: string,
  ~isAnticipatory=false,
  ~taskId: option<string>=?,       // NEW: Supervisor task ID
  ~signal: option<AbortSignal.t>=?, // NEW: Cancellation signal
) => {
```

**2. Replace `TransitionLock.acquire` guard:**
```rescript
// OLD:
let canProceed = TransitionLock.acquire("SceneLoader", Loading(targetSceneId))

// NEW (when taskId is provided):
let canProceed = switch taskId {
| Some(tid) =>
    // In Supervisor mode: always proceed — the Supervisor already cancelled the previous task
    NavigationSupervisor.transitionTo(tid, Loading(tid, targetSceneId))
    Ok()
| None =>
    // Legacy mode: keep TransitionLock behavior during migration
    TransitionLock.acquire("SceneLoader", Loading(targetSceneId))
}
```

**3. Add abort-check before viewer creation:**
```rescript
// Before creating a new Pannellum viewer instance (the expensive operation):
switch signal {
| Some(s) if BrowserBindings.AbortSignal.aborted(s) =>
    Logger.info(~module_="SceneLoader", ~message="LOAD_ABORTED_BEFORE_VIEWER_CREATION", ())
    switch taskId {
    | Some(tid) => NavigationSupervisor.abort(tid)
    | None => TransitionLock.release("SceneLoader_Aborted")
    }
    // Early return — do not create the viewer
| _ => () // Proceed normally
}
```

**4. Update `Events.onSceneLoad` to notify Supervisor:**
```rescript
// After texture loads successfully:
switch taskId {
| Some(tid) =>
    NavigationSupervisor.transitionTo(tid, Swapping(tid, loadedScene.id))
| None =>
    // Legacy path (TransitionLock)
    TransitionLock.transition("SceneLoader_Loaded", Swapping(loadedScene.id))
}
```

**5. Remove retry scheduling logic in Supervisor mode:**
The `retryScheduled` ref and the 100ms retry timeout are no longer needed when the Supervisor is coordinating — the Supervisor auto-cancels the previous task. In Supervisor mode, skip the retry scheduling entirely.

### [MODIFY] `src/systems/Scene/SceneTransition.res`

**1. Update `performSwap` to accept `taskId`:**
```rescript
let performSwap = (loadedScene: scene, _loadStartTime, ~taskId: option<string>=?) => {
```

**2. Replace `TransitionLock.transition` calls:**
```rescript
// OLD:
TransitionLock.transition("SceneTransition_StartSwap", Swapping(loadedScene.id))

// NEW:
switch taskId {
| Some(tid) => NavigationSupervisor.transitionTo(tid, Swapping(tid, loadedScene.id))
| None => TransitionLock.transition("SceneTransition_StartSwap", Swapping(loadedScene.id))
}
```

**3. Update `cleanupViewerInstance` to complete via Supervisor:**
```rescript
// OLD:
TransitionLock.release("SceneTransition_CleanupDone", ~onlyIfPhase=targetPhase)

// NEW:
switch taskId {
| Some(tid) => NavigationSupervisor.complete(tid)
| None => TransitionLock.release("SceneTransition_CleanupDone", ~onlyIfPhase=targetPhase)
}
```

### [MODIFY] `src/systems/Navigation/NavigationController.res`

**Update `useNavigationFSM` to pass `taskId` and `signal` down:**
```rescript
| Preloading({targetSceneId, isAnticipatory}) =>
    // Get current Supervisor task info
    let taskInfo = NavigationSupervisor.getCurrentTask()
    Scene.Loader.loadNewScene(
      ~sourceSceneId?,
      ~targetSceneId,
      ~isAnticipatory,
      ~taskId=?taskInfo->Option.map(t => t.id),
      ~signal=?taskInfo->Option.map(t => t.signal), // requires storing signal in task
    )
```

## Key Constraints
- **No behavioral change** for existing TransitionLock callers (dual-mode)
- **All TransitionLock calls remain intact** during this task (removed in Task 1331)
- The `signal` parameter is `option` — when `None`, the legacy TransitionLock path executes
- Zero new `Obj.magic` or `%raw` usage

## Verification
- [ ] `npm run build` passes cleanly
- [ ] Navigation still works identically via the legacy path (no signal provided)
- [ ] Logger output shows Supervisor events when triggered via Supervisor path
- [ ] No deadlocks during rapid-fire scene clicks (test via E2E `rapid-scene-switching.spec.ts`)

## Files Modified
- `src/systems/Scene/SceneLoader.res` (~30 lines changed)
- `src/systems/Scene/SceneTransition.res` (~15 lines changed)
- `src/systems/Navigation/NavigationController.res` (~10 lines changed)

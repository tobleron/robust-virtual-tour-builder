# 1332: [NAV-SUP 5/6] Remove TransitionLock From Navigation Pipeline

## Parent Task
[1306_ARCH_Navigation_Supervisor_Pattern](./1306_ARCH_Navigation_Supervisor_Pattern.md)

## Objective
Remove all `TransitionLock` calls from the navigation pipeline. After tasks 1328–1331, the Supervisor owns navigation coordination. `TransitionLock` calls in `SceneLoader`, `SceneTransition`, and `NavigationController` are now dead code in the Supervisor path.

## Prerequisites
- Task 1331 completed (all entry points route through Supervisor)
- E2E tests passing with Supervisor active

## Scope — Files With TransitionLock Usage

Current `TransitionLock` consumers (from grep):

| File | Usage | Action |
|------|-------|--------|
| `SceneLoader.res` | `acquire`, `preempt`, `release` | **REMOVE** — Supervisor manages |
| `SceneTransition.res` | `transition`, `release`, `releaseIf` | **REMOVE** — Supervisor manages |
| `NavigationController.res` | `release` (in error case) | **REMOVE** — Supervisor manages |
| `ViewerSystem.res` | `isIdle` check | **MIGRATE** to `NavigationSupervisor.isIdle()` |
| `SceneList.res` | `isIdle` check (guard clicks) | **MIGRATE** to `NavigationSupervisor.isIdle()` |
| `UtilityBar.res` | `isIdle` check (guard buttons) | **MIGRATE** to `NavigationSupervisor.isIdle()` |
| `ViewerManagerLogic.res` | Status listener | **MIGRATE** to `NavigationSupervisor.addStatusListener()` |
| `ViewerManagerLifecycle.res` | Status listener | **MIGRATE** to `NavigationSupervisor.addStatusListener()` |
| `LockFeedback.res` | Phase listener (renders progress) | **MIGRATE** to Supervisor status (Task 1333) |
| `StateInspector.res` | Debug display | **MIGRATE** to Supervisor debug info |

## Implementation

### Phase A: Remove from Core Navigation (SceneLoader, SceneTransition, NavigationController)

**[MODIFY] `src/systems/Scene/SceneLoader.res`**
- Remove the `option<string>` dual-mode `taskId` parameter — make Supervisor-mode the only mode
- Remove `TransitionLock.acquire(...)` / `TransitionLock.preempt(...)` calls
- Remove `TransitionLock.release(...)` in error/abort paths
- Remove the `retryScheduled` ref and retry-after-100ms logic entirely
- Keep the safety timeout (`currentLoadTimeout`) — but have it call `NavigationSupervisor.abort(taskId)` instead of `TransitionLock.release(...)`

**[MODIFY] `src/systems/Scene/SceneTransition.res`**
- Remove `TransitionLock.transition(...)` calls
- Remove `TransitionLock.release(...)` / `releaseIf(...)` calls
- `cleanupViewerInstance`: call `NavigationSupervisor.complete(taskId)` instead
- `finalizeSwap`: remove the `TransitionLock.releaseIf(...)` safety — Supervisor guarantees completion

**[MODIFY] `src/systems/Navigation/NavigationController.res`**
- Remove `TransitionLock.release("NavigationController_NotFound")` in Stabilizing error path
- Replace with `NavigationSupervisor.abort(taskId)`

### Phase B: Migrate Read-Only Consumers

**[MODIFY] `src/systems/ViewerSystem.res`**
```rescript
// OLD:
if TransitionLock.isIdle() { ... }
// NEW:
if NavigationSupervisor.isIdle() { ... }
```

**[MODIFY] `src/components/SceneList.res`**
```rescript
// Same pattern — replace isIdle check
```

**[MODIFY] `src/components/UtilityBar.res`**
```rescript
// Same pattern — replace isIdle check
```

**[MODIFY] `src/components/ViewerManagerLogic.res`**
```rescript
// OLD:
TransitionLock.addChangeListener(phase => ...)
// NEW:
NavigationSupervisor.addStatusListener(status => ...)
```

**[MODIFY] `src/components/ViewerManager/ViewerManagerLifecycle.res`**
```rescript
// Same pattern
```

**[MODIFY] `src/utils/StateInspector.res`**
```rescript
// Update debug output to show NavigationSupervisor.getStatus()
```

## What Happens to `TransitionLock.res`?
**DO NOT DELETE IT YET.** It may still be used by non-navigation features in the future or have edge-case callers discovered during testing. After this task, audit for any remaining imports:
```bash
grep -r "TransitionLock\." src/ --include="*.res"
```
If zero results, mark it as deprecated in `MAP.md`. Deletion can happen in a future cleanup task.

## Verification
- [ ] `grep -r "TransitionLock\." src/systems/Scene/ src/systems/Navigation/` returns **0 results**
- [ ] `npm run build` passes cleanly
- [ ] E2E: `rapid-scene-switching.spec.ts` passes
- [ ] E2E: `upload-link-export-workflow.spec.ts` passes (navigation during workflow)
- [ ] E2E: `simulation-teaser.spec.ts` passes
- [ ] E2E: `robustness.spec.ts` passes
- [ ] No deadlocks during rapid scene clicking (manual QA)

## Files Modified
- `src/systems/Scene/SceneLoader.res` (~40 lines removed/changed)
- `src/systems/Scene/SceneTransition.res` (~20 lines removed/changed)
- `src/systems/Navigation/NavigationController.res` (~5 lines removed/changed)
- `src/systems/ViewerSystem.res` (~3 lines changed)
- `src/components/SceneList.res` (~3 lines changed)
- `src/components/UtilityBar.res` (~3 lines changed)
- `src/components/ViewerManagerLogic.res` (~5 lines changed)
- `src/components/ViewerManager/ViewerManagerLifecycle.res` (~5 lines changed)
- `src/utils/StateInspector.res` (~3 lines changed)

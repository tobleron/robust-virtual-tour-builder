# 1333: [NAV-SUP 6/6] Migrate LockFeedback, Update Docs, Final Validation

## Parent Task
[1306_ARCH_Navigation_Supervisor_Pattern](./1306_ARCH_Navigation_Supervisor_Pattern.md)

## Objective
Complete the Navigation Supervisor migration by:
1. Migrating `LockFeedback.res` to read from `NavigationSupervisor` instead of `TransitionLock`
2. Updating architectural documentation (`MAP.md`, `DATA_FLOW.md`)
3. Deprecating `TransitionLock.res` (or deleting if zero remaining consumers)
4. Running full E2E test suite as final validation

## Implementation

### Part 1: Migrate LockFeedback

**[MODIFY] `src/components/LockFeedback.res`**

`LockFeedback` renders a visual progress/recovery indicator during scene transitions. It currently subscribes to `TransitionLock` phases.

```rescript
// OLD:
let unsub = TransitionLock.addChangeListener(phase => {
  switch phase {
  | Loading(_) => showProgress(...)
  | Swapping(_) => showSwapping(...)
  | Idle => hideProgress(...)
  | _ => ()
  }
})

// NEW:
let unsub = NavigationSupervisor.addStatusListener(status => {
  switch status {
  | Loading(_, sceneId) => showProgress(sceneId)
  | Swapping(_, sceneId) => showSwapping(sceneId)
  | Stabilizing(_, sceneId) => showStabilizing(sceneId)
  | Idle => hideProgress()
  }
})
```

**Timeout/Recovery display:**
- `TransitionLock` had built-in timeout + recovery logic. The Supervisor handles timeouts differently (the `NavigationController` timeout dispatches `LoadTimeout` to the FSM).
- If `LockFeedback` also shows a "recovery" button when transitions hang, wire it to `NavigationSupervisor.abort(currentTaskId)` instead of `TransitionLock.forceRelease()`.

### Part 2: Deprecate or Delete TransitionLock

Run the audit:
```bash
grep -r "TransitionLock\." src/ --include="*.res" | grep -v "TransitionLock.res"
```

**If zero results:**
- Add deprecation header to `TransitionLock.res`:
  ```rescript
  /* @deprecated — Navigation now coordinated by NavigationSupervisor.res.
     This module is retained only for potential non-navigation locking use cases.
     See task 1306 for migration history.
  */
  ```
- Update `MAP.md`: Change tag from `#concurrency #locking #safety` to `#deprecated #concurrency`

**If remaining results exist:**
- Document the remaining callers
- Create a follow-up task for migrating them

### Part 3: Update MAP.md

**[MODIFY] `MAP.md`**

Add the new module:
```markdown
*   [src/systems/Navigation/NavigationSupervisor.res](src/systems/Navigation/NavigationSupervisor.res): Centralized coordinator for scene transitions using structured concurrency. `#navigation` `#orchestration` `#concurrency`
```

Update `TransitionLock` entry:
```markdown
*   [src/core/TransitionLock.res](src/core/TransitionLock.res): ~~Global lock for scene transitions.~~ DEPRECATED — replaced by NavigationSupervisor for navigation flows. `#deprecated` `#concurrency`
```

### Part 4: Update DATA_FLOW.md

**[MODIFY] `DATA_FLOW.md`**

Update the **Scene Navigation** flow to reflect the Supervisor:
```markdown
User Click Event
  → [src/components/SceneList/SceneItem.res] or [src/components/HotspotLayer.res]
  → [src/core/InteractionGuard.res] checks cooldowns
  → [src/systems/Navigation/NavigationSupervisor.res] receives intent (auto-cancels previous)
  → [src/systems/Scene/SceneLoader.res] loads with AbortSignal
  → [src/systems/Scene/SceneTransition.res] performs swap
  → [src/systems/Navigation/NavigationSupervisor.res] completes task
  → [src/components/LockFeedback.res] renders status from Supervisor
```

Remove `TransitionLock` from the navigation flow diagram.

### Part 5: Full E2E Validation

Run the **complete** E2E test suite:
```bash
npx playwright test
```

**All 15 spec files must pass**, specifically:
- [ ] `rapid-scene-switching.spec.ts` — Core Supervisor test
- [ ] `robustness.spec.ts` — Concurrent transitions
- [ ] `simulation-teaser.spec.ts` — Autopilot uses navigation
- [ ] `upload-link-export-workflow.spec.ts` — Navigation during workflow
- [ ] `save-load-recovery.spec.ts` — State persistence with new Supervisor
- [ ] `error-recovery.spec.ts` — Error handling paths
- [ ] `feature-deep-dive.spec.ts` — Advanced features

### Part 6: Unit Test Update

**[MODIFY] `tests/unit/TransitionLock_v.test.res`**
- Rename to `NavigationSupervisor_v.test.res` or create new
- Test:
  - `requestNavigation` sets status to Loading
  - Second `requestNavigation` cancels the first (abort called)
  - `complete` resets to Idle
  - `abort` resets to Idle
  - Stale `taskId` operations are ignored
  - `addStatusListener` fires on each transition

## Verification Checklist
- [ ] `LockFeedback` renders correctly during navigation
- [ ] `TransitionLock` has zero navigation-related consumers
- [ ] `MAP.md` updated with `NavigationSupervisor` entry
- [ ] `DATA_FLOW.md` updated with new navigation flow
- [ ] All E2E tests pass
- [ ] Unit tests for `NavigationSupervisor` pass
- [ ] `npm run build` passes cleanly
- [ ] No `console.log` in any modified files

## Files Modified
- `src/components/LockFeedback.res` (~20 lines changed)
- `src/core/TransitionLock.res` (deprecation comment added)
- `MAP.md` (~5 lines changed)
- `DATA_FLOW.md` (~15 lines changed)
- `tests/unit/NavigationSupervisor_v.test.res` (new, ~80 lines)

# FSM Interaction Logic Overhaul - Fix System Locking Issues

## Priority: **CRITICAL - P0**

## Issue Summary

The application's FSM (Finite State Machine) locking logic is overly aggressive, causing poor UX where:
1. **UI dims on every scene click** - The entire interface locks when users click any scene item
2. **Cannot interrupt scene loading** - Users cannot cancel/change target during preload
3. **Excessive lock duration** - System remains locked through Preloading → Transitioning → Stabilizing (~1-2 seconds)
4. **Race condition lockouts** - Rapid clicking causes application hangs due to compounded throttling

## Root Cause Analysis

### Problem 1: Overly Broad Locking Logic
**Location**: `src/core/AppContext.res:179-194`

```rescript
let useIsSystemLocked = () => {
  let state = useAppState()
  switch state.appMode {
  | Interactive(s) =>
    switch s.navigation {
    | IdleFsm => false
    | _ => true  // ⚠️ LOCKS ON ANY NAVIGATION STATE
    }
  | _ => // other cases
  }
}
```

**Issue**: The function locks the system for ALL NavigationFSM states:
- `Preloading` - Loading scene texture (interruptible by design)
- `Transitioning` - CSS crossfade animation (non-interruptible)
- `Stabilizing` - Post-transition stabilization (interruptible)
- `ErrorFsm` - Error recovery (interruptible)

**Correct Behavior**: Only `Transitioning` state should lock the UI. All other states support interruption per the FSM design (see `NavigationFSM.res:43-44, 55-56`).

### Problem 2: Visual Overlay Compounds Locking
**Location**: `src/App.res:13-17`

```rescript
{if isSystemLocked {
  <div className="interaction-lock-overlay" />  // Dims entire UI
} else {
  React.null
}}
```

**Issue**: A full-screen overlay appears during ANY navigation state, making the UI feel sluggish and broken. Users see buttons dim when clicking scene items in the sidebar.

### Problem 3: Redundant Permission Checking
**Location**: `src/Hooks.res:91-102`

```rescript
let useIsInteractionPermitted = () => {
  let isQueueProcessing = AppContext.useIsSystemLocked()
  let navigationFsm = AppContext.useNavigationFsm()

  let isTransitioning = switch navigationFsm {
  | IdleFsm | ErrorFsm(_) => false
  | _ => true  // Duplicates isSystemLocked check
  }

  !(isQueueProcessing || isModalOpen || isTransitioning)
}
```

**Issue**: This hook duplicates the navigation state check from `useIsSystemLocked`, creating double-blocking.

### Problem 4: Scene Click Double-Throttling
**Location**: `src/components/SceneList.res:86-101`

```rescript
let timeDiff = now -. ViewerState.state.contents.lastSwitchTime
let throttleLimit = 650.0

if timeDiff < throttleLimit || isSystemLocked {
  // User is blocked
}
```

**Issue**: Scene clicks are throttled by BOTH:
1. Time-based throttle (650ms)
2. FSM state locking (any non-Idle state)

When combined, this creates 1-2 second lockout periods where no interactions are possible.

### Problem 5: State Duplication
**Location**: Multiple files

The navigation FSM state exists in TWO places:
1. `state.navigationFsm` (top-level in `State.res:26`)
2. `state.appMode: Interactive({navigation: navigationFsmState})` (nested)

**Issue**: Components use different states:
- `useNavigationFsm()` → reads top-level `state.navigationFsm`
- `useIsSystemLocked()` → reads nested `appMode.Interactive.navigation`

This requires synchronization logic in the reducer (`Reducer.res:166-169, 205-210`) and is error-prone.

### Problem 6: FSM Design vs UI Implementation Mismatch

**NavigationFSM Design** (`src/systems/Navigation/NavigationFSM.res`):
```rescript
| (Preloading(_), UserClickedScene({targetSceneId})) =>
  Preloading({targetSceneId, attempt: 1, isAnticipatory: false})  // ✅ Supports interruption

| (Transitioning(_), UserClickedScene({targetSceneId})) =>
  Preloading({targetSceneId, attempt: 1, isAnticipatory: false})  // ✅ Supports interruption
```

**UI Implementation** (`AppContext.res:useIsSystemLocked`):
```rescript
| Interactive(s) =>
  switch s.navigation {
  | IdleFsm => false
  | _ => true  // ❌ Blocks all interruptions
  }
```

The FSM is correctly designed to handle interruptions, but the UI layer prevents users from triggering them!

## Architecture Consequences

### Current Flow (Broken):
```
User clicks Scene A
  ↓
NavigationFSM: IdleFsm → Preloading
  ↓
useIsSystemLocked() = true
  ↓
Visual overlay appears (dims UI)
  ↓
Scene click handler blocks further clicks
  ↓
User clicks Scene B → BLOCKED ❌
  ↓
Preloading → Transitioning → Stabilizing → IdleFsm
  ↓
(1-2 seconds later) User can click again
```

### Desired Flow (Fixed):
```
User clicks Scene A
  ↓
NavigationFSM: IdleFsm → Preloading
  ↓
useIsSystemLocked() = false (Preloading is interruptible)
  ↓
NO visual overlay
  ↓
User clicks Scene B → ALLOWED ✅
  ↓
NavigationFSM: Preloading(A) → Preloading(B)
  ↓
Scene A load cancelled, Scene B starts loading
  ↓
When transitioning: Lock UI briefly during CSS animation only
```

## Solution Design

### Option A: Surgical Fix (Recommended)
**Scope**: Minimal changes to `useIsSystemLocked` logic
**Risk**: Low
**Effort**: 1 hour

Modify `useIsSystemLocked` to only lock during `Transitioning`:

```rescript
let useIsSystemLocked = () => {
  let state = useAppState()
  switch state.appMode {
  | Initializing => true
  | SystemBlocking(Uploading(_)) => false
  | SystemBlocking(ProjectLoading(_))
  | SystemBlocking(Exporting(_)) => true
  | SystemBlocking(Summary(_))
  | SystemBlocking(CriticalError(_)) => false
  | Interactive(s) =>
    switch s.navigation {
    | Transitioning(_) => true  // ✅ Only lock during actual CSS transition
    | _ => false  // Allow clicks during Preload, Stabilizing, Error, Idle
    }
  }
}
```

**Benefits**:
- Users can interrupt scene loading by clicking another scene
- No UI dimming during preload/stabilization
- Maintains safety during actual transitions
- Aligns UI behavior with FSM design

### Option B: Add Explicit Interruptibility (Architectural Enhancement)
**Scope**: Add semantic helper to NavigationFSM
**Risk**: Low
**Effort**: 2 hours

Add explicit interruptibility checking:

```rescript
// In NavigationFSM.res
let isInterruptible = (state: distinctState): bool => {
  switch state {
  | IdleFsm => true
  | Preloading(_) => true
  | Transitioning(_) => false  // Only non-interruptible state
  | Stabilizing(_) => true
  | ErrorFsm(_) => true
  }
}

// In AppContext.res
let useIsSystemLocked = () => {
  let state = useAppState()
  switch state.appMode {
  | Interactive(s) => !NavigationFSM.isInterruptible(s.navigation)
  | // ... other cases
  }
}
```

**Benefits**:
- Semantic clarity: FSM declares which states are interruptible
- Self-documenting code
- Easier to extend with new FSM states
- Single source of truth for interruptibility logic

### Option C: Deep Refactor - Eliminate State Duplication
**Scope**: Remove `state.navigationFsm`, keep only `appMode.Interactive.navigation`
**Risk**: High (requires updating all components)
**Effort**: 8+ hours

**Not Recommended**: High risk with marginal benefit. The state duplication is annoying but not critical.

## Implementation Plan

### Phase 1: Surgical Fix (Immediate)
1. **Modify `useIsSystemLocked` logic** (`src/core/AppContext.res`)
   - Change locking condition to only `Transitioning` state
   - Add code comments explaining interruptibility

2. **Update `useIsInteractionPermitted`** (`src/Hooks.res`)
   - Remove redundant navigation FSM check (now handled by `useIsSystemLocked`)
   - Keep only modal and system blocking checks

3. **Adjust scene click throttling** (`src/components/SceneList.res`)
   - Reduce time-based throttle from 650ms to 200ms
   - Document that FSM handles interruption logic

4. **Testing**:
   - Rapid scene clicking no longer hangs
   - UI doesn't dim during scene preload
   - Scene switching feels responsive
   - Transitions still protected from interruption

### Phase 2: Architectural Enhancement (Follow-up)
1. **Add `NavigationFSM.isInterruptible`** helper
2. **Use semantic helper in `useIsSystemLocked`**
3. **Document FSM state interruptibility** in code comments
4. **Add unit tests** for interruptibility logic

### Phase 3: Mandatory Removal of Time-Based Throttle
Now that FSM-based locking and interruption logic are established, the artificial time-based throttle must be removed to provide maximum responsiveness:
- **Action**: Remove `ViewerState.state.contents.lastSwitchTime` checks and `throttleLimit` logic from `SceneList.res` and other interaction components.
- **Rationale**: The FSM is the single source of truth for transition safety and interruption capability. Redundant time delays only degrade the user experience.
- **Verification**: Ensure E2E stress tests confirm no race conditions occur when clicking as fast as possible.

## Testing Strategy

### Unit Tests
```rescript
// tests/unit/AppFSM_Interruptibility_v.test.res
describe("useIsSystemLocked", () => {
  test("allows interaction during Preloading", t => {
    let state = {
      ...State.initialState,
      appMode: Interactive({
        uiMode: Viewing,
        navigation: Preloading({targetSceneId: "scene-1", attempt: 1, isAnticipatory: false}),
        backgroundTask: None,
      }),
    }
    let locked = useIsSystemLocked(state)
    t->expect(locked)->Expect.toBe(false)
  })

  test("blocks interaction during Transitioning", t => {
    let state = {
      ...State.initialState,
      appMode: Interactive({
        uiMode: Viewing,
        navigation: Transitioning({fromSceneId: Some("scene-1"), toSceneId: "scene-2", progress: 0.5}),
        backgroundTask: None,
      }),
    }
    let locked = useIsSystemLocked(state)
    t->expect(locked)->Expect.toBe(true)
  })

  test("allows interaction during Stabilizing", t => {
    let state = {
      ...State.initialState,
      appMode: Interactive({
        uiMode: Viewing,
        navigation: Stabilizing({targetSceneId: "scene-1"}),
        backgroundTask: None,
      }),
    }
    let locked = useIsSystemLocked(state)
    t->expect(locked)->Expect.toBe(false)
  })
})
```

### E2E Tests
```typescript
// tests/e2e/rapid-scene-switching.spec.ts
test('rapid scene clicking should not hang', async ({ page }) => {
  await uploadThreeScenes(page);

  // Rapidly click scenes
  for (let i = 0; i < 10; i++) {
    await page.click(`[data-scene-index="${i % 3}"]`);
    await page.waitForTimeout(50); // Very rapid clicks
  }

  // Should not hang, should end on scene 1 (10 % 3 = 1)
  await expect(page.locator('[data-active-scene="1"]')).toBeVisible();
});

test('UI should not dim during scene preload', async ({ page }) => {
  await uploadTwoScenes(page);

  await page.click('[data-scene-index="1"]');

  // Check that overlay does NOT appear during preload
  const overlay = page.locator('.interaction-lock-overlay');
  await expect(overlay).not.toBeVisible({ timeout: 200 });
});

test('can interrupt scene loading by clicking another scene', async ({ page }) => {
  await uploadThreeScenes(page);

  // Start loading scene 1
  await page.click('[data-scene-index="1"]');

  // Immediately click scene 2 (interrupt)
  await page.waitForTimeout(50);
  await page.click('[data-scene-index="2"]');

  // Should end up on scene 2, not scene 1
  await expect(page.locator('[data-active-scene="2"]')).toBeVisible();
});
```

## Risk Assessment

### Low Risk Changes:
- ✅ Modifying `useIsSystemLocked` condition
- ✅ Removing redundant checks in `useIsInteractionPermitted`

### Medium Risk Changes:
- ⚠️ Mandatory removal of time-based throttle (Phase 3) - requires rigorous stress testing.

### High Risk Changes:
- ❌ Eliminating state duplication (not recommended)

## Success Criteria

1. **No UI dimming** on scene item clicks in sidebar
2. **Maximum responsiveness**: Rapid clicks are handled instantly by the FSM (interrupting vs. ignoring) without artificial time delays.
3. **Scene loading interruption** works: clicking Scene B while Scene A loads switches to Scene B
4. **Transition safety** maintained: cannot interrupt during CSS crossfade animation
5. **Zero regression** in existing navigation behavior
6. **Improved perceived performance**: App feels 2x more responsive

## Files to Modify

### Phase 1 (Surgical Fix):
1. `src/core/AppContext.res` - Fix `useIsSystemLocked` logic
2. `src/Hooks.res` - Remove redundant FSM check in `useIsInteractionPermitted`
3. `src/components/SceneList.res` - Reduce time throttle from 650ms to 200ms

### Phase 2 (Enhancement):
4. `src/systems/Navigation/NavigationFSM.res` - Add `isInterruptible` helper
5. `tests/unit/NavigationFSM_Interruptibility_v.test.res` - Unit tests

### Phase 3 (Throttle Removal):
6. `src/components/SceneList.res` - Complete removal of time-based throttle logic
7. `tests/e2e/rapid-scene-switching.spec.ts` - E2E stress tests

## Related Issues

- **Button dimming on scene click**: Fixed by allowing Preloading state
- **Application hang on rapid clicks**: Fixed by removing double-locking
- **Cannot cancel scene loading**: Fixed by allowing interruption during Preload
- **Sluggish UI feel**: Fixed by reducing lock duration from ~1.5s to ~200ms

## Migration Notes

**Breaking Changes**: None - this is a pure UX improvement with no API changes.

**Deployment**: Can be deployed immediately with no database migrations or compatibility concerns.

## Documentation Updates

1. Update `CLAUDE.md` FSM section:
   - Document which states are interruptible
   - Explain the difference between "system locked" and "FSM busy"
   - Add guidance on when to use `useIsSystemLocked` vs checking FSM state directly

2. Add inline comments to FSM reducers:
   - Mark interruptible state transitions
   - Explain why Transitioning is non-interruptible (CSS animation in progress)

## Future Enhancements

1. **Visual feedback during Preloading**: Show a subtle loading indicator on the target scene item instead of dimming the entire UI
2. **Optimistic UI updates**: Update active scene marker immediately on click, before FSM completes
3. **Animation interruption**: Research if CSS transitions can be safely interrupted mid-animation
4. **FSM state visualization**: Dev tool overlay showing current FSM state for debugging

## Estimated Effort

- **Phase 1 (Surgical Fix)**: 1-2 hours (coding + testing)
- **Phase 2 (Enhancement)**: 2 hours (semantic helpers + tests)
- **Phase 3 (E2E Tests)**: 1 hour

**Total**: 4-5 hours for complete implementation and testing

## Approval Required

- [ ] Product Owner - UX improvement approval
- [ ] Tech Lead - Architecture review of interruptibility logic
- [ ] QA - Test plan review

---

**Created**: 2026-02-06
**Priority**: P0 - Critical UX Issue
**Estimated Completion**: Same day (4-5 hours)

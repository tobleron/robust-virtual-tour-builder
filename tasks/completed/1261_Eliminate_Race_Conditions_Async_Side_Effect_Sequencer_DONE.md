# 1261: Eliminate Race Conditions via Async Side-Effect Sequencer

## Context & Problem Statement

Task 1260 introduced `InteractionGuard` to throttle/debounce/mutex **user inputs**. This solved "spam click" races on the entry point. However, the application still has **structural race conditions** in the async side-effect layer — the code that runs *after* a user action is accepted.

### Root Cause: Dual State Planes

The architecture maintains two parallel state management planes:

1. **React Reducer** (`Reducer.res` via `useReducer`) — Immutable, synchronous, batched within event handlers. This is the source of truth.
2. **Mutable Refs** — `GlobalStateBridge.stateRef`, `ViewerSystem.Pool.pool`, `ViewerState.state` — These are read/written from async callbacks (`setTimeout`, `requestAnimationFrame`, `Pannellum.on("load")`, `Promise.then`) with **no coordination**.

**101 calls** to `GlobalStateBridge.dispatch/getState` exist across 27 source files. Any of these can read stale state or trigger uncoordinated state mutations.

### Identified Race Conditions

#### RC-1: Stale State in SceneLoader Callbacks (CRITICAL)
**Files:** `SceneLoader.res:100`, `SceneLoader.res:119`, `SceneLoader.res:88`
**Problem:** `SceneLoader.loadNewScene()` calls `GlobalStateBridge.getState()` to find scenes by index. Between the FSM dispatch that triggered loading and the Pannellum `"load"` callback that fires `Events.onSceneLoad()`, the user could have deleted a scene, reordered scenes, or started navigating elsewhere. The scene index may now point to a different scene or be out of bounds.
**Symptom:** Wrong scene loaded after delete-during-navigation, or crash on stale index.

#### RC-2: NavigationFSM ↔ AppFSM Sync Gap (CRITICAL)
**Files:** `Reducer.res:201-224` (Navigation module), `Reducer.res:159-173` (AppFsm module)
**Problem:** Both `Navigation.reduce` and `AppFsm.reduce` handle `DispatchAppFsmEvent`. The Navigation reducer syncs `navigationFsm` into `appMode.Interactive.navigation` and vice versa. But since the reducer pipeline runs sequentially (AppFsm → Scene → ... → Navigation), the `AppFsm.reduce` step processes the event *before* `Navigation.reduce` does. If AppFSM transitions to a new mode that resets navigation, but Navigation then reads the *pre-transition* `state.appMode`, the sync becomes inconsistent.
**Symptom:** Components reading `state.appMode` see a different navigation state than those reading `state.navigationFsm` for 1 render cycle.

#### RC-3: ViewerPool Concurrent Mutation (HIGH)
**Files:** `ViewerSystem.res:81-172` (Pool module), `SceneTransition.res:43,129-158`
**Problem:** `ViewerSystem.Pool.pool` is a `ref<array<viewport>>` mutated from:
  - `swapActive()` — called during transition
  - `registerInstance()` — called when Pannellum initializes (async)
  - `clearInstance()` — called from `setTimeout` (500ms delay in `cleanupViewerInstance`)
  - `setCleanupTimeout()` — called from load events

These happen in different async contexts. If a user triggers a new scene switch while the cleanup `setTimeout` from the previous transition is still pending, `clearInstance` could destroy the viewer the new transition just created.
**Symptom:** Blank/black viewer after rapid scene switches.

#### RC-4: ViewerState Mutable Ref Concurrent Access (HIGH)
**Files:** `ViewerState.res`, mutated by 7 different files
**Problem:** `ViewerState.state` is a single `ref<t>` modified concurrently by:
  - `SceneTransition.performSwap()` — sets `isSwapping = true`
  - `SceneTransition.finalizeSwap()` — sets `isSwapping = false` (via `setTimeout(_, 50)`)
  - `ViewerSystem.Follow.updateFollowLoop()` — reads `isSwapping` and modifies `followLoopActive` (via `requestAnimationFrame`)
  - `InputSystem.res` — writes mouse position data
  - `CursorPhysics.res` — writes velocity data

The `isSwapping` flag is the only thing protecting the Follow loop from rendering during a swap. But since `finalizeSwap` runs on `setTimeout(50)` and the Follow loop runs on `rAF(~16ms)`, there's a window where `isSwapping` is true but 3+ rAF frames have fired, causing the Follow loop to skip rendering and desync from the actual viewer state.
**Symptom:** Hotspot lines flash/disappear during transitions; cursor follow lags after swap.

#### RC-5: Non-Atomic Multi-Dispatch Sequences (MEDIUM)
**Files:** `SceneSwitcher.res:33-91`, `SceneSwitcher.res:134-146`
**Problem:** `navigateToScene()` dispatches 3-5 actions sequentially:
```
dispatch(IncrementJourneyId)
dispatch(SetNavigationStatus(Navigating(j)))
dispatch(DispatchNavigationFsmEvent(UserClickedScene(...)))
```
React 18+ batches these within event handlers, but `setSimulationMode()` wraps part of its logic in `setTimeout(_, 100)`, moving dispatches outside the batch boundary. Between the batched group and the delayed group, intermediate state is visible to effects.
**Symptom:** Brief flash of inconsistent UI during simulation mode toggle; NavigationController effect fires with partial state.

#### RC-6: Simulation Tick Stale Ref Between Awaits (MEDIUM)
**Files:** `Simulation.res:63-217`
**Problem:** The simulation `runTick` function reads `stateRef.current` across multiple `await` boundaries (delay wait, `waitForViewerScene`, next move calculation). While it checks `cancel.contents` and `simulation.status`, the actual scene data, navigation state, and viewer readiness can change between awaits. The `stateRef` is updated on every render, but if a render occurs *during* an await, the ref now points to new state while the tick function's local variables hold decisions based on old state.
**Symptom:** Simulation navigates to wrong scene after user manually intervenes mid-simulation.

#### RC-7: SceneTransition setTimeout Chain (MEDIUM)
**Files:** `SceneTransition.res:42-157`
**Problem:** `performSwap` triggers a chain: `performSwap()` → `setTimeout(finalizeSwap, 50)` → separate `setTimeout(cleanupViewerInstance, 500)`. Between these timeouts (550ms total window), the viewer pool is in a partially-swapped state. No guard prevents a new navigation from starting during this window.
**Symptom:** If user clicks a scene during the 550ms cleanup window, the new load may target the viewport being cleaned up.

#### RC-8: NavigationController Effect Stale Closures (MEDIUM)
**Files:** `NavigationController.res:9-84`
**Problem:** `useNavigationFSM` depends on `[state.navigationFsm]` but reads `state.navigation`, `state.scenes`, `state.activeIndex` from the closure. If those fields change *without* `navigationFsm` changing, the effect uses stale data. This is a classic React stale-closure bug.
**Symptom:** NavigationController's Stabilizing handler looks up the wrong scene if `scenes` array was modified while FSM was transitioning.

#### RC-9: EventBus Cascading Dispatch (LOW)
**Files:** `EventBus.res:67-117`
**Problem:** EventBus dispatches synchronously. If listener A handles an event by dispatching another EventBus event, listener B (for the original event) hasn't run yet but will see state modified by A's cascade.
**Symptom:** Rare ordering bugs in notification → modal flows.

---

## Proposed Solution: TransitionLock + Atomic Dispatch

Rather than a full rewrite, this solution surgically addresses each race condition class with three complementary mechanisms:

### Mechanism 1: TransitionLock (addresses RC-3, RC-4, RC-7)
A lightweight lock that serializes viewer lifecycle operations.

**New file:** `src/core/TransitionLock.res`
```
type phase = Idle | Loading(string) | Swapping(string) | Cleanup(string)

let current: ref<phase>
let acquire: (string, phase) => Result.t<unit, string>
let release: (string) => unit
let isIdle: unit => bool
let onIdle: (unit => unit) => unit  // callback when lock returns to Idle
```

**Integration points:**
- `SceneLoader.loadNewScene()` — acquire `Loading(sceneId)` before starting; reject if not Idle
- `SceneTransition.performSwap()` — transition to `Swapping(sceneId)`; block new loads
- `SceneTransition.cleanupViewerInstance()` — transition to `Cleanup(sceneId)`; block new loads
- `SceneTransition.finalizeSwap()` — release lock back to `Idle`
- `NavigationFSM` interrupt handling — release lock on `UserClickedScene` during Preloading/Transitioning

**Benefit:** No viewer lifecycle operation can overlap. If a user clicks during swap, the InteractionGuard's throttle policy rejects it (300ms). If they click after throttle expires but during cleanup (300-550ms), TransitionLock queues it via `onIdle`.

### Mechanism 2: Atomic Dispatch (addresses RC-2, RC-5, RC-8)
A batch dispatch helper that sends multiple actions as a single reducer pass.

**Modification to:** `src/core/Actions.res`
```
| Batch(array<action>)  // New action variant
```

**Modification to:** `src/core/Reducer.res`
```
| Batch(actions) => Belt.Array.reduce(actions, state, (s, a) => reducer(s, a)) |> Some
```

**Integration points:**
- `SceneSwitcher.navigateToScene()` — wrap `IncrementJourneyId + SetNavigationStatus + DispatchNavigationFsmEvent` in a single `Batch` dispatch
- `SceneSwitcher.setSimulationMode()` — wrap all 5 dispatches in a single `Batch`
- Eliminate the `setTimeout(_, 100)` in `setSimulationMode` by making auto-forward part of the batch

**Benefit:** One render cycle, one effect trigger, zero intermediate state exposure. Also fixes RC-8 because the effect's dependency (`navigationFsm`) and the values it reads (`navigation`, `scenes`) all update atomically.

### Mechanism 3: Scene ID-Based Resolution (addresses RC-1, RC-6)
Replace index-based scene lookups from GlobalStateBridge with ID-based lookups that are inherently safe against reordering/deletion.

**Refactoring targets:**
- `SceneLoader.loadNewScene()` — change signature from `option<int>` to `string` (sceneId). Look up scene by ID instead of index from `GlobalStateBridge.getState()`
- `NavigationController.useNavigationFSM` Preloading handler — already has `targetSceneId`, pass it directly
- `SceneTransition.performSwap()` — already receives `scene` record, no index needed
- `Simulation.res` `runTick` — resolve scene by ID before each await boundary, not once at the start

**Benefit:** Reordering or deleting scenes during an in-flight navigation cannot cause the wrong scene to load. If the target scene is deleted, the ID lookup returns `None` and the navigation is safely aborted.

---

## Implementation Plan

### Phase 1: TransitionLock Foundation
1. Create `src/core/TransitionLock.res` with `phase` type and `acquire`/`release`/`onIdle` API
2. Integrate into `SceneLoader.loadNewScene()` — acquire before load, reject if locked
3. Integrate into `SceneTransition.performSwap()` — transition from Loading → Swapping → Cleanup → Idle
4. Add cleanup timeout cancellation on lock release (prevent orphaned `setTimeout` cleanups)
5. Add telemetry: log all acquire/release/reject events via `Logger`

### Phase 2: Atomic Dispatch
1. Add `Batch(array<action>)` variant to `Actions.res`
2. Add batch handling to `Reducer.reducer` — fold all sub-actions in a single pass
3. Refactor `SceneSwitcher.navigateToScene()` to use `Batch`
4. Refactor `SceneSwitcher.setSimulationMode()` to use `Batch` — remove the `setTimeout(_, 100)`
5. Refactor `SceneSwitcher.initNavigation()` to use `Batch`
6. Add `Batch` to `actionToString` for telemetry

### Phase 3: ID-Based Scene Resolution
1. Change `SceneLoader.loadNewScene` signature from `(option<int>, option<int>, ~isAnticipatory)` to `(~sourceSceneId: option<string>, ~targetSceneId: string, ~isAnticipatory: bool)`
2. Update `NavigationController.useNavigationFSM` Preloading handler to pass `targetSceneId` directly (already available in FSM state)
3. Update `Simulation.res` `runTick` to re-resolve scene by ID after each `await`
4. Add `Option.forEach` safety to all ID-based lookups — if scene is deleted mid-flight, dispatch `DispatchNavigationFsmEvent(Aborted)` instead of crashing

### Phase 4: NavigationController Effect Fix
1. Expand `useNavigationFSM` dependency array to include `[state.navigationFsm, state.scenes, state.activeIndex]` or restructure to extract needed values into the dep array
2. Alternatively: move the effect body into a `React.useCallback` that captures current values and is included in deps

### Phase 5: ViewerState Consolidation
1. Move `isSwapping` flag from `ViewerState.state` (mutable ref) into `TransitionLock.current` — reading `TransitionLock.phase == Swapping(_)` replaces `ViewerState.state.contents.isSwapping`
2. Update `ViewerSystem.Follow.updateFollowLoop()` to check `TransitionLock` instead of `ViewerState.isSwapping`
3. Update `SceneTransition.finalizeSwap()` and `performSwap()` accordingly
4. This eliminates one class of concurrent mutable ref access

### Phase 6: Testing & Validation
1. Unit test `TransitionLock` — verify acquire/release/reject/onIdle semantics
2. Unit test `Batch` action — verify atomic multi-action dispatch
3. Integration test: rapid scene switching (< 300ms intervals) — verify no blank viewers
4. Integration test: delete scene during active navigation — verify graceful abort
5. Integration test: simulation mode toggle during navigation — verify no intermediate state flash
6. Regression: verify existing `InteractionGuard` tests still pass (no interference)

---

## Files Modified

| File | Change Type | Purpose |
|------|------------|---------|
| `src/core/TransitionLock.res` | **NEW** | Viewer lifecycle lock |
| `src/core/Actions.res` | MODIFY | Add `Batch` variant |
| `src/core/Reducer.res` | MODIFY | Handle `Batch` action |
| `src/systems/Scene/SceneLoader.res` | MODIFY | TransitionLock + ID-based API |
| `src/systems/Scene/SceneTransition.res` | MODIFY | TransitionLock integration |
| `src/systems/Scene/SceneSwitcher.res` | MODIFY | Batch dispatch + ID-based calls |
| `src/systems/Navigation/NavigationController.res` | MODIFY | Fix effect deps + stale closures |
| `src/systems/Simulation.res` | MODIFY | ID-based resolution between awaits |
| `src/systems/ViewerSystem.res` | MODIFY | TransitionLock replaces isSwapping checks |
| `src/core/ViewerState.res` | MODIFY | Remove `isSwapping` (moved to TransitionLock) |

---

## Risk Assessment

- **Phase 1-2** (TransitionLock + Batch): Low risk, additive changes. TransitionLock is purely new; Batch adds one variant.
- **Phase 3** (ID-based): Medium risk. Signature change to `SceneLoader.loadNewScene` affects all callers. Must verify all paths pass sceneId.
- **Phase 4** (Effect fix): Low risk. Expanding dep arrays is safe; may cause extra effect runs but these are idempotent.
- **Phase 5** (ViewerState consolidation): Medium risk. Changing what `Follow.updateFollowLoop` checks requires careful testing of the linking/hotspot rendering path.

## Success Criteria

- Zero blank/black viewer occurrences during rapid scene switching stress test
- No console errors when deleting a scene during active navigation
- Simulation mode toggle produces exactly 1 render cycle (no intermediate flash)
- All existing `InteractionGuard`, `NavigationFSM`, and `SceneLoader` tests pass
- `TransitionLock` unit tests cover: normal flow, double-acquire rejection, release-on-abort, onIdle callback

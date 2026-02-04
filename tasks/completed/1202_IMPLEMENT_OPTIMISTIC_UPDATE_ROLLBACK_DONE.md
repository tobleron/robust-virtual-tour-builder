# TASK: Implement Optimistic Update Rollback Pattern

**Priority**: 🟡 Medium
**Estimated Effort**: Large (4-5 hours)
**Dependencies**: 1200 (Barrier Actions)
**Related Tasks**: 1200, 1203

---

## 1. Problem Statement

Currently, state changes in the Reducer are applied immediately without rollback capability:

- **No Undo on API Failure**: If `AddHotspot` succeeds locally but the backend rejects it, the UI shows stale data.
- **Orphaned State**: Scene deletions can leave orphaned references if backend sync fails.
- **User Confusion**: Users see changes reflected immediately but may lose them silently.

---

## 2. Technical Requirements

### A. Create State Snapshot Manager

**File**: `src/core/StateSnapshot.res` (new)

```rescript
type snapshot = {
  id: string,
  timestamp: float,
  state: Types.state,
  action: Actions.action,
}

let history: ref<array<snapshot>> = ref([])
let maxSnapshots = 10

let capture: (Types.state, Actions.action) => string  // Returns snapshot ID
let rollback: string => option<Types.state>           // Restore by ID
let commit: string => unit                            // Remove snapshot (success)
let getLatest: unit => option<snapshot>
let clear: unit => unit
```

### B. Create Optimistic Action Wrapper

**File**: `src/core/OptimisticAction.res` (new)

```rescript
type optimisticResult<'a> =
  | Committed('a)
  | RolledBack(string)  // Error message

let execute: (
  ~action: Actions.action,
  ~apiCall: unit => Promise.t<result<'a, string>>,
  ~onRollback: Types.state => unit,
) => Promise.t<optimisticResult<'a>>
```

**Logic**:
1. Capture current state snapshot.
2. Dispatch action immediately (optimistic).
3. Execute API call.
4. On success: `commit(snapshotId)`.
5. On failure: `rollback(snapshotId)` and call `onRollback` with restored state.

### C. Apply to Critical Actions

**Actions requiring optimistic handling**:

| Action | API Call | Rollback Strategy |
|--------|----------|-------------------|
| `DeleteScene(index)` | `DELETE /project/scene/:id` | Restore scene from snapshot |
| `AddHotspot(sceneIndex, hotspot)` | `POST /project/hotspot` | Remove hotspot from state |
| `DeleteHotspot(sceneIndex, hotspotIndex)` | `DELETE /project/hotspot/:id` | Restore hotspot from snapshot |
| `UpdateSceneMetadata(index, meta)` | `PATCH /project/scene/:id` | Restore previous metadata |

### D. User Feedback on Rollback

When rollback occurs:

```rescript
EventBus.dispatch(ShowNotification(
  "Action failed. Changes have been reverted.",
  #Warning,
  Some(Logger.castToJson({"action": actionName, "error": errorMsg}))
))
```

---

## 3. Integration with InteractionQueue

The optimistic action should be enqueued as a `Thunk`:

```rescript
let deleteSceneOptimistic = (index: int) => {
  InteractionQueue.enqueue(Thunk(() => {
    OptimisticAction.execute(
      ~action=DeleteScene(index),
      ~apiCall=() => Api.deleteScene(sceneId),
      ~onRollback=state => GlobalStateBridge.setState(state),
    )->Promise.map(_ => ())
  }))
}
```

---

## 4. JSON Encoding Standard

Snapshot serialization MUST use `rescript-json-combinators`:

```rescript
let snapshotEncoder = JsonCombinators.Json.Encode.object([
  ("id", string(snapshot.id)),
  ("timestamp", float(snapshot.timestamp)),
  ("state", JsonParsers.Encoders.state(snapshot.state)),
  ("action", string(Actions.actionToString(snapshot.action))),
])
```

---

## 5. Verification Criteria

- [ ] Deleting a scene and simulating API failure restores the scene.
- [ ] User sees notification when rollback occurs.
- [x] State history is limited to 10 snapshots (memory safety).
- [x] Committed snapshots are removed from history.
- [ ] UI remains responsive during rollback.
- [x] All JSON encoding uses `rescript-json-combinators`.
- [x] `npm run build` completes with zero warnings.

---

## 6. File Checklist

- [x] `src/core/StateSnapshot.res` - New module
- [x] `src/core/StateSnapshot.resi` - Interface file
- [x] `src/core/OptimisticAction.res` - New module
- [x] `src/core/OptimisticAction.resi` - Interface file
- [ ] `src/components/Sidebar/SidebarLogic.res` - Apply to delete scene
- [ ] `src/components/HotspotManager.res` - Apply to hotspot actions
- [x] `tests/unit/OptimisticAction_v.test.res` - Unit tests
- [x] `MAP.md` - Add new module entries

---

## 7. References

- `src/core/Reducer.res`
- `src/core/InteractionQueue.res`
- `src/core/GlobalStateBridge.res`
- `src/systems/EventBus.res`

# TASK: Complete Optimistic Update and Recovery Integration

**Priority**: 🟡 Medium
**Estimated Effort**: Medium (2-3 hours)
**Dependencies**: 1202 (Optimistic Rollback), 1205 (Operation Journal)
**Related Tasks**: 1202, 1205

---

## 1. Problem Statement

Tasks 1202 and 1205 have created the foundational modules for optimistic updates and operation recovery, but they are not fully integrated into the application:

- **Incomplete Integration**: OptimisticAction pattern not applied to critical user actions (delete scene, hotspot operations)
- **Untested Recovery**: No verification that rollback and recovery mechanisms work in real scenarios
- **Missing UX Validation**: Recovery prompt and rollback notifications haven't been tested with users

---

## 2. Technical Requirements

### A. Apply Optimistic Pattern to SidebarLogic

**File**: `src/components/Sidebar/SidebarLogic.res`

Currently, scene deletion and other operations don't use the optimistic pattern. Need to wrap critical operations:

```rescript
// Current (non-optimistic)
let handleDeleteScene = (index) => {
  GlobalStateBridge.dispatch(DeleteScene(index))
  Api.deleteScene(sceneId) // Fire and forget
}

// Target (optimistic with rollback)
let handleDeleteScene = (index) => {
  InteractionQueue.enqueue(Thunk(() => {
    OptimisticAction.execute(
      ~action=DeleteScene(index),
      ~apiCall=() => Api.deleteScene(sceneId),
      ~onRollback=state => {
        GlobalStateBridge.setState(state)
        EventBus.dispatch(ShowNotification(
          "Failed to delete scene. Changes reverted.",
          #Warning,
          None
        ))
      },
    )->Promise.map(_ => ())
  }))
}
```

**Operations to Convert**:
- Scene deletion
- Scene reordering (if persisted)
- Project metadata updates

### B. Apply Optimistic Pattern to HotspotManager

**File**: `src/components/HotspotManager.res`

Apply to hotspot CRUD operations:

```rescript
let handleDeleteHotspot = (sceneIndex, hotspotIndex) => {
  InteractionQueue.enqueue(Thunk(() => {
    OptimisticAction.execute(
      ~action=DeleteHotspot(sceneIndex, hotspotIndex),
      ~apiCall=() => Api.deleteHotspot(hotspotId),
      ~onRollback=state => {
        GlobalStateBridge.setState(state)
        EventBus.dispatch(ShowNotification(
          "Failed to delete hotspot. Changes reverted.",
          #Warning,
          None
        ))
      },
    )->Promise.map(_ => ())
  }))
}
```

**Operations to Convert**:
- Add hotspot
- Delete hotspot
- Update hotspot metadata

### C. Create E2E Tests for Rollback

**File**: `tests/e2e/optimistic-rollback.spec.ts` (new)

```typescript
import { test, expect } from '@playwright/test';

test.describe('Optimistic Update Rollback', () => {
  test('should rollback scene deletion on API failure', async ({ page }) => {
    // Setup: Load project with scenes
    // Action: Delete scene with mocked API failure
    // Verify: Scene is restored, notification shown
  });

  test('should rollback hotspot addition on API failure', async ({ page }) => {
    // Setup: Load scene
    // Action: Add hotspot with mocked API failure
    // Verify: Hotspot removed, notification shown
  });

  test('should commit successful operations', async ({ page }) => {
    // Setup: Load project
    // Action: Delete scene with successful API
    // Verify: Scene removed, no rollback
  });
});
```

### D. Create E2E Tests for Recovery

**File**: `tests/e2e/operation-recovery.spec.ts` (new)

```typescript
import { test, expect } from '@playwright/test';

test.describe('Operation Recovery', () => {
  test('should show recovery prompt after interrupted save', async ({ page, context }) => {
    // Setup: Start save operation
    // Action: Close tab mid-operation
    // Reopen: Verify recovery prompt appears
    // Verify: Can retry or dismiss
  });

  test('should recover interrupted upload', async ({ page, context }) => {
    // Setup: Start upload
    // Action: Simulate crash
    // Reopen: Verify recovery prompt
    // Verify: Can retry upload
  });

  test('should clear completed operations from journal', async ({ page }) => {
    // Setup: Complete save operation
    // Reopen: Verify no recovery prompt
  });
});
```

### E. Manual Testing Checklist

Create a manual testing guide for QA:

**File**: `docs/TESTING_OPTIMISTIC_UPDATES.md` (new)

```markdown
# Testing Guide: Optimistic Updates & Recovery

## Rollback Testing

1. **Scene Deletion Rollback**
   - Load project with multiple scenes
   - Disconnect network (DevTools > Network > Offline)
   - Delete a scene
   - Verify: Scene reappears, warning notification shown

2. **Hotspot Rollback**
   - Add hotspot while offline
   - Verify: Hotspot removed, warning shown

## Recovery Testing

1. **Interrupted Save**
   - Start save operation
   - Close browser tab immediately
   - Reopen app
   - Verify: Recovery prompt appears
   - Click "Retry All"
   - Verify: Save completes

2. **Interrupted Upload**
   - Start image upload
   - Force close browser
   - Reopen app
   - Verify: Recovery prompt shows upload
   - Dismiss or retry
```

---

## 3. Verification Criteria

### Optimistic Updates
- [ ] Scene deletion uses OptimisticAction pattern
- [ ] Hotspot CRUD operations use OptimisticAction pattern
- [ ] Failed operations show rollback notification
- [ ] Successful operations commit without notification
- [ ] UI remains responsive during rollback
- [ ] StateSnapshot history is properly managed (max 10 entries)

### Recovery System
- [ ] Interrupted save shows recovery prompt on restart
- [ ] Interrupted upload shows recovery prompt on restart
- [ ] Recovery prompt allows retry or dismiss
- [ ] Completed operations don't trigger recovery prompt
- [ ] Journal persists to IndexedDB correctly
- [ ] Recovery prompt UI is clear and actionable

### Testing
- [ ] E2E tests for rollback scenarios pass
- [ ] E2E tests for recovery scenarios pass
- [ ] Manual testing guide created
- [ ] All tests documented in test plan

### Build & Quality
- [ ] `npm run build` completes with zero warnings
- [ ] No console errors during rollback
- [ ] No console errors during recovery
- [ ] All JSON encoding uses `rescript-json-combinators`

---

## 4. File Checklist

### Implementation
- [ ] `src/components/Sidebar/SidebarLogic.res` - Apply optimistic pattern
- [ ] `src/components/HotspotManager.res` - Apply optimistic pattern
- [ ] `src/core/OptimisticAction.res` - Add helper functions if needed

### Testing
- [ ] `tests/e2e/optimistic-rollback.spec.ts` - New E2E tests
- [ ] `tests/e2e/operation-recovery.spec.ts` - New E2E tests
- [ ] `docs/TESTING_OPTIMISTIC_UPDATES.md` - Manual testing guide

### Documentation
- [ ] Update `MAP.md` if new modules created
- [ ] Update `CHANGELOG.md` with feature completion

---

## 5. Success Metrics

- **Rollback Success Rate**: 100% of failed API calls trigger rollback
- **Recovery Prompt Accuracy**: 100% of interrupted operations show in recovery
- **User Notification**: Clear, actionable messages for all rollback scenarios
- **Performance**: Rollback completes in <100ms
- **Reliability**: Zero state corruption after rollback

---

## 6. References

- `tasks/active/1202_IMPLEMENT_OPTIMISTIC_UPDATE_ROLLBACK.md`
- `tasks/active/1205_ENHANCE_PERSISTENCE_MID_FLIGHT_RECOVERY.md`
- `src/core/OptimisticAction.res`
- `src/core/StateSnapshot.res`
- `src/utils/OperationJournal.res`
- `src/components/RecoveryPrompt.res`

---

## 7. Notes

This task completes the integration work started in tasks 1202 and 1205. Once complete, both parent tasks can be moved to completed. The focus is on:

1. **Integration**: Applying patterns to real user actions
2. **Verification**: Ensuring mechanisms work in practice
3. **Documentation**: Creating testing guides for maintainability

This is the final step to make optimistic updates and recovery production-ready.

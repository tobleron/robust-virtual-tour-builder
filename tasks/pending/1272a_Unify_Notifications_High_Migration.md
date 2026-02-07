# 1272a: Unify Notifications - High-Impact Migration

**Status**: Pending
**Priority**: High (Core system unification - Phase 1/3)
**Effort**: 1 hour
**Dependencies**: 1269 (NotificationManager must exist), 1271 (NotificationCenter component)
**Blocks**: 1272b (sequential migration)
**Scalability**: ⭐⭐⭐⭐⭐ (Strategic migration to unified system)
**Reliability**: ⭐⭐⭐⭐⭐ (High-impact files first = maximum validation)

---

## 🎯 Objective

**Phase 1 of 3**: Migrate high-impact ShowNotification calls (18 usages) to NotificationManager. Focus on highest-value files first: SidebarLogic (9), RecoveryManager (5), UtilityBar (4). This validates the migration pattern and creates the blueprint for phases 2 & 3.

**Outcome**: Core notification paths unified, tests passing, migration pattern established, ready for phase 2 (medium-impact files).

---

## 📋 Acceptance Criteria

✅ **Phase 1 Completion (18 usages migrated)**
- [ ] SidebarLogic.res: All 9 ShowNotification → NotificationManager
- [ ] RecoveryManager.res: All 5 ShowNotification → NotificationManager
- [ ] UtilityBar.res: All 4 ShowNotification → NotificationManager

✅ **Code Quality**
- Zero compilation errors
- Zero compiler warnings
- Consistent type mapping applied
- Code formatted with `npm run rs:fmt`

✅ **No Regressions**
- All 787+ existing tests still pass
- All other EventBus events still work
- Sidebar operations work correctly (upload, download, export)
- Recovery operations show notifications correctly
- Utility bar feedback appears correctly

✅ **Migration Pattern Established**
- Type mapping documented: #Error→Error, #Warning→Warning, #Success→Success, #Info→Info
- Context mapping clear: Operation("feature_name") or SystemEvent("recovery")
- Duration calculation: NotificationTypes.defaultTimeoutMs(importance)
- Blueprint ready for phases 2 & 3

---

## 📝 Implementation Checklist

**File 1: SidebarLogic.res (9 usages)**
- [ ] Read file and locate all ShowNotification calls
- [ ] For each call, determine context (upload, download, export, etc.)
- [ ] Create notification record with:
  - `importance` from type mapping (#Error→Error, etc.)
  - `context: Operation("sidebar_upload")` etc.
  - `message` from original string
  - `duration: NotificationTypes.defaultTimeoutMs(importance)`
- [ ] Replace EventBus.dispatch(ShowNotification(...)) with NotificationManager.dispatch(...)
- [ ] Format file

**File 2: RecoveryManager.res (5 usages)**
- [ ] Read file and understand recovery flow
- [ ] For each ShowNotification, map to NotificationManager with context: SystemEvent("recovery")
- [ ] Replace calls
- [ ] Format file

**File 3: UtilityBar.res (4 usages)**
- [ ] Read file and understand utility bar operations
- [ ] Map each ShowNotification to NotificationManager
- [ ] Replace calls
- [ ] Format file

**Verification**:
- [ ] Compile: `npm run res:build` - 0 errors, 0 warnings
- [ ] Tests: `npm test` - all 787+ pass
- [ ] Manual: Test sidebar upload, recovery, utility bar operations
- [ ] Search: `grep "ShowNotification" src/systems/EventBus.res` - should still exist (phases 2 & 3 use it)

---

## 🧪 Testing

**Verification Steps**:
1. Run full build: `npm run res:build` (verify 0 errors, 0 warnings)
2. Run full test suite: `npm test` (verify all 787+ tests pass)
3. Search for ShowNotification: `grep -r "ShowNotification" src/` (should be empty)
4. Verify EventBus compiles cleanly with reduced type
5. Check that UpdateProcessing and other events still work
6. Verify no console warnings about unused types

---

## 📊 Migration Pattern

**Old Format** (EventBus.ShowNotification):
```rescript
EventBus.dispatch(ShowNotification("Upload Complete", #Success, None))
EventBus.dispatch(ShowNotification("Error: " ++ msg, #Error, data))
EventBus.dispatch(ShowNotification("Please wait...", #Warning, None))
```

**New Format** (NotificationManager):
```rescript
NotificationManager.dispatch({
  id: "",
  importance: Success,
  context: Operation("sidebar_upload"),
  message: "Upload Complete",
  details: None,
  action: None,
  duration: NotificationTypes.defaultTimeoutMs(Success),
  dismissible: true,
  createdAt: Date.now(),
})
```

**Type Mapping**:
```
#Error    → Error (8000ms timeout)
#Warning  → Warning (5000ms timeout)
#Success  → Success (3000ms timeout)
#Info     → Info (3000ms timeout)
```

**Context Examples**:
- Upload: `Operation("sidebar_upload")`
- Recovery: `SystemEvent("recovery")`
- Utility: `Operation("utility_bar")`

---

## 🔍 Quality Gates (Must Pass Before 1273 Starts)

| Gate | Condition | Check |
|------|-----------|-------|
| Compilation | 0 errors, 0 warnings | `npm run res:build` output |
| Test Suite | All 787+ tests pass | `npm test` output |
| Dead Code Removal | No ShowNotification refs | `grep -r "ShowNotification" src/` |
| Code Clean | EventBus focuses on domain events | Code review of event type |

---

## 🔄 Rollback Plan

**If compilation fails:**
1. Verify ShowNotification was completely removed (both type and dispatch case)
2. Run `npm run rs:fmt` to auto-fix formatting
3. Check no type references remain in other modules
4. Rebuild: `npm run res:build`

**If tests fail:**
1. Search for any ShowNotification references in test files
2. Verify other EventBus events still dispatch correctly
3. Check that event handlers for NavStart, UpdateProcessing, etc. still work
4. Run individual test: `npx vitest specific_test_file.test.bs.js`

**If grep still finds ShowNotification:**
1. It should only appear in NotificationTypes.res (expected)
2. Check it's not in src/ directory with: `grep -r "ShowNotification" src/`
3. If found, investigate usage and update that file

---

## 💡 Implementation Tips

1. **Locate ShowNotification**: Line 39 of EventBus.res type definition
2. **Locate dispatch case**: Lines 71-78 of EventBus.res dispatch function
3. **Minimal change philosophy**: Remove only dead code, preserve all active events
4. **Verify removal**: Use grep to confirm no ShowNotification references remain
5. **Test all events**: Verify other EventBus events still dispatch correctly

---

## 🚀 Next Tasks

- **1272b: Unify Notifications - Medium-Impact Migration** (4 files, 19 usages, 1.5 hours)
  - Sidebar, TeaserLogic, ProjectManager, AuthenticatedClient, SceneList, LabelMenu
- **1272c: Unify Notifications - Low-Impact Migration + Cleanup** (23 files, 16 usages, 1 hour)
  - All single-usage files + remove ShowNotification from EventBus
- **1273: Mount NotificationCenter in App** (depends on 1272a completion)
- **1274: Integration testing & verification** (depends on 1273)

---

## 📌 Notes - Phase 1 of 3

- **Strategic Approach**: High-impact files first = maximum validation and testing
- **Blueprint Phase**: Establish migration pattern for phases 2 & 3
- **Incremental**: Tests pass after each phase, not just at the end
- **ShowNotification Lifecycle**: Still exists in EventBus during phases 2-3, removed only in cleanup
- **Pattern Reuse**: Once established, pattern can be applied systematically to remaining 26 files

**Phase 2 Target**: Medium-impact files (4 files, 19 usages, ~1.5 hours)
**Phase 3 Target**: Low-impact files + cleanup (23 files, 16 usages + removal, ~1 hour)

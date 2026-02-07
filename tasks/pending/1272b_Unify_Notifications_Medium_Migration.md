# 1272b: Unify Notifications - Medium-Impact Migration

**Status**: Pending
**Priority**: High (Core system unification - Phase 2/3)
**Effort**: 1.5 hours
**Dependencies**: 1272a (Phase 1 must complete first)
**Blocks**: 1272c (final cleanup phase)
**Scalability**: ⭐⭐⭐⭐⭐ (Pattern proven, systematic application)
**Reliability**: ⭐⭐⭐⭐⭐ (Continues established migration pattern)

---

## 🎯 Objective

**Phase 2 of 3**: Migrate medium-impact ShowNotification calls (19 usages) to NotificationManager using the pattern established in phase 1. Files: Sidebar (4), TeaserLogic (3), ProjectManager (3), AuthenticatedClient (3), SceneList (3), LabelMenu (3).

**Outcome**: 39 of 64 total usages migrated, pattern fully validated, ready for phase 3 cleanup.

---

## 📋 Acceptance Criteria

✅ **Phase 2 Completion (19 usages migrated)**
- [ ] Sidebar.res: All 4 ShowNotification → NotificationManager
- [ ] TeaserLogic.res: All 3 ShowNotification → NotificationManager
- [ ] ProjectManager.res: All 3 ShowNotification → NotificationManager
- [ ] AuthenticatedClient.res: All 3 ShowNotification → NotificationManager
- [ ] SceneList.res: All 3 ShowNotification → NotificationManager
- [ ] LabelMenu.res: All 3 ShowNotification → NotificationManager

✅ **Code Quality**
- Zero compilation errors
- Zero compiler warnings
- Consistent with phase 1 pattern
- Code formatted with `npm run rs:fmt`

✅ **No Regressions**
- All 787+ existing tests still pass
- All 18 phase 1 migrations still work
- Teaser, project, auth, scene list operations work correctly
- No rollback needed

✅ **Cumulative Progress**
- Phase 1: 18/64 ✅
- Phase 2: 19/64 (this task)
- Phase 3: 16/64 (remaining)
- **Total after 1272b**: 37/64 migrated (58%)

---

## 📝 Implementation Checklist

**File 1: Sidebar.res (4 usages)**
- [ ] Read file and locate all ShowNotification calls
- [ ] Understand each context (routing, sidebar operations, etc.)
- [ ] Replace with NotificationManager using established pattern
- [ ] Format file

**File 2: TeaserLogic.res (3 usages)**
- [ ] Read file and understand teaser generation/playback flow
- [ ] Map each ShowNotification to NotificationManager with context: Operation("teaser")
- [ ] Replace calls with consistent pattern
- [ ] Format file

**File 3: ProjectManager.res (3 usages)**
- [ ] Read file and understand project operations (save, load, export)
- [ ] Map each ShowNotification with appropriate Operation context
- [ ] Replace calls
- [ ] Format file

**File 4: AuthenticatedClient.res (3 usages)**
- [ ] Read file and understand API authentication flow
- [ ] Map each ShowNotification to appropriate context
- [ ] Replace calls
- [ ] Format file

**File 5: SceneList.res (3 usages)**
- [ ] Read file and understand scene list interactions
- [ ] Map each ShowNotification (likely scene operations)
- [ ] Replace calls
- [ ] Format file

**File 6: LabelMenu.res (3 usages)**
- [ ] Read file and understand label menu operations
- [ ] Map each ShowNotification to Operation("label_menu")
- [ ] Replace calls
- [ ] Format file

**Verification**:
- [ ] Compile: `npm run res:build` - 0 errors, 0 warnings
- [ ] Tests: `npm test` - all 787+ pass
- [ ] Manual: Test teaser, project operations, scene list, label menu
- [ ] No regressions from phase 1

---

## 📊 Migration Pattern (from Phase 1)

**Type Mapping**:
```
#Error    → Error (8000ms)
#Warning  → Warning (5000ms)
#Success  → Success (3000ms)
#Info     → Info (3000ms)
```

**Template**:
```rescript
NotificationManager.dispatch({
  id: "",
  importance: Error,
  context: Operation("feature_name"),
  message: "Your message here",
  details: None,
  action: None,
  duration: NotificationTypes.defaultTimeoutMs(Error),
  dismissible: true,
  createdAt: Date.now(),
})
```

**Context Naming Convention**:
- UI operations: `Operation("feature_name")`
- System events: `SystemEvent("recovery")`, `SystemEvent("persistence")`
- API calls: `Operation("api_endpoint")`

---

## 🔍 Quality Gates

| Gate | Condition | Check |
|------|-----------|-------|
| Compilation | 0 errors, 0 warnings | `npm run res:build` |
| Tests | All 787+ pass | `npm test` |
| Phase 1 Integrity | All previous usages still work | Manual spot check |
| Pattern Consistency | Follows phase 1 approach | Code review |

---

## 🔄 Rollback Plan

**If compilation fails:**
1. Verify all 6 files have NotificationManager imported
2. Check type mapping consistency
3. Verify duration calculation is correct
4. Run `npm run rs:fmt` and retry build

**If tests fail:**
1. Check if any test fixtures reference ShowNotification
2. Verify NotificationManager is working (phase 1 tests should pass)
3. Test individual features (teaser, project, scene)
4. Roll back single file at a time to isolate issue

**If manual testing fails:**
1. Check NotificationCenter component is mounted in App.res
2. Verify browser dev tools show notifications
3. Check Logger output for errors
4. Compare with phase 1 files for pattern differences

---

## 💡 Implementation Tips

1. **Establish rhythm**: Follow phase 1 pattern exactly - 6 files, similar approach each time
2. **Test incrementally**: After each file, compile and quick manual test
3. **Consistent contexts**: Use clear Operation names that describe what's happening
4. **Duration defaults**: Always use `NotificationTypes.defaultTimeoutMs(importance)`
5. **No breaking changes**: All operations should still show notifications to user

---

## 🚀 Next Task

**1272c: Unify Notifications - Low-Impact Migration + Cleanup**
- Remaining 23 files (1 usage each) + remove ShowNotification from EventBus
- Final step of unification

---

## 📌 Notes - Phase 2 of 3

- **Cumulative**: Phase 1 pattern is now proven and reusable
- **Systematic**: 6 medium files = good mix of coverage
- **Validation**: Tests will confirm no regressions
- **Momentum**: After phase 2, phase 3 becomes simple cleanup
- **Architecture**: Getting closer to single source of truth

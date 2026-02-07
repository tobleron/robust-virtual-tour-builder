# 1272c: Unify Notifications - Low-Impact Migration + EventBus Cleanup

**Status**: Pending
**Priority**: High (Core system unification - Phase 3/3)
**Effort**: 1 hour
**Dependencies**: 1272b (Phase 2 must complete first)
**Blocks**: None (final phase)
**Scalability**: ⭐⭐⭐⭐⭐ (Cleanup and consolidation)
**Reliability**: ⭐⭐⭐⭐⭐ (Simple single-usage migrations + type removal)

---

## 🎯 Objective

**Phase 3 of 3 (FINAL)**: Complete migration of remaining low-impact ShowNotification calls (16 usages across 23 files, mostly 1 usage each), then remove ShowNotification from EventBus type definition. This achieves **true architectural unification** - NotificationManager becomes the single source of truth.

**Outcome**: All 64 ShowNotification calls migrated, EventBus cleaned of notification concerns, true unified notification system ready for production.

---

## 📋 Acceptance Criteria

✅ **Phase 3 Completion (16 usages + cleanup)**
- [ ] All 23 remaining files migrated (1 usage each)
  - FloorNavigation, HotspotActionMenu, LinkModal, NotificationContext, PreviewArrow, ReturnPrompt, SceneItem, SceneLoader, SceneSwitcher, SimulationNavigation, Simulation, InputSystem, LinkEditorLogic, UploadProcessorLogic, UploadReport, ViewerSnapshot
  - EventBus.res (2 entries), LabelMenu (1), TeaserLogic (1), ProjectManager (1), AuthenticatedClient (1), SceneList (1)
- [ ] ShowNotification removed from EventBus type definition
- [ ] ShowNotification removed from EventBus dispatch logging

✅ **EventBus Cleanup**
- [ ] Type definition contains only 13 event variants (no ShowNotification)
- [ ] Dispatch logging no longer handles ShowNotification case
- [ ] EventBus focused on domain events only:
  - Navigation: NavStart, NavCompleted, NavCancelled, NavProgress
  - Scene/UI: SceneArrived, ClearSimUi, LinkPreviewStart, LinkPreviewEnd
  - Modal/Processing: ShowModal, CloseModal, UpdateProcessing
  - Hotspot: OpenHotspotMenu, ForceHotspotSync, TriggerUpload

✅ **Code Quality**
- Zero compilation errors
- Zero compiler warnings
- All 37 previous phase 1+2 migrations still work
- Code formatted with `npm run rs:fmt`

✅ **Full Unification Achieved**
- All 64 ShowNotification calls migrated ✅
- ShowNotification removed from EventBus ✅
- NotificationManager is single source of truth ✅
- Clean architecture with focused concerns ✅
- All 787+ tests pass ✅

---

## 📝 Implementation Checklist

**Batch 1: Single-usage files (migrate in groups)**
- [ ] FloorNavigation.res (1)
- [ ] HotspotActionMenu.res (1)
- [ ] LinkModal.res (1)
- [ ] NotificationContext.res (1)
- [ ] PreviewArrow.res (1)
- [ ] ReturnPrompt.res (1)
- [ ] SceneItem.res (1)
- [ ] SceneLoader.res (1)
- [ ] SceneSwitcher.res (1)
- [ ] SimulationNavigation.res (1)
- [ ] Simulation.res (1)
- [ ] InputSystem.res (1)
- [ ] LinkEditorLogic.res (1)
- [ ] UploadProcessorLogic.res (1)
- [ ] UploadReport.res (1)
- [ ] ViewerSnapshot.res (1)

**Batch 2: EventBus type cleanup**
- [ ] Read EventBus.res (should still have ShowNotification from phases 1-2)
- [ ] Remove ShowNotification from type event definition (line 39)
- [ ] Remove ShowNotification case from dispatch logging (lines 71-78)
- [ ] Format with `npm run rs:fmt`

**Verification**:
- [ ] Compile: `npm run res:build` - 0 errors, 0 warnings
- [ ] Tests: `npm test` - all 787+ pass
- [ ] Search: `grep -r "ShowNotification" src/` - should be empty (only in NotificationTypes)
- [ ] Manual: Spot check 3-4 key operations (upload, scene load, floor nav)

---

## 📊 Migration Pattern (Established in Phases 1-2)

**All files follow identical pattern:**
```rescript
// OLD (EventBus)
EventBus.dispatch(ShowNotification("Message", #Error, None))

// NEW (NotificationManager)
NotificationManager.dispatch({
  id: "",
  importance: Error,
  context: Operation("feature_name"),
  message: "Message",
  details: None,
  action: None,
  duration: NotificationTypes.defaultTimeoutMs(Error),
  dismissible: true,
  createdAt: Date.now(),
})
```

**Context for single-usage files:**
- Floor navigation: `Operation("floor_nav")`
- Hotspot menu: `Operation("hotspot_menu")`
- Link modal: `Operation("link_modal")`
- Scene transitions: `Operation("scene_loading")`
- Simulation: `Operation("simulation")`
- API/upload: `Operation("upload")` or `Operation("api")`

---

## 🔍 Quality Gates

| Gate | Condition | Check |
|------|-----------|-------|
| Compilation | 0 errors, 0 warnings | `npm run res:build` |
| Tests | All 787+ pass | `npm test` |
| Phases 1-2 | 37 migrations still working | Previous tests pass |
| Cleanup | No ShowNotification remains | `grep -r "ShowNotification" src/` |
| Architecture | EventBus cleaned | EventBus type definition review |

---

## 🔄 Rollback Plan

**If compilation fails on single-usage files:**
1. Check if NotificationManager is imported
2. Verify type mapping (Error, Warning, Success, Info)
3. Run `npm run rs:fmt`
4. Rebuild single file: `npm run res:build`

**If EventBus removal fails:**
1. Carefully remove ONLY ShowNotification line from type
2. Carefully remove ONLY ShowNotification case from dispatch
3. Verify no syntax errors with `npm run rs:fmt`
4. Compile: `npm run res:build`

**If tests fail:**
1. Check if phases 1-2 files still compile
2. Verify NotificationManager is working
3. Run tests individually: `npx vitest specific_file.test.bs.js`
4. Compare EventBus changes with phase 1-2 approach

---

## 💡 Implementation Tips

1. **Single-usage files are fast**: Each file is ~5 minutes, no complex logic
2. **Batch processing**: Do 5-6 files, test, then do EventBus cleanup
3. **EventBus is last**: Don't remove ShowNotification until all migrations complete
4. **Double-check contexts**: Make sure Operation names are descriptive
5. **Final sweep**: After EventBus cleanup, grep to verify no references remain

---

## 📊 Cumulative Progress

| Phase | Files | Usages | Duration | Status |
|-------|-------|--------|----------|--------|
| 1272a | 3 | 18 | 1 hr | Pending |
| 1272b | 6 | 19 | 1.5 hrs | Pending |
| 1272c | 23 | 16 + cleanup | 1 hr | **THIS TASK** |
| **TOTAL** | **29** | **64** | **3.5 hrs** | - |

---

## 🎉 Success Criteria - FINAL

After 1272c completes:
- ✅ **64/64 ShowNotification calls migrated**
- ✅ **ShowNotification removed from EventBus**
- ✅ **NotificationManager is single notification source**
- ✅ **All 787+ tests passing**
- ✅ **Zero compilation errors/warnings**
- ✅ **Architecture unified and clean**

Ready for:
- 1273: Mount NotificationCenter in App
- 1274: Integration testing & verification

---

## 🚀 Next Task

**1273: Mount NotificationCenter in App**
- Now all notifications funnel through NotificationManager
- NotificationCenter component can render them

---

## 📌 Notes - Phase 3 of 3 (FINAL)

- **Completion**: This task achieves true architectural unification
- **Simplicity**: Single-usage files = quick, systematic migration
- **Validation**: 787+ tests will confirm everything works
- **Cleanup**: Removing ShowNotification from EventBus is final cleanup step
- **Production Ready**: After this task, system is fully unified
- **Technical Debt Eliminated**: No duplicate notification paths, no legacy code

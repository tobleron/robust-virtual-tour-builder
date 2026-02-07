# 1273: Mount NotificationCenter in App - Component Integration

**Status**: Pending
**Priority**: High (Final component wiring)
**Effort**: 0.5 hours
**Dependencies**: 1271 (NotificationCenter component must exist)
**Scalability**: ⭐⭐⭐⭐⭐ (Trivial change, unblocks integration tests)
**Reliability**: ⭐⭐⭐⭐ (Simple integration point)

---

## 🎯 Objective

Mount the NotificationCenter React component in App.res so that notifications are rendered on the page. This is a simple component integration - find where to insert it and add the component tag.

**Outcome**: NotificationCenter component mounted and visible in app, debug widget appears in bottom-right, ready for integration testing.

---

## 📋 Acceptance Criteria

✅ **Code Quality**
- Zero compilation errors
- Zero compiler warnings
- Component properly imported and used

✅ **Functionality**
- NotificationCenter component renders
- Debug widget visible on page (bottom-right corner)
- Positioned above other content (proper z-index)
- No console errors

✅ **Integration**
- Component mounted alongside LockFeedback and other UI
- App still starts without errors
- All existing UI still works

---

## 📝 Implementation Checklist

**Code Changes**:
- [ ] Open file: `src/App.res`
- [ ] Locate where `<LockFeedback />` is mounted
- [ ] Import NotificationCenter: `let module NotificationCenter = NotificationCenter`
- [ ] Add component to render tree
- [ ] Verify component is at same level as other persistent UI
- [ ] Check z-index layering (should be above main content)

**Verification**:
- [ ] Compile: `npm run res:build`
- [ ] 0 errors, 0 warnings
- [ ] Browser loads
- [ ] Debug widget visible (blue box, bottom-right)
- [ ] No console errors
- [ ] Trigger notification
- [ ] Widget updates with count

---

## 🧪 Testing

**Verification Steps**:
1. Compile: `npm run res:build`
2. Start dev server: `npm run dev`
3. Open browser console: No errors
4. Look for blue debug widget: Should be visible bottom-right
5. Trigger a notification (click upload, trigger error, etc.)
6. Watch widget update: Count should increase

---

## 📊 Code Template

```rescript
// In src/App.res, locate the render section and add:

// At top of file with other imports:
// (depending on how App is structured)

// In the main render/JSX section, find where other persistent UI components are:
// Look for patterns like:
// <LockFeedback />
// <NotificationLayer />

// Then add NotificationCenter alongside them:
<>
  <NotificationLayer />
  <NotificationCenter />  {/* ADD THIS LINE */}
  <LockFeedback />
  // ... rest of your UI
</>
```

---

## 🔍 Quality Gates (Must Pass Before 1274 Starts)

| Gate | Condition | Check |
|------|-----------|-------|
| Compilation | 0 errors, 0 warnings | `npm run res:build` output |
| Renders | Component mounts cleanly | No console errors |
| Visibility | Widget appears on page | Visual inspection |
| Integration | App still works | All existing UI functional |

---

## 🔄 Rollback Plan

If compilation fails:
1. Check import statement for NotificationCenter
2. Verify file path: `src/components/NotificationCenter`
3. Check component name and capitalization
4. Verify React JSX syntax is correct
5. Run `npm run res:fmt` to auto-fix

If component doesn't appear:
- Check browser DevTools Elements tab for `<div className="fixed inset-0...">`
- Verify z-index is high enough (should be 40 or higher)
- Check app actually reloaded after compile
- Verify src/components/NotificationCenter.res exists

If app breaks:
- Remove the NotificationCenter component line
- Verify other components still work
- Check for import errors
- Re-add with correct syntax

---

## 💡 Implementation Tips

1. **Find the right place**: Look for where other persistent UI components mount
2. **Check z-index**: Ensure widget is visible above other content
3. **Compile early**: Verify compilation before moving to next task
4. **Visual verification**: Widget should be clearly visible when app loads
5. **Test with real data**: Trigger a notification to see state update

---

## 🚀 Next Tasks

After component mounts successfully:
- **1274: Integration testing & verification** (depends on this)

---

## 📌 Notes

- **Trivial Task**: Should complete in <30 minutes
- **Integration Point**: Component now part of app render tree
- **Zero Breaking Changes**: Only adds new component, doesn't modify existing
- **Scalability**: Component is self-contained, easy to move/remove if needed
- **Reliability**: Simple DOM insertion, no state complications

# 1271: Create NotificationCenter Component - UI Rendering

**Status**: Pending
**Priority**: High (Main UI component)
**Effort**: 1 hour
**Dependencies**: 1266 (NotificationTypes), 1269 (NotificationManager)
**Can Parallelize With**: 1270, 1272 (only depends on 1266, 1269)
**Scalability**: ⭐⭐⭐⭐ (Reusable React component)
**Reliability**: ⭐⭐⭐⭐ (Simple rendering, subscription testing in 1270)

---

## 🎯 Objective

Create the React component that subscribes to NotificationManager state and renders notifications. Phase 1 uses a minimal debug widget showing active notification count. Full toast/modal rendering happens in Phase 2.

**Outcome**: Minimal NotificationCenter component that subscribes to manager, renders placeholder widget, ready for Phase 2 styling and animation.

---

## 📋 Acceptance Criteria

✅ **Code Quality**
- Zero ReScript compilation errors
- Zero compiler warnings
- Proper React component patterns
- Subscription cleanup working

✅ **Functionality**
- Component mounts without errors
- Subscribes to NotificationManager on mount
- Receives state updates
- Unsubscribes on unmount
- Re-renders when state changes

✅ **Rendering**
- Shows debug widget (temporary placeholder)
- Displays active notification count
- Widget visible in browser (z-index, positioning)
- No console errors

✅ **Architecture**
- Uses React hooks (useState, useEffect)
- Subscription pattern: subscribe on mount, unsubscribe on unmount
- State passed through component state, not context

---

## 📝 Implementation Checklist

**Component Structure**:
- [ ] Create file: `src/components/NotificationCenter.res`
- [ ] Use `@react.component` decorator
- [ ] Implement with `make` function

**Subscription**:
- [ ] Use `React.useState` to track queue state
- [ ] Initialize with `NotificationManager.getState()`
- [ ] Use `React.useEffect` with empty dependency array
- [ ] Subscribe to NotificationManager on mount
- [ ] Store unsubscribe function
- [ ] Return cleanup function from useEffect

**Rendering (Phase 1 - Debug Widget)**:
- [ ] Render fixed position div (bottom-right)
- [ ] Show active notification count
- [ ] Add pointer-events-auto so it's clickable (if needed)
- [ ] Use Tailwind classes for styling
- [ ] No toast rendering yet (Phase 2)
- [ ] No modal rendering yet (Phase 2)
- [ ] No progress widget yet (Phase 2)

**Component Memoization**:
- [ ] Wrap with `React.memo` to prevent unnecessary re-renders
- [ ] Only re-render if props change (none in Phase 1)

**Compilation**:
- [ ] Run `npm run res:build` - verify 0 warnings
- [ ] Verify component exports properly

---

## 🧪 Testing

**Verification Steps** (manual - no unit tests yet):
1. Compile: `npm run res:build`
2. Check for warnings: 0 allowed
3. Start dev server: `npm run dev`
4. Open browser to localhost
5. Verify NotificationCenter mounts: No errors in console
6. Trigger a notification: Should see debug widget update count
7. Verify unsubscribe: Dispatch notification, check state updates

---

## 📊 Code Template

```rescript
// src/components/NotificationCenter.res

open NotificationTypes

@react.component
let make = React.memo(() => {
  // Track queue state in component
  let (state, setState) = React.useState(_ => {
    NotificationManager.getState()
  })

  // Subscribe to manager on mount, unsubscribe on unmount
  React.useEffect0(() => {
    let unsubscribe = NotificationManager.subscribe(newState => {
      setState(_ => newState)
    })

    // Cleanup: unsubscribe on unmount
    Some(unsubscribe)
  })

  // Active notification count
  let activeCount = Belt.Array.length(state.active)

  // Phase 1: Debug widget showing active count
  <div className="fixed inset-0 pointer-events-none z-40">
    <div className="fixed bottom-4 right-4 pointer-events-auto bg-blue-500 text-white px-4 py-2 rounded text-sm font-medium">
      {React.string("Active: " ++ Int.toString(activeCount))}
    </div>
  </div>
})
```

---

## 🔍 Quality Gates (Must Pass Before 1272 Starts)

| Gate | Condition | Check |
|------|-----------|-------|
| Compilation | 0 errors, 0 warnings | `npm run res:build` output |
| No Console Errors | Component mounts cleanly | Browser console clear |
| Subscription Works | State updates on dispatch | Manual test in browser |
| Cleanup Works | Unsubscribe fires on unmount | React DevTools or manual test |

---

## 🔄 Rollback Plan

If compilation fails:
1. Check React.useState type syntax
2. Verify useEffect0 vs useEffect with dependencies
3. Check React.memo wrapping
4. Verify NotificationManager.subscribe return type is unsubscribe function
5. Run `npm run res:fmt` to auto-fix

If component doesn't render:
- Check App.res to verify component is mounted
- Verify z-index is high enough to be visible
- Check browser dev tools for DOM presence
- Use Logger.debug to trace rendering

If subscription doesn't work:
- Verify NotificationManager.subscribe is called
- Check setState is being called
- Use Logger.debug in subscribe callback to trace updates

---

## 💡 Implementation Tips

1. **React hooks**: Use `React.useEffect0` for no-dependency effect (mount/unmount only)
2. **Cleanup**: Return unsubscribe function from useEffect
3. **Memoization**: Use React.memo to prevent unnecessary re-renders
4. **Debug widget**: Simple placeholder for Phase 1, full rendering in Phase 2
5. **State management**: Component owns state, subscribed to manager via listener

---

## 🚀 Next Tasks

After this renders successfully:
- **1272: Add backward compat to EventBus** (can start in parallel)
- **1273: Mount NotificationCenter in App** (depends on 1271)

---

## 📌 Notes

- **Phase 1 Scope**: Debug widget only, minimal rendering
- **Phase 2 Scope**: Full toast rendering with animations, modals, progress widget
- **Dependency**: NotificationManager must be exported and working
- **Scalability**: Simple component, easy to enhance with more complex rendering
- **Reliability**: Subscription pattern ensures component stays in sync with manager

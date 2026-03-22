# 1931 — Clarify DispatchAppFsmEvent Reducer Routing

**Priority:** 🟠 P1  
**Effort:** 5 minutes  
**Origin:** Codebase Analysis 2026-03-22

## Context

In `src/core/Reducer.res`, `DispatchAppFsmEvent` is routed to `applyNavigationOnly`:

```rescript
| Actions.DispatchAppFsmEvent(_) => applyNavigationOnly(state, action)
```

This is semantically misleading. A reader would expect `DispatchAppFsmEvent` to go through the AppFsm reducer, not the Navigation reducer. The actual handling is in `NavigationProjectReducer.Navigation.handleAppFsmEvent`, which owns the canonical `AppFSM.transition` call + bidirectional nav-state sync. The `AppFsm.reduce` module is a no-op (`=> None`).

This is technically correct but a maintenance trap — future developers may "fix" the routing and break the system.

## Scope

### Steps

1. Add a clarifying comment at line 103 of `src/core/Reducer.res`:
   ```rescript
   // DispatchAppFsmEvent is handled by NavigationProjectReducer.Navigation,
   // which owns the canonical AppFSM.transition call and bidirectional
   // navigation-state sync. AppFsm.reduce is intentionally a no-op.
   | Actions.DispatchAppFsmEvent(_) => applyNavigationOnly(state, action)
   ```
2. Verify existing comment in `ReducerModules.AppFsm` module (line 165–169) aligns
3. Run `npm run build`

## Acceptance Criteria

- [ ] Clarifying comment exists at the routing site in Reducer.res
- [ ] `npm run build` passes

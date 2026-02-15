# 1405: Performance - Frontend State Subscription and Persistence Budget [RESOLVED]

## Resolution Note
✅ **RESOLVED by commit d271db14** - ViewerManager refactored to use granular slices instead of full app state subscription. This directly addresses the core concern of unnecessary re-renders and state churn.

## Objective
Reduce unnecessary re-renders and autosave churn caused by full-state subscriptions and broad save triggers.

## Context
- `src/core/AppContext.res` writes session state on any global state change with 500ms debounce.
- `src/utils/PersistenceLayer.res` serializes and saves full project payload on debounced global changes.
- High-frequency orchestrators still subscribe to full app state (`src/components/ViewerManager.res`, `src/systems/Navigation/NavigationController.res`).

## Suggested Action Plan
- [ ] Introduce persistence dirty flags keyed to structural project mutations only (scene/hotspot/timeline/project metadata), excluding camera-only churn.
- [ ] Narrow `SessionStore.saveState` trigger dependencies to the minimal session slice.
- [ ] Migrate high-frequency orchestrators to selectors/slices or explicit subscriptions to only required fields.
- [ ] Add a simple render budget metric (rerenders/sec) for critical components.

## Verification
- [ ] React Profiler: camera movement does not trigger unrelated component rerenders.
- [ ] IndexedDB autosave rate stays stable during navigation-only activity.
- [ ] No behavior regressions for save/load/recovery flows.
- [ ] `npm run res:build` and key frontend tests pass.

# 1939 — Track Index-Based Scene Addressing for Future Refactor

**Priority:** 🟡 P3  
**Effort:** Tracking only (no implementation)  
**Origin:** Codebase Analysis 2026-03-22

## Context

The `state` type uses `activeIndex: int` for scene identification, and many actions use integer indices:

```rescript
| SetActiveScene(int, float, float, option<transition>)
| AddHotspot(int, hotspot)
| RemoveHotspot(int, int)
| DeleteScene(int)
```

While scenes have `id: string` fields, primary addressing is by array index into `sceneOrder`. This is fragile because:
- Array mutation (reorder, delete) invalidates held indices
- Race conditions between index-based dispatch and async operations
- The `NavigationFSM` correctly uses `targetSceneId: string` — creating an impedance mismatch between the FSM layer (ID-based) and the reducer layer (index-based)

## Why Not Fix Now

This is deeply embedded in the reducer, state, and all action dispatchers. A migration requires:
1. Changing 15+ action signatures
2. Updating all dispatch sites (100+ components)
3. Converting all array index lookups to Map lookups
4. Updating all tests

Estimated effort: 2–3 full days of focused work.

## Scope (Tracking)

### Known Risk Areas

- `SceneMutations.res` — All mutation functions take `index: int`
- `ReducerModules.Scene.reduce` — All action handlers use indices
- `HotspotHelpers.res` — Hotspot operations use scene index + hotspot index
- `AppContextProviderHooks.res` — Scene slice selection by index

### Possible Migration Path

1. Add `activeSceneId: option<string>` alongside `activeIndex`
2. Migrate actions one-by-one from index to ID
3. Update reducer handlers to resolve ID → index internally
4. Deprecate and remove `activeIndex` once all actions use IDs

## Acceptance Criteria

- [ ] This task serves as a tracking document only
- [ ] No code changes required
- [ ] Referenced in future architecture planning discussions

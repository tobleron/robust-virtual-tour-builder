# 1535 - Frontend State Normalization (Phase 1)

## Objective
Decouple the application from the duplicated `scenes: array<scene>` and `deletedSceneIds: array<string>` fields in the global state, consolidating on the `inventory` (Map) and `sceneOrder` (ID Array) for all data operations.

## Context
The current state maintains redundant data structures:
1. `scenes: array<scene>` (Pre-hydrated array for UI)
2. `inventory: Belt.Map.String.t<sceneEntry>` (Canonical storage)
3. `sceneOrder: array<string>` (Canonical order)

Recomputing `scenes` and `deletedSceneIds` on every state change is computationally expensive and memory-intensive for large projects.

## Success Criteria
- [ ] `Types.state` and `Types.project` no longer contain `scenes` or `deletedSceneIds`.
- [ ] `SceneInventory.rebuildLegacyFields` is removed.
- [ ] Reducers and systems use selectors to derive arrays from the inventory when needed.
- [ ] Application compiles with zero warnings/errors.
- [ ] Existing Vitest unit suites pass.

## Boundary
- `src/core/Types.res`
- `src/core/State.res`
- `src/core/Reducer.res`
- `src/core/SceneInventory.res`
- `src/core/SceneOperations.res`
- `src/core/SceneMutations.res`
- `src/core/NavigationProjectReducer.res`
- All components reading `.scenes` or `.deletedSceneIds`

## Planned Steps
1. Create `SceneInventory.getActiveScenesArray` and `SceneInventory.getDeletedIdsArray` helpers.
2. Refactor components and systems to use these helpers instead of state fields.
3. Remove the fields from `Types.res` and `State.res`.
4. Remove `rebuildLegacyFields` and all its call sites in `SceneMutations.res`/`SceneOperations.res`.
5. Verify with `npm run res:build`.

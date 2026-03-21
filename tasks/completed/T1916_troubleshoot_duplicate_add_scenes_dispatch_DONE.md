- [ ] Hypothesis (Ordered Expected Solutions)
  - [x] The duplicate `ADD_SCENES_*` logs come from `AppContextProviderHooks.useManagedDispatch` calling `Reducer.reducer` once for bridge sync and then a second time through `React.useReducer`.
  - [x] The duplicate logs do not come from a second explicit `AddScenes` dispatch after upload finalization.
  - [x] The stale dev-mode rendering issue amplified observability earlier, but the direct duplicate reducer execution was the actual remaining cause.

- [ ] Activity Log
  - [x] Read `MAP.md`, `DATA_FLOW.md`, `tasks/TASKS.md`, `.agent/workflows/debug-standards.md`, and `.agent/workflows/rescript-standards.md`.
  - [x] Traced `ADD_SCENES_*` log origin to `src/core/SceneOperationsCollection.res`.
  - [x] Traced upload dispatch path to `src/systems/Upload/UploadFinalizer.res`.
  - [x] Identified the reducer double-execution path in `src/core/AppContextProviderHooks.res`.
  - [x] Patched bridge synchronization so reducer logic executes once per action.
  - [x] Verified with `npm run build` and `npm test`.

- [ ] Code Change Ledger
  - [x] `src/core/AppContext.res`: move bridge synchronization into the reducer wrapper used by `React.useReducer`; revert by restoring direct `Reducer.reducer`.
  - [x] `src/core/AppContextProviderHooks.res`: remove speculative reducer execution from `useManagedDispatch`; revert by restoring precomputed `nextState` path.
  - [x] `tasks/active/T1916_troubleshoot_duplicate_add_scenes_dispatch.md`: troubleshooting record only.

- [ ] Rollback Check
  - [x] Confirmed CLEAN for working changes; no non-working edits were left behind.

- [ ] Context Handoff
  - [x] The duplicate `ADD_SCENES_*` logs were traced to reducer execution occurring twice for non-batched actions. `useManagedDispatch` was precomputing `Reducer.reducer(currentState, action)` for bridge synchronization, then `React.useReducer` executed the reducer again. The fix moves bridge synchronization into the reducer wrapper used by `React.useReducer`; verification passed with `npm run build` and `npm test`.

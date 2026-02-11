# [1346] Replace GlobalStateBridge in Core Context & Initialization

## Priority: P2 (Medium)

## Context
`App`, `AppContext`, `Main`, `OptimisticAction`, and `StateInspector` still interact with `GlobalStateBridge`, which keeps the global singleton alive even though the rest of the app uses `AppContext`. Initialization flows dispatch events and expose the state snapshot through the bridge, while optimistic rollback logic relies on `GlobalStateBridge` for snapshots and dispatching.

## Objective
1. Remove all remaining `GlobalStateBridge` usage from `AppContext`, providing hooks and deferred getters for pure logic modules instead.
2. Refactor `App`, `Main`, and `OptimisticAction` to use the new context-based API for dispatching actions and reading state snapshots (including rollback paths).
3. Update `StateInspector` to consume the new getter/loader hooks rather than accessing the bridge directly.

## Implementation Steps
1. Introduce explicit helpers in `AppContext` for `getState`/`getDispatch` that can be passed down to non-React modules, and provide safe hooks for `stateRef` if needed for utilities such as `StateInspector` or `OptimisticAction`.
2. Replace `GlobalStateBridge.dispatch`/`getState` in `App` and `Main` with the new hooks or helper closures created near the `Provider` component.
3. Refactor `OptimisticAction.execute` to accept a `getState`/`dispatch` pair instead of directly reaching into the bridge (e.g., pass them from the caller). Ensure `StateSnapshot.capture`/`rollback` still works by supplying the current state.
4. Update `StateInspector` to use the new exposed getters for the window debug store.

## Verification
1. `npm run build` passes with zero warnings.
2. `StateInspector` still exposes `window.store` when enabled and the data matches the current state.
3. Optimistic rollback flow still records snapshots and dispatches actions successfully.


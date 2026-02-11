# [1345] Replace GlobalStateBridge in Persistence + Recovery Layers

## Priority: P2 (Medium)

## Context
`PersistenceLayer`, `RecoveryManager`, and the project recovery flow still subscribe and dispatch via `GlobalStateBridge`. Every time `state` changes we hook into the bridge to autosave, and recovery/wait loops reach into `GlobalStateBridge` to listen for state updates or dispatch load actions. This keeps the bridge entrenched even though the rest of the app already runs through `AppContext`.

## Objective
1. Update `PersistenceLayer` so it gets `state` updates and dispatch callbacks via context or injection instead of subscribing to `GlobalStateBridge`.
2. Update `Main.res` persistence hook + recovery initialization to work with the new API.
3. Refactor `ProjectManager.recoverSaveProject` so it no longer polls `GlobalStateBridge`, and make `RecoveryManager.registerHandler("SaveProject", ...)` operate on the new dependency injection pattern.

## Implementation Steps
1. Expose `PersistenceLayer.initSubscriber` with a signature `(~getState: unit => Types.state, ~onChange: Types.state => unit) => unit` and remove direct `GlobalStateBridge` calls. Root initialization passes `AppContext.useAppState` (or a memoized state getter) and `AppContext.useAppDispatch` where needed.
2. Replace the `GlobalStateBridge` subscriptions inside `ProjectManager.recoverSaveProject` with the new helper that accepts a state getter/dispatch function. Consider wrapping the wait-for-state-update logic in a helper that accepts those params.
3. Update `Main.res` to wire up `PersistenceLayer.initSubscriber` with context-based getter/dispatch and remove remaining `GlobalStateBridge` usage in the global click handler, replacing it with `AppContext` or `dispatch` passed from the viewer click listener context (maybe by passing the handler down to the viewer setup). Document the new flow.

## Verification
1. `npm run build` passes with zero warnings.
2. Autosave/recovery still triggers when scenes load/save.
3. `PersistenceLayer` unit tests (if any) no longer import `GlobalStateBridge`.


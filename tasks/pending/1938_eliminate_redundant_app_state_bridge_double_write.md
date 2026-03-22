# 1938 — Eliminate Redundant AppStateBridge Double-Write

**Priority:** 🟡 P3  
**Effort:** 20 minutes  
**Origin:** Codebase Analysis 2026-03-22

## Context

In `src/core/AppContext.res`, `AppStateBridge.updateState` is called in two places:

1. **Inside the reducer callback** (line 110):
   ```rescript
   let reducerWithBridge = React.useCallback((state, action) => {
     let nextState = Reducer.reducer(state, action)
     AppStateBridge.updateState(nextState)   // ← Write 1
     nextState
   }, ())
   ```

2. **Synchronously after `useReducer`** (line 117):
   ```rescript
   let (state, dispatchRaw) = React.useReducer(reducerWithBridge, loadedState)
   AppStateBridge.updateState(state)          // ← Write 2 (claimed "eliminate bridge lag")
   ```

Write 2 is the authoritative "eliminate lag" write, making Write 1 redundant for most renders. The reducer callback write happens during React's reducer execution, while the synchronous write happens before children render.

## Scope

### Steps

1. Analyze if removing Write 1 (inside `reducerWithBridge`) causes any behavioral difference:
   - Check if any `AppStateBridge.subscribe` listener reads state *during* the same reducer dispatch
   - If no subscriber reads mid-dispatch, Write 1 is safely removable
2. If safe, remove the `AppStateBridge.updateState(nextState)` call from `reducerWithBridge`
3. Add a comment explaining why Write 2 is the sole authority
4. Run `npm run build` and `npm run test:frontend`
5. Manually test navigation and upload flows to verify no bridge lag

## Acceptance Criteria

- [ ] Only one `AppStateBridge.updateState` call exists in `AppContext.Provider`
- [ ] Comment explains the rationale
- [ ] `npm run build` passes
- [ ] No behavioral regression in navigation or upload flows

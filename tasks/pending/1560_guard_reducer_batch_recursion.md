# 1560 — Guard Reducer Batch Action Against Infinite Recursion

## Priority: P1 — Hardening

## Objective
Add a recursion depth guard to `Reducer.res` `Batch(actions)` handling to prevent potential stack overflow from nested batch actions.

## Context
`Reducer.res` line 70 handles batch actions recursively:

```rescript
| Actions.Batch(actions) => Belt.Array.reduce(actions, state, (s, a) => reducer(s, a))
```

If a `Batch` action contains another `Batch` action (or transitively produces one via `RestoreState`), this recurses without limit. While the current codebase doesn't intentionally create nested batches, this is a defensive hardening gap:

- Future code changes could accidentally produce nested batches
- An import or state deserialization could produce a deeply nested action tree
- The `RestoreState(nextState)` case on line 69 could be inside a batch, leading to subtle state corruption

## Recommended Fix
Add a `MAX_BATCH_DEPTH` constant and a depth parameter:

```rescript
let maxBatchDepth = 3

let rec reducer = (~depth: int=0, state: state, action: Actions.action): state => {
  switch action {
  | Actions.Batch(actions) if depth < maxBatchDepth =>
    Belt.Array.reduce(actions, state, (s, a) => reducer(~depth=depth + 1, s, a))
  | Actions.Batch(_) =>
    Logger.error(~module_="Reducer", ~message="MAX_BATCH_DEPTH exceeded, dropping batch", ())
    state
  | ...
  }
}
```

## Acceptance Criteria
- [ ] Batch recursion has a depth limit (3 levels is sufficient)
- [ ] Exceeding the limit logs an error and returns the current state (no crash)
- [ ] Normal batch operations continue to work (single-level batches are common)
- [ ] Builds cleanly

## Files to Modify
- `src/core/Reducer.res` (single file change)

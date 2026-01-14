# Report: Migrate Store.res to Logger System

## Objective (Completed)
Update Store.res to use the new Logger module for tracking state changes (at debug/trace level).

## Context
Store manages the application's central state. Logging state changes helps debug issues where the UI doesn't reflect expected state. However, state changes can be frequent, so logging should be at debug/trace level.

## Prerequisites
- Logger.res module exists ✅

## Implementation Details

### 1. Update State Dispatch

```rescript
let dispatch = (action: action): unit => {
  Logger.debug(~module_="Store", ~message="DISPATCH", ~data=Some({
    "action": actionToString(action)
  }), ())
  
  // ... apply action
  
  Logger.trace(~module_="Store", ~message="STATE_UPDATED", ~data=Some({
    "sceneCount": Belt.Array.length(state.scenes),
    "currentScene": state.currentSceneIndex
  }), ())
}
```

### 2. Action String Helper

```rescript
let actionToString = (action: action): string =>
  switch action {
  | SetScenes(_) => "SetScenes"
  | SetCurrentScene(idx) => `SetCurrentScene(${Belt.Int.toString(idx)})`
  | UpdateScene(_) => "UpdateScene"
  | AddHotspot(_) => "AddHotspot"
  | RemoveHotspot(_) => "RemoveHotspot"
  | SetTourName(_) => "SetTourName"
  | _ => "Unknown"
  }
```

### 3. Update Subscription Notifications

```rescript
let notifySubscribers = (): unit => {
  Logger.trace(~module_="Store", ~message="NOTIFY", ~data=Some({
    "subscriberCount": Belt.Array.length(subscribers)
  }), ())
}
```

## Standard Log Points

| Event | Level | Message | Data |
|-------|-------|---------|------|
| Dispatch | `debug` | `DISPATCH` | action name |
| State updated | `trace` | `STATE_UPDATED` | state summary |
| Notify | `trace` | `NOTIFY` | subscriberCount |

## Files to Modify

| File | Changes |
|------|---------|
| `src/Store.res` | Add Logger calls for state management |

## Testing Checklist

- [ ] Debug mode shows action dispatches
- [ ] Trace mode shows state after each change
- [ ] Action names are readable

## Definition of Done

- State changes logged at debug/trace level
- Action names converted to readable strings
- Minimal performance impact (trace level by default hidden)

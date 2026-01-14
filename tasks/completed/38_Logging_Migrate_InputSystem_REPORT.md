# Report: Migrate InputSystem.res to Logger System

## Objective (Completed)
Update InputSystem.res to use the new Logger module for tracking keyboard and global input handling.

## Context
InputSystem handles global keyboard shortcuts (ESC for cancel, debug toggles) and contextual input. Logging helps diagnose why a shortcut didn't work or what action was triggered.

## Prerequisites
- Logger.res module exists ✅

## Implementation Details

### 1. Update Initialization

```rescript
let init = (): unit => {
  Logger.initialized(~module_="InputSystem")
  // ... existing logic
}
```

### 2. Update ESC Key Handling

```rescript
// Modal close
Logger.debug(~module_="InputSystem", ~message="MODAL_CLOSE", ~data=Some({
  "modalId": modalId
}), ())

// Context menu close
Logger.debug(~module_="InputSystem", ~message="CONTEXT_MENU_CLOSE", ())

// Linking mode cancel
Logger.info(~module_="InputSystem", ~message="LINKING_CANCELLED", ())

// Auto-pilot stop
Logger.info(~module_="InputSystem", ~message="AUTOPILOT_STOPPED", ())
```

### 3. Update Debug Toggle

```rescript
// Ctrl+Shift+D
Logger.info(~module_="InputSystem", ~message="DEBUG_TOGGLE", ~data=Some({
  "newState": isEnabled ? "enabled" : "disabled"
}), ())
```

## Standard Log Points

| Event | Level | Message | Data |
|-------|-------|---------|------|
| Init | `info` | `InputSystem initialized` | - |
| Modal close | `debug` | `MODAL_CLOSE` | modalId |
| Context close | `debug` | `CONTEXT_MENU_CLOSE` | - |
| Linking cancel | `info` | `LINKING_CANCELLED` | - |
| Autopilot stop | `info` | `AUTOPILOT_STOPPED` | - |
| Debug toggle | `info` | `DEBUG_TOGGLE` | newState |

## Files to Modify

| File | Changes |
|------|---------|
| `src/systems/InputSystem.res` | Replace Debug calls with Logger calls |

## Testing Checklist

- [ ] ESC key actions are logged
- [ ] Debug toggle logs new state
- [ ] Modal closures logged in debug mode

## Definition of Done

- All Debug calls replaced with Logger calls
- Global input handling instrumented

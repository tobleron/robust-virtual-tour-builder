# Task: Migrate Navigation.res to Logger System

## Objective
Update Navigation.res to use the new Logger module with standardized log points for better observability.

## Context
Navigation is one of the most critical systems. It handles scene transitions, auto-forward logic, and coordinates with the viewer. Proper logging here helps diagnose stuck navigations, infinite loops, and timing issues.

## Prerequisites
- Logger.res module exists ✅
- Debug.js updated with perf() method ✅

## Implementation Steps

### 1. Import Logger Module

At the top of the file:

```rescript
// Use Logger instead of ReBindings.Debug
```

Note: Logger.res uses the same underlying Debug.js, so the output format is consistent.

### 2. Replace Initialization Log

```rescript
// Before
ReBindings.Debug.info("Navigation", "Navigation system initialized (ReScript)", ())

// After
Logger.initialized(~module_="Navigation")
```

### 3. Update navigateToScene Function

```rescript
let navigateToScene = async (targetIndex: int, ~animate: bool=true, ()): unit => {
  Logger.startOperation(~module_="Navigation", ~operation="NAV", ~data=Some({
    "targetIndex": targetIndex,
    "animate": animate
  }), ())
  
  // ... existing logic
  
  // On success:
  Logger.endOperation(~module_="Navigation", ~operation="NAV", ~data=Some({
    "targetIndex": targetIndex,
    "durationMs": elapsed
  }), ())
  
  // On blocked:
  Logger.warn(~module_="Navigation", ~message="NAV_BLOCKED", ~data=Some({
    "reason": "Navigation already in progress"
  }), ())
}
```

### 4. Update Auto-Forward Logging

```rescript
let processAutoForward = (scene: scene): unit => {
  Logger.debug(~module_="Navigation", ~message="AUTO_FORWARD_CHECK", ~data=Some({
    "sceneName": scene.name
  }), ())
  
  // On loop detected:
  Logger.warn(~module_="Navigation", ~message="LOOP_DETECTED", ~data=Some({
    "sceneName": scene.name
  }), ())
  
  // On jumping:
  Logger.info(~module_="Navigation", ~message="AUTO_FORWARD_JUMP", ~data=Some({
    "from": scene.name,
    "to": targetScene.name
  }), ())
}
```

### 5. Update Cancel Navigation

```rescript
let cancelNavigation = (): unit => {
  Logger.info(~module_="Navigation", ~message="NAV_CANCELLED", ())
  // ... existing logic
}
```

### 6. Use Logger.timed for Animation

```rescript
let animateToView = async (targetYaw: float, targetPitch: float): unit => {
  let {result: _, durationMs} = await Logger.timedAsync(
    ~module_="Navigation", 
    ~operation="ANIMATE_VIEW",
    async () => {
      // ... animation logic
    }
  )
  // Performance automatically logged
}
```

## Standard Log Points

| Event | Level | Message | Data |
|-------|-------|---------|------|
| Init | `info` | `Navigation initialized` | - |
| Start | `info` | `NAV_START` | targetIndex, animate |
| Complete | `info` | `NAV_COMPLETE` | targetIndex, durationMs |
| Blocked | `warn` | `NAV_BLOCKED` | reason |
| Cancelled | `info` | `NAV_CANCELLED` | - |
| Auto-forward | `info` | `AUTO_FORWARD_JUMP` | from, to |
| Loop detected | `warn` | `LOOP_DETECTED` | sceneName |
| Animation | `debug/perf` | `ANIMATE_VIEW` | durationMs |

## Files to Modify

| File | Changes |
|------|---------|
| `src/systems/Navigation.res` | Replace all Debug calls with Logger calls |

## Testing Checklist

- [ ] Navigation between scenes logs NAV_START and NAV_COMPLETE
- [ ] Rapid clicks log NAV_BLOCKED warning
- [ ] Auto-forward chain logs each jump
- [ ] Loop detection logs warning with scene name
- [ ] Animation duration appears in debug mode
- [ ] Cancel action is logged
- [ ] DEBUG.setLevel('debug') shows step-by-step flow

## Definition of Done

- All `ReBindings.Debug` calls replaced with `Logger` calls
- Standardized message format (ACTION_STATUS pattern)
- Performance timing for animations
- Clear data context in each log entry

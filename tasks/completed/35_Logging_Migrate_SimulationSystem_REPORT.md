# Report: Migrate SimulationSystem.res to Logger System

## Objective (Completed)
Update SimulationSystem.res to use the new Logger module for comprehensive simulation flow logging.

## Context
SimulationSystem manages auto-pilot tours and blink previews. It has complex state machines and pathfinding. Logging here helps diagnose stuck simulations, infinite loops, and state machine issues.

## Prerequisites
- Logger.res module exists ✅
- Debug.js updated with perf() method ✅

## Implementation Details

### 1. Update Initialization

```rescript
let init = (): unit => {
  Logger.initialized(~module_="Simulation")
  // ... existing logic
}
```

### 2. Update Auto-Pilot Start

```rescript
let startAutoPilot = (): unit => {
  Logger.startOperation(~module_="Simulation", ~operation="AUTOPILOT", ~data=Some({
    "startScene": currentScene.name,
    "mode": "auto"
  }), ())
  
  // ... existing logic
}
```

### 3. Update Scene Step

```rescript
let advanceToNextScene = (): unit => {
  Logger.debug(~module_="Simulation", ~message="SIM_STEP", ~data=Some({
    "currentScene": currentScene.name,
    "nextScene": nextHotspot.target,
    "visitedCount": visitedScenes.length
  }), ())
  
  // ... existing logic
}
```

### 4. Update Blink Mode

```rescript
let startBlinkPreview = (hotspotId: string): unit => {
  Logger.info(~module_="Simulation", ~message="BLINK_START", ~data=Some({
    "hotspotId": hotspotId,
    "mode": "preview"
  }), ())
}

let stopBlinkPreview = (): unit => {
  Logger.info(~module_="Simulation", ~message="BLINK_STOP", ())
}
```

### 5. Update Arrival Handling

```rescript
let onSceneArrival = (sceneIndex: int): unit => {
  Logger.debug(~module_="Simulation", ~message="SCENE_ARRIVED", ~data=Some({
    "sceneIndex": sceneIndex
  }), ())
  
  // Debounce warning
  if isDebouncing {
    Logger.warn(~module_="Simulation", ~message="ARRIVAL_DEBOUNCED", ())
    return
  }
}
```

### 6. Update Loop Detection

```rescript
// Infinite loop detected
Logger.warn(~module_="Simulation", ~message="INFINITE_LOOP_DETECTED", ~data=Some({
  "stateKey": stateKey,
  "visitedScenes": visitedScenes
}), ())

// Max steps reached
Logger.warn(~module_="Simulation", ~message="MAX_STEPS_REACHED", ~data=Some({
  "maxSteps": maxSteps
}), ())
```

### 7. Update Completion

```rescript
// Normal completion
Logger.endOperation(~module_="Simulation", ~operation="AUTOPILOT", ~data=Some({
  "reason": "no_reachable_scenes",
  "scenesVisited": visitedScenes.length
}), ())

// Return to start
Logger.info(~module_="Simulation", ~message="SIM_COMPLETE", ~data=Some({
  "reason": "returned_to_start"
}), ())
```

### 8. Update Path Generation

```rescript
let generatePath = (startScene: scene): array<pathStep> => {
  let {result: path, durationMs} = Logger.timed(
    ~module_="Simulation",
    ~operation="PATH_GENERATE",
    () => computePath(startScene)
  )
  
  Logger.debug(~module_="Simulation", ~message="PATH_COMPUTED", ~data=Some({
    "steps": Belt.Array.length(path),
    "durationMs": durationMs
  }), ())
  
  path
}
```

## Standard Log Points

| Event | Level | Message | Data |
|-------|-------|---------|------|
| Init | `info` | `Simulation initialized` | - |
| Start | `info` | `AUTOPILOT_START` | startScene, mode |
| Step | `debug` | `SIM_STEP` | current, next, visitedCount |
| Arrived | `debug` | `SCENE_ARRIVED` | sceneIndex |
| Debounced | `warn` | `ARRIVAL_DEBOUNCED` | - |
| Loop detected | `warn` | `INFINITE_LOOP_DETECTED` | stateKey |
| Max steps | `warn` | `MAX_STEPS_REACHED` | maxSteps |
| Complete | `info` | `AUTOPILOT_COMPLETE` | reason, scenesVisited |
| Blink start | `info` | `BLINK_START` | hotspotId, mode |
| Blink stop | `info` | `BLINK_STOP` | - |
| Path compute | `debug` | `PATH_COMPUTED` | steps, durationMs |

## Files to Modify

| File | Changes |
|------|---------|
| `src/systems/SimulationSystem.res` | Replace all Debug calls with Logger calls |

## Testing Checklist

- [ ] Auto-pilot logs start with scene name
- [ ] Each step logs current and next scene
- [ ] Loop detection logs warning with context
- [ ] Completion logs reason and stats
- [ ] Blink mode logs start/stop
- [ ] Path generation logs duration
- [ ] Debounce situations log warning

## Definition of Done

- All Debug/ReBindings.Debug calls replaced with Logger calls
- State machine transitions fully logged
- Performance timing for path computation
- Clear context for debugging stuck simulations

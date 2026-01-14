# Report: Migrate NavigationRenderer.res to Logger System

## Objective (Completed)
Update NavigationRenderer.res to use the new Logger module for tracking rendering and animation operations.

## Context
NavigationRenderer handles the visual rendering of navigation animations, including camera movement interpolation. Logging helps diagnose jerky animations, stalls, or rendering issues.

## Prerequisites
- Logger.res module exists ✅

## Implementation Details

### 1. Update Journey Start

```rescript
let startJourney = (params: journeyParams): unit => {
  Logger.info(~module_="NavRenderer", ~message="JOURNEY_START", ~data=Some({
    "targetYaw": params.targetYaw,
    "targetPitch": params.targetPitch,
    "duration": params.duration
  }), ())
  
  // Viewer not ready error
  Logger.error(~module_="NavRenderer", ~message="VIEWER_NOT_READY", ())
}
```

### 2. Update Journey Completion

```rescript
// Complete
Logger.info(~module_="NavRenderer", ~message="JOURNEY_COMPLETE", ~data=Some({
  "journeyId": params.journeyId,
  "durationMs": actualDuration
}), ())

// Cancelled
Logger.warn(~module_="NavRenderer", ~message="JOURNEY_CANCELLED", ~data=Some({
  "journeyId": params.journeyId
}), ())
```

### 3. Update Frame Rendering (Trace Level)

```rescript
let renderFrame = (progress: float): unit => {
  Logger.trace(~module_="NavRenderer", ~message="FRAME", ~data=Some({
    "progress": progress,
    "currentYaw": yaw,
    "currentPitch": pitch
  }), ())
}
```

## Standard Log Points

| Event | Level | Message | Data |
|-------|-------|---------|------|
| Start | `info` | `JOURNEY_START` | target coords, duration |
| Complete | `info` | `JOURNEY_COMPLETE` | journeyId, durationMs |
| Cancelled | `warn` | `JOURNEY_CANCELLED` | journeyId |
| Not ready | `error` | `VIEWER_NOT_READY` | - |
| Frame | `trace` | `FRAME` | progress, coords |

## Files to Modify

| File | Changes |
|------|---------|
| `src/systems/NavigationRenderer.res` | Replace Debug calls with Logger calls |

## Testing Checklist

- [ ] Journey start logs target coordinates
- [ ] Completion logs actual duration
- [ ] Cancellation logs warning
- [ ] Trace mode shows frame-by-frame

## Definition of Done

- All Debug calls replaced with Logger calls
- Animation lifecycle instrumented
- Trace level for frame debugging

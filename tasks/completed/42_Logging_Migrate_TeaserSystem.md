# Task: Migrate TeaserManager.res and TeaserRecorder.res to Logger System

## Objective
Update the teaser system modules to use the new Logger module for tracking teaser generation workflow.

## Context
The teaser system records video teasers by automating navigation and capturing frames. It's a complex multi-step process involving pathfinding, scene loading, canvas capture, and video encoding. Logging is essential for diagnosing why a teaser failed or what step it's stuck on.

## Prerequisites
- Logger.res module exists ✅

## Implementation Steps

### 1. TeaserManager - Update Generation Start

```rescript
let generateTeaser = async (style: teaserStyle): unit => {
  Logger.startOperation(~module_="Teaser", ~operation="GENERATE", ~data=Some({
    "style": styleToString(style),
    "sceneCount": Belt.Array.length(scenes)
  }), ())
```

### 2. TeaserManager - Update Path Generation

```rescript
let {result: path, durationMs} = Logger.timed(
  ~module_="Teaser",
  ~operation="PATH_GENERATE",
  () => TeaserPathfinder.getWalkPath(scenes, startScene)
)

Logger.info(~module_="Teaser", ~message="PATH_READY", ~data=Some({
  "steps": Belt.Array.length(path)
}), ())
```

### 3. TeaserManager - Update Scene Transitions

```rescript
// Scene loading
Logger.debug(~module_="Teaser", ~message="SCENE_LOAD", ~data=Some({
  "sceneName": scene.name,
  "stepIndex": currentStep
}), ())

// Scene captured
Logger.debug(~module_="Teaser", ~message="SCENE_CAPTURED", ~data=Some({
  "sceneName": scene.name,
  "frameCount": frames.length
}), ())
```

### 4. TeaserRecorder - Update Recording

```rescript
let startRecording = (): unit => {
  Logger.info(~module_="TeaserRecorder", ~message="RECORDING_START", ~data=Some({
    "width": canvasWidth,
    "height": canvasHeight,
    "fps": fps
  }), ())
}

let stopRecording = async (): blob => {
  Logger.info(~module_="TeaserRecorder", ~message="RECORDING_STOP", ~data=Some({
    "chunkCount": chunks.length
  }), ())
}
```

### 5. TeaserRecorder - Update Frame Capture

```rescript
let captureFrame = (): unit => {
  Logger.trace(~module_="TeaserRecorder", ~message="FRAME_CAPTURE", ~data=Some({
    "frameNumber": frameCount
  }), ())
}
```

### 6. Update Error Handling

```rescript
Logger.error(~module_="Teaser", ~message="GENERATE_FAILED", ~data=Some({
  "step": currentStep,
  "error": errorMessage
}), ())
```

### 7. Update Completion

```rescript
Logger.endOperation(~module_="Teaser", ~operation="GENERATE", ~data=Some({
  "style": styleToString(style),
  "durationMs": totalDuration,
  "outputSize": Blob.size(video)
}), ())
```

## Standard Log Points

### TeaserManager

| Event | Level | Message | Data |
|-------|-------|---------|------|
| Start | `info` | `GENERATE_START` | style, sceneCount |
| Path ready | `info` | `PATH_READY` | steps |
| Scene load | `debug` | `SCENE_LOAD` | sceneName, stepIndex |
| Scene captured | `debug` | `SCENE_CAPTURED` | sceneName, frameCount |
| Complete | `info` | `GENERATE_COMPLETE` | durationMs, outputSize |
| Failed | `error` | `GENERATE_FAILED` | step, error |

### TeaserRecorder

| Event | Level | Message | Data |
|-------|-------|---------|------|
| Recording start | `info` | `RECORDING_START` | dimensions, fps |
| Recording stop | `info` | `RECORDING_STOP` | chunkCount |
| Frame capture | `trace` | `FRAME_CAPTURE` | frameNumber |

## Files to Modify

| File | Changes |
|------|---------|
| `src/systems/TeaserManager.res` | Replace Debug calls with Logger calls |
| `src/systems/TeaserRecorder.res` | Replace Debug calls with Logger calls |

## Testing Checklist

- [ ] Generation start logs style and scene count
- [ ] Path generation logs step count
- [ ] Scene transitions logged at debug level
- [ ] Recording start/stop logged
- [ ] Frame captures visible at trace level
- [ ] Failures log the step where error occurred

## Definition of Done

- Both modules use Logger consistently
- Multi-step workflow fully instrumented
- Performance timing for path generation
- Clear error context for debugging

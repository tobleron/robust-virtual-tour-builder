# Report: Migrate ViewerLoader.res to Logger System

## Objective (Completed)
Update ViewerLoader.res to use the new Logger module with comprehensive logging for scene loading lifecycle.

## Context
ViewerLoader handles the critical path of loading panoramic images into the viewer. Issues here cause blank screens, timeouts, or memory leaks. Proper logging helps diagnose load failures, texture swapping issues, and performance bottlenecks.

## Prerequisites
- Logger.res module exists ✅
- Debug.js updated with perf() method ✅

## Implementation Details

### 1. Replace Debug Imports

The module already uses Debug. We'll switch to Logger for consistency but the underlying system is the same.

### 2. Update Scene Load Start

```rescript
let loadScene = async (scene: scene, options: loadOptions): unit => {
  Logger.startOperation(~module_="Viewer", ~operation="SCENE_LOAD", ~data=Some({
    "sceneName": scene.name,
    "sceneIndex": options.targetIndex,
    "hasPreview": scene.preview->Option.isSome
  }), ())
```

### 3. Update Preview/Master Load Stages

```rescript
// Preview loaded
Logger.debug(~module_="Viewer", ~message="PREVIEW_LOADED", ~data=Some({
  "sceneName": scene.name
}), ())

// Master pre-loaded
Logger.debug(~module_="Viewer", ~message="MASTER_PRELOADED", ~data=Some({
  "sceneName": scene.name
}), ())

// Final texture loaded
Logger.info(~module_="Viewer", ~message="TEXTURE_LOADED", ~data=Some({
  "sceneName": scene.name,
  "quality": "4k"
}), ())
```

### 4. Update Timeout Handling

```rescript
// On timeout
Logger.error(~module_="Viewer", ~message="SCENE_LOAD_TIMEOUT", ~data=Some({
  "sceneName": scene.name,
  "timeoutMs": Constants.sceneLoadTimeout
}), ())
```

### 5. Update Recovery Logic

```rescript
// Scene changed during load
Logger.warn(~module_="Viewer", ~message="LOAD_INTERRUPTED", ~data=Some({
  "originalScene": originalScene.name,
  "currentScene": currentScene.name,
  "action": "triggering recovery"
}), ())
```

### 6. Update Queue Handling

```rescript
// Load queued
Logger.debug(~module_="Viewer", ~message="LOAD_QUEUED", ~data=Some({
  "sceneName": scene.name,
  "queueLength": queue.length
}), ())
```

### 7. Use Logger.timedAsync for Load Operations

```rescript
let loadTexture = async (url: string): result<unit, string> => {
  let {result, durationMs} = await Logger.timedAsync(
    ~module_="Viewer",
    ~operation="TEXTURE_FETCH",
    async () => await fetchTexture(url)
  )
  
  // Performance automatically logged based on duration
  result
}
```

### 8. Update Error Handling

```rescript
| Error(e) => {
    Logger.error(~module_="Viewer", ~message="LOAD_ERROR", ~data=Some({
      "sceneName": scene.name,
      "error": e
    }), ())
    Notification.notify("Failed to load scene", "error")
  }
```

## Standard Log Points

| Event | Level | Message | Data |
|-------|-------|---------|------|
| Load start | `info` | `SCENE_LOAD_START` | sceneName, sceneIndex |
| Preview loaded | `debug` | `PREVIEW_LOADED` | sceneName |
| Master loaded | `debug` | `MASTER_PRELOADED` | sceneName |
| Texture final | `info` | `TEXTURE_LOADED` | sceneName, quality |
| Load complete | `info` | `SCENE_LOAD_COMPLETE` | sceneName, durationMs |
| Timeout | `error` | `SCENE_LOAD_TIMEOUT` | sceneName, timeoutMs |
| Interrupted | `warn` | `LOAD_INTERRUPTED` | originalScene, currentScene |
| Queued | `debug` | `LOAD_QUEUED` | sceneName, queueLength |
| Error | `error` | `LOAD_ERROR` | sceneName, error |

## Files to Modify

| File | Changes |
|------|---------|
| `src/components/ViewerLoader.res` | Replace all Debug calls with Logger calls |

## Testing Checklist

- [ ] Scene load logs start and complete events
- [ ] Timeout after 10s logs error with scene name
- [ ] Fast scene changes log interruption warning
- [ ] Queue system logs when scenes are queued
- [ ] Texture fetch duration is performance-logged
- [ ] Errors include scene context

## Definition of Done

- All Debug calls replaced with Logger calls
- Load lifecycle fully instrumented
- Performance timing for texture fetches
- Clear error context for debugging

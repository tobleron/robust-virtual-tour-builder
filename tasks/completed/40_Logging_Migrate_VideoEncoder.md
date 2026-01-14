# Task: Migrate VideoEncoder.res to Logger System

## Objective
Update VideoEncoder.res to use the new Logger module for tracking FFmpeg encoding operations.

## Context
VideoEncoder handles teaser video encoding using FFmpeg.wasm. This is a complex async operation that can fail in various ways. Logging helps diagnose encoding issues, performance bottlenecks, and FFmpeg errors.

## Prerequisites
- Logger.res module exists ✅

## Implementation Steps

### 1. Update FFmpeg Initialization

```rescript
let initFFmpeg = async (): result<unit, string> => {
  Logger.info(~module_="VideoEncoder", ~message="FFMPEG_INIT_START", ())
  
  // On success
  Logger.info(~module_="VideoEncoder", ~message="FFMPEG_INIT_COMPLETE", ~data=Some({
    "version": ffmpegVersion
  }), ())
  
  // On failure
  Logger.error(~module_="VideoEncoder", ~message="FFMPEG_INIT_FAILED", ~data=Some({
    "error": errorMessage
  }), ())
}
```

### 2. Update Encoding Start

```rescript
let encodeVideo = async (frames: array<blob>): result<blob, string> => {
  Logger.startOperation(~module_="VideoEncoder", ~operation="ENCODE", ~data=Some({
    "frameCount": Belt.Array.length(frames),
    "fps": fps
  }), ())
```

### 3. Update Progress Logging

```rescript
let onProgress = (progress: float): unit => {
  Logger.debug(~module_="VideoEncoder", ~message="ENCODE_PROGRESS", ~data=Some({
    "percent": progress *. 100.0
  }), ())
}
```

### 4. Update Completion

```rescript
Logger.endOperation(~module_="VideoEncoder", ~operation="ENCODE", ~data=Some({
  "outputSize": Blob.size(output),
  "durationMs": encodeDuration
}), ())
```

### 5. Update Error Handling

```rescript
Logger.error(~module_="VideoEncoder", ~message="ENCODE_FAILED", ~data=Some({
  "error": error,
  "frameCount": frameCount
}), ())
```

## Standard Log Points

| Event | Level | Message | Data |
|-------|-------|---------|------|
| FFmpeg init | `info` | `FFMPEG_INIT_*` | version or error |
| Encode start | `info` | `ENCODE_START` | frameCount, fps |
| Progress | `debug` | `ENCODE_PROGRESS` | percent |
| Complete | `info` | `ENCODE_COMPLETE` | outputSize, durationMs |
| Failed | `error` | `ENCODE_FAILED` | error, frameCount |

## Files to Modify

| File | Changes |
|------|---------|
| `src/systems/VideoEncoder.res` | Replace Debug calls with Logger calls |

## Testing Checklist

- [ ] FFmpeg initialization logged
- [ ] Encoding start logs frame count
- [ ] Progress updates in debug mode
- [ ] Completion logs output size
- [ ] Failures log with context

## Definition of Done

- All Debug calls replaced with Logger calls
- FFmpeg lifecycle instrumented
- Performance timing for encoding

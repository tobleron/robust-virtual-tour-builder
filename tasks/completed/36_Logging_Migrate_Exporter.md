# Task: Migrate Exporter.res to Logger System

## Objective
Update Exporter.res to use the new Logger module for comprehensive export process logging.

## Context
Exporter handles the multi-step process of bundling scenes, libraries, and templates into a downloadable ZIP. It involves network requests, binary data handling, and backend communication. Logging helps diagnose which step failed and why.

## Prerequisites
- Logger.res module exists ✅
- Debug.js updated with perf() method ✅

## Implementation Steps

### 1. Update Export Start

```rescript
let exportTour = async (scenes: array<scene>, onProgress: option<progressFn>): unit => {
  Logger.startOperation(~module_="Exporter", ~operation="EXPORT", ~data=Some({
    "sceneCount": Belt.Array.length(scenes),
    "tourName": tourName
  }), ())
```

### 2. Update Phase Logging

```rescript
// Template generation
Logger.debug(~module_="Exporter", ~message="PHASE_TEMPLATES", ())

// Library loading
Logger.debug(~module_="Exporter", ~message="PHASE_LIBRARIES", ())

// Logo loading
Logger.debug(~module_="Exporter", ~message="PHASE_LOGO", ())

// Scene attachment
Logger.debug(~module_="Exporter", ~message="PHASE_SCENES", ~data=Some({
  "count": Belt.Array.length(scenes)
}), ())

// Upload to backend
Logger.info(~module_="Exporter", ~message="UPLOAD_START", ())
```

### 3. Update Library Loading

```rescript
let fetchLib = async filename => {
  let {result, durationMs} = await Logger.timedAsync(
    ~module_="Exporter",
    ~operation=`FETCH_LIB:${filename}`,
    async () => {
      let response = await Fetch.fetch(...)
      await Fetch.blob(response)
    }
  )
  
  result
}
```

### 4. Update Error Handling

```rescript
} catch {
| JsExn(e) => {
    let msg = Option.getOr(JsExn.message(e), "Unknown Error")
    Logger.error(~module_="Exporter", ~message="EXPORT_FAILED", ~data=Some({
      "error": msg,
      "phase": currentPhase
    }), ())
    Notification.notify(`Export Failed: ${msg}`, "error")
  }
}
```

### 5. Update Completion

```rescript
// Success
Logger.endOperation(~module_="Exporter", ~operation="EXPORT", ~data=Some({
  "filename": filename,
  "durationMs": totalDuration
}), ())

// Download triggered
Logger.info(~module_="Exporter", ~message="DOWNLOAD_TRIGGERED", ~data=Some({
  "filename": filename
}), ())
```

### 6. Update XHR Progress (Optional Enhancement)

In the raw XHR function, we can add logging callbacks:

```javascript
xhr.upload.onprogress = (e) => {
    // Existing progress handling
    // Could add: onLog("UPLOAD_PROGRESS", { percent, bytesUploaded })
};
```

## Standard Log Points

| Event | Level | Message | Data |
|-------|-------|---------|------|
| Start | `info` | `EXPORT_START` | sceneCount, tourName |
| Phase | `debug` | `PHASE_*` | phase-specific data |
| Fetch lib | `debug/perf` | `FETCH_LIB` | filename, durationMs |
| Upload start | `info` | `UPLOAD_START` | - |
| Upload progress | `debug` | `UPLOAD_PROGRESS` | percent, bytesUploaded |
| Server processing | `info` | `SERVER_PROCESSING` | - |
| Complete | `info` | `EXPORT_COMPLETE` | filename, durationMs |
| Failed | `error` | `EXPORT_FAILED` | error, phase |
| Download | `info` | `DOWNLOAD_TRIGGERED` | filename |

## Files to Modify

| File | Changes |
|------|---------|
| `src/systems/Exporter.res` | Replace Debug calls with Logger calls |

## Testing Checklist

- [ ] Export start logs scene count and tour name
- [ ] Each phase is logged in sequence
- [ ] Library fetch logs file and duration
- [ ] Upload start is logged
- [ ] Completion logs filename and total duration
- [ ] Failures log the phase where error occurred
- [ ] Download trigger is logged

## Definition of Done

- All Debug calls replaced with Logger calls
- Multi-phase process fully instrumented
- Performance timing for network operations
- Clear error context including failed phase

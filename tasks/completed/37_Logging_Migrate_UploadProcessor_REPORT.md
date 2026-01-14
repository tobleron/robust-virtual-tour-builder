# Report: Migrate UploadProcessor.res to Logger System

## Objective (Completed)
Update UploadProcessor.res to use the new Logger module for tracking image upload and processing flow.

## Context
UploadProcessor handles the initial image intake: file validation, EXIF parsing, quality analysis, and resize requests. Issues here cause failed uploads, wrong orientations, or quality problems. Detailed logging helps diagnose the full pipeline.

## Prerequisites
- Logger.res module exists ✅
- Debug.js updated with perf() method ✅

## Implementation Details

### 1. Update Batch Start

```rescript
let processUploadBatch = async (files: array<File.t>): unit => {
  Logger.startOperation(~module_="Upload", ~operation="BATCH", ~data=Some({
    "fileCount": Belt.Array.length(files),
    "totalSize": calculateTotalSize(files)
  }), ())
```

### 2. Update Per-File Processing

```rescript
let processFile = async (file: File.t, index: int): result<scene, string> => {
  Logger.debug(~module_="Upload", ~message="FILE_START", ~data=Some({
    "filename": File.name(file),
    "index": index,
    "size": File.size(file)
  }), ())
  
  // ... processing
}
```

### 3. Update EXIF Parsing

```rescript
let parseExif = async (file: File.t): option<exifData> => {
  let {result, durationMs} = await Logger.timedAsync(
    ~module_="Upload",
    ~operation="EXIF_PARSE",
    async () => await ExifParser.parse(file)
  )
  
  switch result {
  | Some(exif) => 
      Logger.debug(~module_="Upload", ~message="EXIF_SUCCESS", ~data=Some({
        "hasGps": exif.gps->Option.isSome,
        "orientation": exif.orientation
      }), ())
  | None => 
      Logger.debug(~module_="Upload", ~message="EXIF_NONE", ())
  }
  
  result
}
```

### 4. Update Quality Analysis

```rescript
Logger.debug(~module_="Upload", ~message="QUALITY_ANALYSIS", ~data=Some({
  "brightness": qualityStats.brightness,
  "contrast": qualityStats.contrast,
  "sharpness": qualityStats.sharpness
}), ())

// Quality warning
if qualityStats.brightness < 0.2 {
  Logger.warn(~module_="Upload", ~message="LOW_BRIGHTNESS", ~data=Some({
    "filename": file.name,
    "brightness": qualityStats.brightness
  }), ())
}
```

### 5. Update Backend Resize Call

```rescript
let resizeImage = async (file: File.t): result<blob, string> => {
  let {result, durationMs} = await Logger.timedAsync(
    ~module_="Upload",
    ~operation="BACKEND_RESIZE",
    async () => await Backend.resize(file)
  )
  
  switch result {
  | Ok(blob) => 
      Logger.debug(~module_="Upload", ~message="RESIZE_SUCCESS", ~data=Some({
        "originalSize": File.size(file),
        "resizedSize": Blob.size(blob),
        "durationMs": durationMs
      }), ())
  | Error(err) => 
      Logger.error(~module_="Upload", ~message="RESIZE_FAILED", ~data=Some({
        "filename": File.name(file),
        "error": err
      }), ())
  }
  
  result
}
```

### 6. Update Batch Completion

```rescript
// All files processed
Logger.endOperation(~module_="Upload", ~operation="BATCH", ~data=Some({
  "successful": successCount,
  "failed": failedCount,
  "totalDurationMs": totalDuration
}), ())

// Individual failure
Logger.error(~module_="Upload", ~message="FILE_FAILED", ~data=Some({
  "filename": File.name(file),
  "error": errorMessage
}), ())
```

## Standard Log Points

| Event | Level | Message | Data |
|-------|-------|---------|------|
| Batch start | `info` | `BATCH_START` | fileCount, totalSize |
| File start | `debug` | `FILE_START` | filename, index, size |
| EXIF parse | `debug/perf` | `EXIF_PARSE` | durationMs |
| EXIF result | `debug` | `EXIF_SUCCESS/NONE` | hasGps, orientation |
| Quality | `debug` | `QUALITY_ANALYSIS` | brightness, contrast, sharpness |
| Quality warn | `warn` | `LOW_*` | filename, value |
| Resize | `debug/perf` | `BACKEND_RESIZE` | durationMs |
| Resize result | `debug` | `RESIZE_SUCCESS` | sizes |
| Resize fail | `error` | `RESIZE_FAILED` | filename, error |
| File complete | `debug` | `FILE_COMPLETE` | filename |
| File failed | `error` | `FILE_FAILED` | filename, error |
| Batch complete | `info` | `BATCH_COMPLETE` | successful, failed, durationMs |

## Files to Modify

| File | Changes |
|------|---------|
| `src/systems/UploadProcessor.res` | Replace Debug calls with Logger calls |

## Testing Checklist

- [ ] Batch upload logs start with file count
- [ ] Each file logs start processing
- [ ] EXIF parsing logs result
- [ ] Quality issues log warnings
- [ ] Backend resize logs duration
- [ ] Resize failures log with error detail
- [ ] Batch completion logs success/fail counts

## Definition of Done

- All Debug calls replaced with Logger calls
- Full upload pipeline instrumented
- Performance timing for EXIF and resize
- Quality warnings logged appropriately
- Clear error context for failed uploads

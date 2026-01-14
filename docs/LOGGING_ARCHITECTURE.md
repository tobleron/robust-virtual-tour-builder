# Logging & Debugging Architecture

> A systematic hybrid design for observability, debugging, and performance monitoring in a purely functional ReScript application with a Rust backend.

---

## Table of Contents

1. [Philosophy](#1-philosophy)
2. [Hybrid Architecture](#2-hybrid-architecture)
3. [Log Levels & Semantics](#3-log-levels--semantics)
4. [Frontend (ReScript) Responsibilities](#4-frontend-rescript-responsibilities)
5. [Backend (Rust) Responsibilities](#5-backend-rust-responsibilities)
6. [Data Flow](#6-data-flow)
7. [ReScript Logger Module](#7-rescript-logger-module)
8. [Rust Logging Endpoints](#8-rust-logging-endpoints)
9. [Performance Monitoring](#9-performance-monitoring)
10. [Error Handling Patterns](#10-error-handling-patterns)
11. [Debug Modes & Runtime Control](#11-debug-modes--runtime-control)
12. [Log File Structure](#12-log-file-structure)
13. [Module Migration Guide](#13-module-migration-guide)

---

## 1. Philosophy

### The Functional Debugging Advantage

Pure functional programming gives us a **significant debugging advantage**: every function is a pure transformation from input to output. This means:

- **State is explicit**: We always know what data flows in and out.
- **No hidden mutations**: Side effects are isolated and trackable.
- **Reproducibility**: Logs can capture full context to replay errors.

### Design Principles

| Principle | Description |
|-----------|-------------|
| **Hybrid Approach** | Frontend catches and enriches; Backend persists and processes. |
| **Zero-Cost Abstraction** | Debug logging has minimal impact in production. |
| **Structured Data** | All logs are JSON objects, not strings. |
| **Automatic Context** | Every log entry includes module, timestamp, and environment. |
| **Critical Always Visible** | Errors are always logged, regardless of level. |
| **Opt-In Verbosity** | Debug/trace logs only appear when level is lowered. |

---

## 2. Hybrid Architecture

### Why Hybrid?

| Aspect | Frontend (ReScript) | Backend (Rust) |
|--------|---------------------|----------------|
| **User Feedback** | ✅ Immediate | ⚠️ Requires round-trip |
| **Persistence** | ⚠️ Browser can close | ✅ Writes to disk |
| **Reliability** | ⚠️ JS errors can break logging | ✅ Rust is very stable |
| **Context** | ✅ Has UI state, user actions | ⚠️ Only sees request data |
| **Offline** | ✅ Can buffer and retry | ❌ Requires connection |
| **Type Safety** | ✅ ReScript's Result type | ✅ Rust's Result type |

### Responsibility Split

| Error Type | Primary Handler | Reason |
|------------|-----------------|--------|
| Navigation failed | **Frontend** | Has scene/hotspot context |
| Image resize failed | **Backend** | Rust process owns this |
| Viewer load timeout | **Frontend** | Has viewer state |
| ZIP creation failed | **Backend** | Rust owns file I/O |
| Hotspot click error | **Frontend** | Immediate UI context |
| WebGL crash | **Frontend** | Needs GPU info |
| EXIF parsing failed | **Backend** | Image processing context |

---

## 3. Log Levels & Semantics

### Standard Levels (Priority Order)

| Level | Code | When to Use | Console | Backend |
|-------|------|-------------|---------|---------|
| `trace` | 0 | Frame-by-frame, animation ticks | Gray | No |
| `debug` | 1 | Step-by-step function flow | Blue | Conditional |
| `info` | 2 | Major lifecycle events | Green | Yes |
| `warn` | 3 | Soft failures, unexpected states | Yellow | Yes |
| `error` | 4 | Critical failures | Red | **Always** |
| `perf` | 2 | Performance-specific logs | Cyan | Yes |

### Level Behavior

```
DEBUG_LOG_LEVEL = 'info' (default)
├── trace: Hidden in console, not sent to backend
├── debug: Hidden in console, not sent to backend
├── info:  Shown in console, sent to backend
├── warn:  Shown in console, sent to backend
├── error: Shown in console, ALWAYS sent to backend + error.log
└── perf:  Shown in console, sent to backend (as 'info')
```

---

## 4. Frontend (ReScript) Responsibilities

### First Line of Defense

The frontend is responsible for:

1. **Catching errors where they occur**
   - UI interactions, navigation, viewer events
   - Immediate context (scene ID, hotspot, user action)

2. **User feedback**
   - Toast notifications for user-visible errors
   - Progress updates for long operations

3. **Context enrichment**
   - Screen size, user agent, URL
   - Current scene, navigation state
   - Memory usage (if available)

4. **Buffering**
   - Ring buffer of 500 entries in memory
   - Available for export/download

5. **Forwarding to backend**
   - POST to `/log-telemetry` for all logs at threshold
   - POST to `/log-error` for critical errors (redundant safety)

### Frontend Modules to Instrument

| Module | Key Log Points |
|--------|----------------|
| `Navigation.res` | NAV_START, NAV_COMPLETE, NAV_FAILED |
| `HotspotManager.res` | HOTSPOT_CLICK, LINK_CREATE, LINK_DELETE |
| `ViewerLoader.res` | SCENE_LOAD_START, SCENE_LOAD_COMPLETE, TIMEOUT |
| `SimulationSystem.res` | SIM_START, SIM_STEP, SIM_COMPLETE |
| `Exporter.res` | EXPORT_START, EXPORT_PROGRESS, EXPORT_COMPLETE |
| `Store.res` | STATE_CHANGE (debug level only) |

---

## 5. Backend (Rust) Responsibilities

### Persistent Storage & Processing

The backend is responsible for:

1. **Receiving telemetry**
   - `POST /log-telemetry` - All frontend logs
   - `POST /log-error` - Critical errors (dedicated endpoint)

2. **Persistent storage**
   - Write to `logs/telemetry.log` (JSON lines)
   - Write to `logs/error.log` (plaintext, critical only)
   - Console output in dev mode

3. **Backend-specific errors**
   - Image processing failures
   - ZIP creation errors
   - File I/O issues
   - These are logged directly by Rust AND returned to frontend

4. **Future: Log processing**
   - Log rotation
   - Compression/archiving
   - Analytics aggregation

### Backend Modules to Instrument

| Handler | Key Log Points |
|---------|----------------|
| `resize_handler` | RESIZE_START, RESIZE_COMPLETE, RESIZE_FAILED |
| `create_tour_package` | EXPORT_RECEIVED, PROCESSING, COMPLETE, FAILED |
| `load_project` | PROJECT_LOAD, SESSION_CREATE |
| `health_check` | HEALTH_CHECK (trace level) |

---

## 6. Data Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           FRONTEND (ReScript)                                │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐            │
│  │ Navigation  │ │   Viewer    │ │   Hotspot   │ │   Export    │  ...       │
│  │    .res     │ │    .res     │ │    .res     │ │    .res     │            │
│  └──────┬──────┘ └──────┬──────┘ └──────┬──────┘ └──────┬──────┘            │
│         │               │               │               │                    │
│         └───────────────┴───────┬───────┴───────────────┘                    │
│                                 ▼                                            │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │                         Logger.res + Debug.js                           │ │
│  │  ┌──────────────────────────────────────────────────────────────────┐  │ │
│  │  │  1. Create structured entry (timestamp, module, level, data)     │  │ │
│  │  │  2. Add to ring buffer (500 entries)                             │  │ │
│  │  │  3. Show in console (if level >= threshold)                      │  │ │
│  │  │  4. Show toast to user (if error)                                │  │ │
│  │  │  5. POST to backend (if level >= threshold OR error)             │  │ │
│  │  └──────────────────────────────────────────────────────────────────┘  │ │
│  └───────────────────────────────┬─────────────────────────────────────────┘ │
│                                  │                                           │
└──────────────────────────────────┼───────────────────────────────────────────┘
                                   │
                    ┌──────────────┴──────────────┐
                    │      HTTP POST Requests     │
                    ├──────────────┬──────────────┤
                    ▼              ▼              
         POST /log-telemetry   POST /log-error   
                    │              │              
                    └──────┬───────┘              
                           ▼                      
┌──────────────────────────────────────────────────────────────────────────────┐
│                           BACKEND (Rust)                                      │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │                        Logging Handlers                                  │ │
│  │  ┌────────────────────────────────────────────────────────────────────┐ │ │
│  │  │  1. Parse JSON entry                                               │ │ │
│  │  │  2. Add server timestamp                                           │ │ │
│  │  │  3. Append to appropriate log file                                 │ │ │
│  │  │  4. Print to console (dev mode)                                    │ │ │
│  │  └────────────────────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
│                                  │                                           │
│            ┌─────────────────────┼─────────────────────┐                     │
│            ▼                     ▼                     ▼                     │
│   logs/telemetry.log     logs/error.log          Console                    │
│   (JSON lines)           (plaintext)             (dev mode)                  │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 7. ReScript Logger Module

### Location: `src/utils/Logger.res`

### API Reference

```rescript
// Log levels
type level = Trace | Debug | Info | Warn | Error | Perf

// Basic logging
Logger.trace(~module_="Module", ~message="msg", ~data=Some({...}), ())
Logger.debug(~module_="Module", ~message="msg", ~data=Some({...}), ())
Logger.info(~module_="Module", ~message="msg", ~data=Some({...}), ())
Logger.warn(~module_="Module", ~message="msg", ~data=Some({...}), ())
Logger.error(~module_="Module", ~message="msg", ~data=Some({...}), ())

// Performance timing
let {result, durationMs} = Logger.timed(~module_="M", ~operation="OP", fn)
let {result, durationMs} = await Logger.timedAsync(~module_="M", ~operation="OP", asyncFn)

// Error handling with auto-logging
let result = Logger.attempt(~module_="M", ~operation="OP", fn)
let result = await Logger.attemptAsync(~module_="M", ~operation="OP", asyncFn)

// Utilities
Logger.startOperation(~module_="M", ~operation="OP", ())
Logger.endOperation(~module_="M", ~operation="OP", ())
Logger.initialized(~module_="ModuleName")
Logger.setLevel(Logger.Debug)
```

---

## 8. Rust Logging Endpoints

### POST /log-telemetry

Receives all frontend logs at or above threshold.

```rust
#[derive(Deserialize)]
struct TelemetryEntry {
    level: String,
    module: String,
    message: String,
    data: Option<serde_json::Value>,
    timestamp: String,
}

async fn log_telemetry(Json(entry): Json<TelemetryEntry>) -> impl IntoResponse {
    let line = serde_json::to_string(&entry).unwrap() + "\n";
    append_to_file("logs/telemetry.log", &line).await;
    StatusCode::OK
}
```

### POST /log-error

Receives critical errors (redundant endpoint for reliability).

```rust
async fn log_error(Json(entry): Json<TelemetryEntry>) -> impl IntoResponse {
    let line = format!("[{}] [{}] {} - {:?}\n", 
        entry.timestamp, entry.module, entry.message, entry.data);
    append_to_file("logs/error.log", &line).await;
    
    // Also log to telemetry for completeness
    let json_line = serde_json::to_string(&entry).unwrap() + "\n";
    append_to_file("logs/telemetry.log", &json_line).await;
    
    StatusCode::OK
}
```

### Backend Internal Logging

For Rust-side errors, use `tracing`:

```rust
use tracing::{info, warn, error};

info!(module = "Resizer", "RESIZE_START");
error!(module = "Resizer", error = %e, "RESIZE_FAILED");
```

---

## 9. Performance Monitoring

### Automatic Thresholds

| Duration | Level | Emoji | Interpretation |
|----------|-------|-------|----------------|
| > 500ms | `warn` | 🐢 | Very slow, investigate |
| > 100ms | `info` | ⏱️ | Slow, worth noting |
| < 100ms | `debug` | ⚡ | Fast, only in debug mode |

### ReScript Usage

```rescript
// Synchronous
let {result, _} = Logger.timed(~module_="Export", ~operation="COMPRESS", () => {
  compress(data)
})

// Async
let {result, _} = await Logger.timedAsync(~module_="Loader", ~operation="FETCH", async () => {
  await fetchData()
})
```

### JavaScript Usage

```javascript
const start = performance.now();
await doWork();
const duration = performance.now() - start;
Debug.perf('Module', 'OPERATION', duration, { extra: 'data' });
```

---

## 10. Error Handling Patterns

### Pattern 1: Auto-Logged Errors (Preferred)

```rescript
let result = Logger.attempt(~module_="Config", ~operation="PARSE", () => {
  parseJson(raw)
})

switch result {
| Ok(data) => use(data)
| Error(_) => showUserError("Parse failed") // Already logged!
}
```

### Pattern 2: Manual Error Logging

```rescript
try {
  riskyOperation()
} catch {
| JsExn(e) => {
    let msg = e->JsExn.message->Option.getOr("Unknown")
    Logger.error(~module_="Module", ~message="OPERATION_FAILED", ~data=Some({"error": msg}), ())
    Notification.notify(msg, "error")
  }
}
```

### Pattern 3: Backend Error Propagation

```rust
// Rust handler
async fn resize_image(...) -> Result<Json<Response>, ApiError> {
    match process_image(&data).await {
        Ok(result) => Ok(Json(Response { success: true, data: result })),
        Err(e) => {
            error!(module = "Resizer", error = %e, "RESIZE_FAILED");
            Err(ApiError::ProcessingFailed(e.to_string()))
        }
    }
}
```

```rescript
// Frontend handling
let response = await Backend.resizeImage(file)
switch response {
| Ok(data) => updateScene(data)
| Error(msg) => {
    // Backend already logged, we just show user message
    Logger.warn(~module_="Upload", ~message="Backend resize failed", ~data=Some({"error": msg}), ())
    Notification.notify("Image processing failed", "error")
  }
}
```

---

## 11. Debug Modes & Runtime Control

### Global Configuration (`src/constants.js`)

```javascript
export const DEBUG_ENABLED_DEFAULT = false;  // Console output?
export const DEBUG_LOG_LEVEL = 'info';       // Minimum level
export const DEBUG_MAX_ENTRIES = 500;        // Ring buffer size
export const PERF_WARN_THRESHOLD = 500;      // ms - warn if slower
export const PERF_INFO_THRESHOLD = 100;      // ms - info if slower
```

### Runtime Console Commands

```javascript
DEBUG.enable()                  // Turn on console output
DEBUG.disable()                 // Turn off console output
DEBUG.setLevel('trace')         // Maximum verbosity
DEBUG.setLevel('debug')         // Development detail
DEBUG.setLevel('info')          // Default
DEBUG.enableModule('Navigation')// Filter to one module
DEBUG.getLog()                  // Get all entries
DEBUG.getLogByModule('Viewer')  // Get entries for module
DEBUG.downloadLog()             // Save as JSON file
DEBUG.getSummary()              // Count by module
```

### Keyboard Shortcut (Dev Only)

**Ctrl+Shift+D** — Toggle debug mode on/off

---

## 12. Log File Structure

### Log Files

| File | Purpose | Format | Written By |
|------|---------|--------|------------|
| `logs/telemetry.log` | All telemetry | JSON lines | Backend |
| `logs/error.log` | Critical errors | Plaintext | Backend |
| `logs/backend.log` | Rust internal | Plaintext | Rust tracing |

### Telemetry Log Format (JSON Lines)

```json
{"timestamp":"2026-01-14T09:00:00.000Z","module":"Navigation","level":"info","message":"NAV_COMPLETE","data":{"sceneId":"scene_1","durationMs":245}}
{"timestamp":"2026-01-14T09:00:00.500Z","module":"Viewer","level":"perf","message":"⏱️ RENDER (120.50ms)","data":{"durationMs":120.5,"threshold":"SLOW"}}
{"timestamp":"2026-01-14T09:00:01.000Z","module":"Hotspot","level":"warn","message":"DUPLICATE_LINK","data":{"from":"scene_1","to":"scene_2"}}
```

### Error Log Format (Plaintext)

```
[2026-01-14T09:00:00.000Z] [Navigation] SCENE_LOAD_FAILED - {"sceneId":"scene_3","error":"Network timeout"}
[2026-01-14T09:00:05.123Z] [Exporter] ZIP_GENERATION_FAILED - {"step":"compression","error":"Out of memory"}
```

---

## 13. Module Migration Guide

### Standard Log Points Per Module

Every module should have these log points:

| Event | Level | Message Pattern | When |
|-------|-------|-----------------|------|
| Initialization | `info` | `{Module} initialized` | Module starts |
| Major Action Start | `info` | `{ACTION}_START` | Before async work |
| Major Action Complete | `info` | `{ACTION}_COMPLETE` | After success |
| Error | `error` | `{ACTION}_FAILED` | On failure |
| Warning | `warn` | `{ISSUE}` | Unexpected but handled |
| Debug Step | `debug` | `{step description}` | Each logical step |
| Trace | `trace` | `{detail}` | Frame/tick level |

### Migration Checklist Per Module

- [ ] Replace `Console.log` with `Logger.debug`
- [ ] Replace `Console.error` with `Logger.error`
- [ ] Add `Logger.initialized` at module init
- [ ] Add `startOperation`/`endOperation` for major actions
- [ ] Wrap risky operations with `Logger.attempt`
- [ ] Use `Logger.timed` for performance-critical sections
- [ ] Ensure errors trigger user notifications

---

## Implementation Checklist

### Phase 1: Core Infrastructure
- [x] Create `src/utils/Logger.res` module
- [x] Update `src/utils/Debug.js` with `perf()` method
- [x] Add performance thresholds to `src/constants.js`
- [ ] Add `POST /log-telemetry` endpoint to Rust backend
- [ ] Add `POST /log-error` endpoint to Rust backend
- [ ] Add Rust internal logging with `tracing`

### Phase 2: Frontend Migration
- [ ] Migrate `Navigation.res` to use Logger
- [ ] Migrate `HotspotManager.res` to use Logger
- [ ] Migrate `ViewerLoader.res` to use Logger
- [ ] Migrate `SimulationSystem.res` to use Logger
- [ ] Migrate `Exporter.res` to use Logger
- [ ] Migrate `UploadProcessor.res` to use Logger
- [ ] Migrate `Store.res` to use Logger

### Phase 3: Backend Integration
- [ ] Add logging to `resize_handler`
- [ ] Add logging to `create_tour_package`
- [ ] Add logging to `load_project`
- [ ] Implement log rotation (optional)

### Phase 4: Polish
- [ ] Add keyboard shortcut for debug toggle
- [ ] Update all remaining modules
- [ ] Performance testing and optimization
- [ ] Documentation review

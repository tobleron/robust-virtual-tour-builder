# Project-Specific Implementation Guide

**Version**: 1.0  
**Last Updated**: 2026-02-04  
**Status**: Active

---

## Overview

This document details how the **Robust Virtual Tour Builder** implements the general architectural patterns defined in `/docs/architecture/`. This serves as a bridge between theory and practice.

---

## 1. System Robustness Implementation

### Circuit Breaker (Backend API)

**Location**: `src/utils/CircuitBreaker.res`

**Configuration**:
```rescript
let defaultConfig = {
  failureThreshold: 5,      // Open after 5 failures
  resetTimeoutMs: 60000,    // Try recovery after 60s
  halfOpenRequests: 3       // Test with 3 requests
}
```

**Usage**:
```rescript
// Wrap API calls
let fetchWithCircuitBreaker = (url) => {
  CircuitBreaker.execute(
    ~fn=() => Fetch.fetch(url),
    ~config=defaultConfig,
    ()
  )
}
```

**Monitoring**: Circuit breaker state changes are logged via `Logger.info` with `CIRCUIT_BREAKER_STATE_CHANGE` message.

---

### Retry with Backoff

**Location**: `src/utils/Retry.res`

**Configuration**:
```rescript
let defaultRetryConfig = {
  maxRetries: 3,
  initialDelayMs: 1000,
  maxDelayMs: 30000,
  backoffMultiplier: 2.0,
  jitter: true
}
```

**Integration**: Used in `src/systems/Api/AuthenticatedClient.res` for all backend requests.

**Retryable Errors**:
- Network errors (`NetworkError`, `fetch failed`)
- Server errors (500, 502, 503, 504)

**Non-Retryable Errors**:
- Client errors (400, 401, 403, 404)
- Validation errors

---

### Request Debouncing

**Location**: `src/utils/Debounce.res`

**Use Cases**:
1. **Project Name Input** (`src/components/Sidebar/SidebarProjectInfo.res`)
   - Delay: 300ms
   - Prevents excessive state updates during typing

2. **Auto-Save** (`src/systems/ProjectManager.res`)
   - Delay: 2000ms
   - Batches rapid state changes into single save

---

### Interaction Queue

**Location**: `src/core/InteractionQueue.res`

**Purpose**: Serializes critical state transitions to prevent race conditions.

**Queued Actions**:
- Scene switching (`SwitchToScene`)
- Project loading (`LoadProject`)
- Navigation transitions (`StartNavigation`, `CompleteNavigation`)
- Save/Export operations

**Implementation**:
```rescript
// Enqueue action
InteractionQueue.enqueue(dispatch, SwitchToScene(sceneId))

// Barrier actions (block queue until complete)
InteractionQueue.enqueueBarrier(dispatch, LoadProject(data))
```

**UI Integration**: `src/hooks/UseIsInteractionPermitted.res` disables buttons while queue is processing.

---

### Optimistic Updates

**Location**: `src/core/OptimisticAction.res`

**State Snapshots**: `src/core/StateSnapshot.res`

**Use Cases**:
1. **Scene Renaming**
   - Optimistic: Update UI immediately
   - Server: POST to `/api/project/rename-scene`
   - Rollback: Restore previous name on failure

2. **Hotspot Creation**
   - Optimistic: Add hotspot to state
   - Server: Validate and persist
   - Rollback: Remove hotspot on failure

**Example**:
```rescript
OptimisticAction.execute(
  ~optimisticUpdate=() => dispatch(RenameScene(id, newName)),
  ~serverAction=() => Api.renameScene(id, newName),
  ~rollback=() => dispatch(RenameScene(id, oldName)),
  ()
)
```

---

### Rate Limiting

**Location**: `src/utils/RateLimiter.res`

**Configuration**:
```rescript
// User actions: 30 per minute
let userActionLimiter = RateLimiter.make(~limit=30, ~windowMs=60000)

// API requests: 100 per minute
let apiLimiter = RateLimiter.make(~limit=100, ~windowMs=60000)
```

**Integration**: Applied in `src/systems/EventBus.res` for user-initiated events.

---

## 2. JSON Encoding Implementation

### Validation Library

**Choice**: `rescript-json-combinators` (CSP-compliant)

**Rationale**: 
- No `eval()` usage (unlike `rescript-schema`)
- Functional composition
- Explicit error handling

### Decoder Registry

**Location**: `src/core/JsonParsers.res`

**Key Decoders**:
```rescript
// Scene decoder
let sceneDecoder = {
  open JsonCombinators.Json.Decode
  object(field => {
    id: field.required("id", string),
    name: field.required("name", string),
    imageUrl: field.required("imageUrl", string),
    hotspots: field.required("hotspots", array(hotspotDecoder))
  })
}

// Project decoder
let projectDecoder = {
  open JsonCombinators.Json.Decode
  object(field => {
    tourName: field.required("tourName", string),
    scenes: field.required("scenes", array(sceneDecoder)),
    version: field.required("version", string)
  })
}
```

### Encoder Registry

**Location**: `src/core/JsonEncoders.res`

**Key Encoders**:
```rescript
let sceneEncoder = scene => {
  open JsonCombinators.Json.Encode
  object([
    ("id", string(scene.id)),
    ("name", string(scene.name)),
    ("imageUrl", string(scene.imageUrl)),
    ("hotspots", array(hotspotEncoder, scene.hotspots))
  ])
}
```

### Validation Points

1. **API Responses** (`src/systems/Api/*.res`)
   - All backend responses validated before state update
   
2. **File Imports** (`src/systems/ProjectManager.res`)
   - ZIP contents validated before loading
   
3. **LocalStorage** (`src/utils/SessionStore.res`)
   - Cached state validated on restore

---

## 3. Logging & Telemetry

### Logger Module

**Location**: `src/utils/Logger.res`

**Facade Pattern**: Delegates to specialized modules:
- `LoggerConsole.res` - Browser console output
- `LoggerTelemetry.res` - Backend batching
- `LoggerLogic.res` - Threshold logic

### Telemetry Batching

**Configuration**:
```rescript
let telemetryConfig = {
  batchSize: 50,           // Flush after 50 entries
  batchIntervalMs: 5000,   // Flush every 5 seconds
  useSendBeacon: true      // Use sendBeacon for reliability
}
```

**Priority Levels**:
- **Critical/High**: Sent immediately
- **Medium**: Batched (default)
- **Low**: Console only (unless Diagnostic Mode enabled)

### Diagnostic Mode

**Toggle**: About dialog → Enable Diagnostic Mode

**Effect**: 
- All logs (including Trace/Debug) sent to backend
- Bypasses batching for real-time streaming
- Viewable via `./scripts/tail-diagnostics.sh`

---

## 4. State Management

### Architecture

**Pattern**: Elm/Redux-inspired unidirectional data flow

**Core Files**:
- `src/core/State.res` - State definition
- `src/core/Actions.res` - Action types
- `src/core/Reducer.res` - State transitions
- `src/core/AppContext.res` - React Context provider

### State Persistence

**Session Storage** (`src/utils/SessionStore.res`):
- Saves state on every update
- Restores on page reload
- Cleared on "New Project"

**Backend Persistence** (`src/systems/ProjectManager.res`):
- Manual save via "Save" button
- Auto-save (debounced 2s)
- Export to ZIP

### Immutability

**Rule**: No `mutable` fields in domain records

**Pattern**:
```rescript
// ❌ BAD
type state = { mutable count: int }
state.count = state.count + 1

// ✅ GOOD
type state = { count: int }
let newState = {...state, count: state.count + 1}
```

---

## 5. Error Handling

### Result Type

**Usage**: All fallible operations return `result<'a, string>`

```rescript
let loadProject = (file: File.t): result<project, string> => {
  switch parseProjectFile(file) {
  | Ok(data) => Ok(data)
  | Error(msg) => Error(`Failed to load project: ${msg}`)
  }
}
```

### Error Boundaries

**Location**: `src/components/AppErrorBoundary.res`

**Fallback**: `src/components/ErrorFallbackUI.res`

**Behavior**:
- Catches React render errors
- Displays user-friendly message
- Logs full error to backend
- Provides "Reload" button

---

## 6. Testing Strategy

### Three-Tier Approach

1. **Unit Tests** (`tests/unit/*_v.test.res`)
   - Pure functions
   - Math utilities
   - Data transformers

2. **Smoke Tests** (`tests/unit/*_v.test.res`)
   - Component rendering
   - Context providers
   - Modal systems

3. **Regression Tests** (`tests/unit/*_v.test.res`)
   - Historical bug fixes
   - Edge cases

### E2E Tests

**Location**: `tests/e2e/*.spec.ts`

**Framework**: Playwright

**Coverage**:
- Full editor workflow
- Image upload
- Scene navigation
- Project save/load

---

## 7. Performance Optimizations

### Memoization

**React.memo**: Applied to high-frequency components
- `ViewerHUD.res`
- `SceneItem.res`
- `HotspotLayer.res`

### Lazy Loading

**Dynamic Imports**: Heavy modules loaded on demand
- Teaser system
- Export system
- EXIF report generator

### Render Throttling

**Simulation Mode**: Reduced to 20fps during autopilot to minimize CPU usage

---

## 8. Security Measures

### Content Security Policy

**Location**: `index.html`

**Key Directives**:
- `script-src 'self' blob:` - No inline scripts
- `style-src 'self' 'unsafe-inline'` - CSS allowed (necessary for dynamic styles)
- `img-src 'self' blob: data:` - Local images only

### Input Sanitization

**Backend** (`backend/src/api/utils.rs`):
```rust
fn sanitize_filename(name: &str) -> String {
    name.replace(['/', '\\', '\0'], "_")
}
```

**Frontend** (`src/utils/TourLogic.res`):
```rescript
let sanitizeName = (name: string): string => {
  name
  ->String.trim
  ->replaceControlChars
  ->collapseWhitespace
  ->removeLeadingTrailingUnderscores
}
```

---

## 9. Deployment

### Build Process

```bash
# Frontend
npm run build

# Backend
cd backend && cargo build --release
```

### Environment Variables

**Development** (`.env.development`):
```
BACKEND_URL=http://localhost:8080
LOG_LEVEL=debug
```

**Production** (`.env.production`):
```
BACKEND_URL=https://api.example.com
LOG_LEVEL=info
```

---

## 10. Monitoring & Observability

### Metrics

**Backend** (`backend/src/metrics.rs`):
- Prometheus endpoint: `/metrics`
- Request duration histograms
- Error rate counters

**Frontend** (`src/utils/LoggerTelemetry.res`):
- Batch telemetry: `/telemetry/batch`
- Performance marks
- Error tracking

### Log Aggregation

**Script**: `./scripts/tail-diagnostics.sh`

**Output**: Color-coded, real-time log stream from `logs/diagnostic.log`

---

## References

- [General Architecture Patterns](/docs/architecture/)
- [Project Specifications](/docs/PROJECT_SPECS.md)
- [Testing Standards](/.agent/workflows/testing-standards.md)
- [ReScript Standards](/.agent/workflows/rescript-standards.md)
- [Rust Standards](/.agent/workflows/rust-standards.md)

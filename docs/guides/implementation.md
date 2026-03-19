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
- **Location**: `src/utils/CircuitBreaker.res`
- **Use**: Open after 5 failures, 60s reset, half-open config (3 requests).
- **Monitoring**: State changes are logged via `Logger.info("CIRCUIT_BREAKER_STATE_CHANGE")`.

### Retry with Backoff
- **Location**: `src/utils/Retry.res`
- **Use**: Used in `src/systems/Api/AuthenticatedClient.res`. Retries on 500-level and network errors. Do not retry 400-level limits.

### Request Debouncing
- **Location**: `src/utils/Debounce.res`
- **Use**: Delaying typing inputs in `SidebarProjectInfo.res` and auto-save (2000ms delay) in `ProjectManager.res`.

### Interaction Queue
- **Location**: `src/core/InteractionQueue.res`
- **Use**: Prevents race conditions. Queues UI transitions, nav routing, saving/export limits.
- **UI Locking**: `useIsInteractionPermitted` disables clicks while queue drains.

### Optimistic Updates
- **Location**: `src/core/OptimisticAction.res`
- **Use**: State mutations (e.g., Hotspots, Rename Scene) instantly update UI, but fallback via rollbacks if the network fails.

### Rate Limiting
- **Location**: `src/utils/RateLimiter.res`
- **Use**: Applied in `EventBus.res` to govern user clicks (30 per min) and API requests (100 per min).

---

## 2. JSON Encoding Implementation

### Validation Library
**Choice**: `rescript-json-combinators` (CSP-compliant, no `eval()`). Used universally for backend endpoints and filesystem load/save.

### Decoding/Encoding Location
- **Decoders**: `src/core/JsonParsers.res`
- **Encoders**: `src/core/JsonEncoders.res`
- **Validation Points**: API input layers, `SessionStore.res`, Zip Project Loaders. 

---

## 3. Logging & Telemetry

### Logger Facade
- **Location**: `src/utils/Logger.res`
- **Modes**:
  - Console: Standard `console.log`.
  - Telemetry: Batched and flushed to backend (`BatchSize=50, interval=5s`).
  - Diagnostic: Enabled via Modal for real-time unbatched streaming to backend. Viewable locally via `./scripts/tail-diagnostics.sh`.

---

## 4. State Management (Action => Reducer => Context)

- **Pure Architecture**: Based on the Elm/Redux unidirectional loop. All mutable domain states are banned in favor of `...state` overrides.
- **Core Files**: `State.res`, `Actions.res`, `Reducer.res`, `AppContext.res`.
- **Backend Persistence**: Controlled securely via `ProjectManager.res` (manual save, debounced auto-save, zip export).

---

## 5. Security Measures

- **CSP Headers**: Enforced via `index.html`. No inline scripts (`script-src 'self' blob:`).
- **Input Sanitization**: Explicit filename sanitization via backend and UI (`removeLeadingTrailingUnderscores`, `replaceControlChars`).

---

## 6. Testing Strategy

1. **Unit Tests (`tests/unit/*_v.test.res`)**: Focus on explicit logic, data transforms, geometry.
2. **Smoke Tests (`tests/unit/*_v.test.res`)**: Virtual DOM initialization. 
3. **E2E Tests (`tests/e2e/*.spec.ts`)**: Broad interaction testing with Playwright (Editor, Image Upload, Export Workflow, Modals).

---

## 7. Performance Optimizations

- **Memoization**: Active usage of `React.memo` inside high-frequency layers (e.g., `ViewerHUD.res`, `SceneItem.res`).
- **Lazy Loading**: Non-trivial systems like `Exporter` / `Teaser` wait for active invocation.
- **Render Throttling**: AutoPilot mode throttles the Pannelum renderer to 20 FPS to limit CPU usage on heavy visual scenes. 

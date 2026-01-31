# 🛠️ Implementation Plan: Comprehensive Diagnostic Logging [User: Diagnostic Level]

## 🎯 Objective
Establish an end-to-end diagnostic pipeline that guarantees **no error is swallowed**. Frontend traces, backend warnings, and correlation IDs must work in unison to provide a "GOD MODE" view of the system when debugging.

## 📦 Scope
1.  **Frontend (ReScript)**: Enrich telemetry, add explicit `Result` logging, and support dynamic diagnostic mode.
2.  **Backend (Rust)**: Unify log sinks, correlate requests via `X-Request-ID`, and ensure `AppError` visibility.
3.  **Infrastructure**: Tooling to tail and visualize the unified log stream.

---

## 📝 1. Frontend Enhancements (ReScript)

### 1.1 Trace ID Injection (`src/systems/Api/AuthenticatedClient.res`)
- [ ] **Action**: Generate unique `X-Request-ID` for every API request.
- [ ] **Detail**: Use `window.crypto.randomUUID()` (bound to `ReBindings`) or fallback.
- [ ] **Purpose**: Link a specific UI action (e.g., "Save Project") to its backend logs.

### 1.2 Logger "Result" Helper (`src/utils/Logger.res`)
- [ ] **Action**: Add `Logger.logResult(~module_, ~msg, result)` helper.
- [ ] **Logic**:
    - `Ok(v)` -> Log `Debug` (or `Info` if `~verbose=true`).
    - `Error(e)` -> Log `Error` (with stack trace if available).
- [ ] **Goal**: Standardize how `Result` types are observed.

### 1.3 Diagnostic Mode & Global Context (`src/utils/LoggerTelemetry.res`)
- [ ] **Action**: Ensure `Trace` logs are sent to backend when `diagnosticMode` is `true`.
- [ ] **Action**: Attach `window.location.href` and `navigator.userAgent` to `Global` errors.

---

## 🦀 2. Backend Enhancements (Rust)

### 2.1 Request ID Middleware (`backend/src/middleware.rs`)
- [ ] **Action**: Enhance `RequestTracker` to extract `X-Request-ID` or generate new one.
- [ ] **Action**: Attach this ID to the current `tracing::Span`.
- [ ] **Action**: Ensure this ID appears in `diagnostic.log`.

### 2.2 Unified Log Sinks (`backend/src/api/telemetry.rs`)
- [ ] **Action**: Ensure **ALL** Backend Errors (via `AppError`) are written to `diagnostic.log` in the same JSON format as frontend telemetry.
- [ ] **Action**: Currently `AppError` logs via `tracing::error!`. Verify this flows into the unified JSON structure.

### 2.3 Dynamic Log Level (`backend/src/api/admin.rs`)
- [ ] **Action**: Add `POST /api/admin/log-level` endpoint (Admin only).
- [ ] **Payload**: `{ "level": "trace" | "debug" | "info" }`.
- [ ] **Goal**: Allow runtime verbosity changes without restart.

---

## 🛠️ 3. Verification & Tooling

### 3.1 Script: Tail Diagnostics (`scripts/tail-diagnostics.sh`)
- [ ] **Action**: Create script to `tail -f logs/diagnostic.log | jq ...`.
- [ ] **Feature**: Color code entries based on `source` (Frontend/Backend) and `level`.

### 3.2 Verification Routine
1.  Enable Diagnostic Mode in Frontend (`window.Logger.enableDiagnostics()`).
2.  Perform an endpoint action (e.g., Save Project).
3.  Fail the action intentionally (e.g., invalid data).
4.  Confirm `diagnostic.log` shows:
    - Frontend: `TRACE` logs leading up to call.
    - Frontend: `ERROR` log with stack.
    - Backend: `ERROR` log with same `X-Request-ID`.

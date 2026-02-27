# Task: Frontend Telemetry Sampling & Batch Aggregation

## Objective
Implement intelligent telemetry sampling and batch aggregation in the Logger/Telemetry pipeline to reduce network overhead and backend ingest pressure while preserving observability for critical events.

## Problem Statement
The `Logger.res` → `LoggerTelemetry.res` pipeline currently sends individual telemetry events to the backend `/api/telemetry` endpoint. High-frequency events (navigation progress, upload progress, operation lifecycle updates) can generate 100+ telemetry calls per minute during active use. Each call goes through `RequestQueue`, consuming concurrency slots that could serve user-facing requests. The backend `telemetry.rs` endpoint processes each event individually.

## Acceptance Criteria
- [x] Implement event-level sampling rates:
  - `Error`/`Critical`: 100% (always send)
  - `Warn`: 100% (always send)
  - `Info`: 50% sampling (configurable)
  - `Debug`: 10% sampling in production, 100% in development
- [x] Implement batch aggregation: buffer events for up to 5 seconds (configurable), then send as a single array payload
- [x] Add `requestIdleCallback`-gated flushing: only send batches during browser idle periods
- [x] Flush immediately on `beforeunload` (ensuring no events are lost on tab close)
- [x] Implement client-side deduplication: collapse repeated identical events into a single event with a `count` field
- [x] Add bandwidth budget: if telemetry exceeds 10KB/sec, automatically increase sampling rates (drop more Debug/Info)
- [x] Backend `/api/telemetry` should accept batch payloads and process them atomically

## Technical Notes
- **Files**: `src/utils/LoggerTelemetry.res`, `backend/src/api/telemetry.rs`
- **Pattern**: Ring buffer for pending events + periodic flush timer
- **Risk**: Low — telemetry is advisory; reduced volume doesn't affect user experience
- **Measurement**: Network tab should show ≤ 5 telemetry requests/minute during normal use (down from 100+)

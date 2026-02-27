# Task: Backend Zero-Downtime Graceful Shutdown with Request Draining

## Objective
Harden the `ShutdownManager` to guarantee zero-downtime deployments by implementing proper connection draining, health endpoint state transitions, and in-flight operation persistence.

## Problem Statement
The current `ShutdownManager` in `backend/src/services/shutdown.rs` uses `RwLock<usize>` for request counting, which introduces lock contention under high throughput. The `wait_for_completion` polls at 500ms intervals which is too coarse for fast drains. The health endpoint (`/health`) doesn't reflect shutdown state, so load balancers continue routing traffic during drain. In-flight long operations (image processing, export packaging) have no checkpoint/resume capability.

## Acceptance Criteria
- [ ] Replace `RwLock<usize>` with `AtomicUsize` for lock-free request counting
- [ ] The `/health` endpoint must return `503 Service Unavailable` once `begin_shutdown()` is called, with a `Retry-After` header containing estimated drain time
- [ ] Add a drain deadline: new requests receive `503` with a structured JSON body including `{"draining": true, "retryAfterSec": N}`
- [ ] Reduce polling interval to 100ms with exponential backoff (100ms → 200ms → 400ms)
- [ ] Persist in-flight upload sessions to disk before shutdown so they can be resumed after restart
- [ ] Add SIGTERM/SIGINT handler that triggers `begin_shutdown()` with a configurable grace period (default: 30s)
- [ ] Add shutdown completion metric: log total drain time and operations completed/abandoned

## Technical Notes
- **Files**: `backend/src/services/shutdown.rs`, `backend/src/api/health.rs`, `backend/src/main.rs`
- **Pattern**: Two-phase shutdown: (1) stop accepting new requests, (2) drain active requests with deadline
- **Risk**: Low — improved shutdown; primarily affects deployment mechanics
- **Measurement**: Zero 502/503 errors during rolling deployment under load

# 1485 - Commercial Grade Rate-Limit and Backpressure Resilience

## Context
During high-volume usage (for example, importing large projects with many scenes/thumbnails), the backend can return `429 Too Many Requests` for `/api/health` and other routes. This currently blocks critical flows and can present user-facing states that are operationally correct but not commercially robust for sustained heavy sessions.

This task defines a production-grade strategy to:
1. Prevent avoidable self-inflicted throttling.
2. Preserve user progress and transparency under load.
3. Keep backend stable while maintaining acceptable UX.
4. Provide measurable SLO-oriented controls and observability.

## Objective
Implement a full resilience layer that handles bursty workloads without collapsing into user lockout loops, while preserving backend protection and clear user messaging.

## Non-Goals
- Re-architecting the full upload/media pipeline.
- Disabling rate limiting globally.
- Relaxing security controls in production.

## Business Requirements
- User must receive precise reason when requests are throttled (`rate-limited`, not generic offline).
- System must recover automatically when `retry-after` window expires.
- Heavy workloads must degrade gracefully, not fail abruptly.
- Health/status endpoints must remain reliable for control-plane behavior.
- Engineering must have clear operational metrics to detect and tune pressure points.

## Scope

### A) Backend Rate-Limit Architecture (Route-Class Based)
- Replace single broad limiter behavior with route-class policy:
  - `health/control`: `/api/health`, `/health` (high allowance or exempt from global limiter).
  - `read-heavy`: `/api/project/{id}/file/*`, static retrieval.
  - `write-heavy`: `/api/project/import`, `/api/media/*` processing routes.
  - `admin/sensitive`: conservative limits and stricter auth checks.
- Introduce explicit env-tunable settings per class in startup/config:
  - `RATE_LIMIT_HEALTH_RPS`, `RATE_LIMIT_HEALTH_BURST`
  - `RATE_LIMIT_READ_RPS`, `RATE_LIMIT_READ_BURST`
  - `RATE_LIMIT_WRITE_RPS`, `RATE_LIMIT_WRITE_BURST`
- Ensure health checks are not starved by data-plane traffic.

### B) Structured 429 Contract
- Standardize backend `429` response payload for all protected routes:
  - `code`: `RATE_LIMITED`
  - `reason`: short machine-readable reason
  - `retryAfterSec`: integer if known
  - `scope`: `health|read|write|admin`
  - `requestId`: correlation id if available
  - `message`: user-friendly summary
- Keep `Retry-After` header and add compatibility with existing `x-ratelimit-after` where needed.

### C) Client Backpressure + Adaptive Requesting
- Add centralized handling for `429` in API transport layer (`src/systems/Api/AuthenticatedClient.res`, `src/systems/ApiHelpers.res`):
  - Parse `Retry-After`/payload `retryAfterSec`.
  - Apply bounded exponential backoff with jitter.
  - Suspend non-critical queue traffic during penalty windows.
- Extend `src/utils/RequestQueue.res` with adaptive mode:
  - Dynamic concurrency reduction under repeated `429`.
  - Cooldown windows and gradual recovery to nominal concurrency.
  - Priority lanes (critical control-plane > user-triggered write > background).
- Avoid synchronized retry storms across many queued tasks.

### D) UX and Product Behavior
- Extend status UX to distinguish:
  - Offline (network unreachable)
  - Backend unavailable
  - Backend rate-limited (with countdown)
- Ensure clear action guidance:
  - "Retry in N seconds"
  - "Pause background loading"
  - "Continue when backend recovers"
- Prevent misleading hard-block on actions that can safely queue/defer.

### E) Observability and Operations
- Emit structured telemetry/logs for throttling events:
  - route, scope, retryAfterSec, queueDepth, activeRequests, recoveryTime.
- Add backend counters/gauges for:
  - 429 count by route class
  - request latency by class
  - queue pause duration and retry attempts
- Add runbook and tuning guide under `docs/_pending_integration/`:
  - incident triage steps
  - recommended default thresholds by environment
  - rollback/feature-flag strategy

## Implementation Plan

### Phase 1 - Backend Safety and Contracts
- Introduce route-class limiter configuration and middleware wiring in:
  - `backend/src/main.rs`
  - `backend/src/startup.rs`
  - `backend/src/api/mod.rs` (if scope routing adjustments are needed)
- Add unified 429 response builder and headers.
- Add/adjust tests for limiter classification and payload schema.

### Phase 2 - Client Transport and Queue Controls
- Implement 429-aware retry/backoff in:
  - `src/systems/Api/AuthenticatedClient.res`
  - `src/systems/ApiHelpers.res`
- Add adaptive queue behavior in:
  - `src/utils/RequestQueue.res`
- Ensure compatibility with existing `NetworkStatus`/banner behavior.

### Phase 3 - UX and Product Controls
- Refine user messaging components:
  - `src/components/ui/OfflineBanner.res`
  - any upload/import status presenters that should surface throttle state
- Add countdown and non-blocking guidance where practical.

### Phase 4 - Telemetry, Testing, and Hardening
- Add instrumentation for 429 lifecycle and recovery.
- Validate via:
  - unit tests (parser, retry policy, queue adaptation)
  - backend route tests (class-specific limit behavior)
  - E2E stress scenario with burst requests and expected graceful recovery
- Produce operational note in `docs/_pending_integration/`.

## Acceptance Criteria
- `/api/health` remains usable under high media/project traffic.
- User-facing banner/messages differentiate `rate-limited` from `offline`.
- Client retries use server-provided retry windows and avoid retry storms.
- Background requests are deprioritized or paused during throttle windows.
- Backend returns consistent structured 429 payload + standard headers.
- Load scenario (high image/thumbnail count) no longer creates prolonged blind lockout.
- Build passes with zero warnings and tests for new behavior are added and green.

## Verification Checklist
- `npm run res:build`
- `npm run test:frontend`
- `cd backend && cargo test`
- `npm run build`
- Focused E2E throttle scenario proving:
  - controlled degradation
  - countdown visibility
  - automatic recovery after retry window

## Risk and Mitigation
- Risk: overly strict limits still starve key paths.
  - Mitigation: route-class isolation + env tunables + metrics.
- Risk: retry flood after cooldown expiry.
  - Mitigation: jitter, staged queue release, dynamic concurrency ramp-up.
- Risk: UX complexity/confusion.
  - Mitigation: explicit status taxonomy and consistent wording.

## Rollout Strategy
- Gate adaptive queue and route-class limiter via feature flags/env switches.
- Enable in development/staging first with synthetic burst tests.
- Promote gradually to production with monitored thresholds.
- Keep rollback path to previous limiter profile until confidence is established.

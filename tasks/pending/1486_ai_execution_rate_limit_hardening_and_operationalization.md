# 1486 - AI Execution: Rate-Limit Hardening and Operationalization

## Purpose
Execute all remaining technical work that can be delivered autonomously by AI for commercial-grade resiliency under throttling and burst traffic.

## Scope
This task covers six execution tracks that do not require product-owner policy sign-off to begin.

## Track 1 - Backend Limiter and Contract Test Coverage
### Objective
Guarantee route-class limiter behavior and structured 429 payload/header compatibility.

### Deliverables
- Add backend tests for route-class policies:
  - `health`, `read`, `write`, `admin` scope boundaries.
- Add tests for 429 body schema:
  - `code`, `reason`, `retryAfterSec`, `scope`, `requestId`, `message`.
- Add tests verifying `Retry-After` and `x-ratelimit-after` behavior.
- Add tests for no-regression on non-throttled responses.

### Candidate files
- `backend/src/middleware/rate_limiter.rs`
- `backend/src/api/mod.rs`
- `backend/src/main.rs`
- `backend/src/startup.rs`
- `backend/tests/*` (or existing module tests)

## Track 2 - Client Retry/Backoff Refinement
### Objective
Ensure deterministic, safe retry behavior that follows backend cooldown windows and avoids request storms.

### Deliverables
- Harden `429` parsing for both header and JSON payload fallback.
- Add bounded backoff behavior with jitter defaults and guardrails.
- Ensure retry path uses cooldown precedence:
  1. `Retry-After`
  2. `x-ratelimit-after`
  3. payload `retryAfterSec`
  4. local fallback
- Add negative tests (invalid/missing headers, malformed payload).

### Candidate files
- `src/systems/Api/AuthenticatedClient.res`
- `src/utils/Retry.res`
- `src/utils/Retry.resi`
- `tests/unit/AuthenticatedClient_v.test.res`
- Additional retry-focused unit test file(s)

## Track 3 - Queue Backpressure and Recovery Behavior
### Objective
Operationally safe queue behavior during throttle windows and clean automatic recovery.

### Deliverables
- Improve queue pause/resume logic for repeated `RateLimitBackoff` events.
- Ensure idempotent pause behavior and single resume timers.
- Add adaptive queue telemetry hooks (queue depth, pause duration).
- Add tests for:
  - repeated backoff events
  - online/offline transitions during cooldown
  - recovery without starvation

### Candidate files
- `src/utils/RequestQueue.res`
- `src/Main.res`
- `src/systems/EventBus.res`
- `tests/unit/*RequestQueue*`

## Track 4 - UX Clarity and Status Robustness
### Objective
Present clear, non-misleading user state during network failure vs backend throttling.

### Deliverables
- Keep state taxonomy explicit:
  - offline
  - backend unavailable
  - rate-limited with countdown
- Validate banner behavior precedence and transition timing.
- Ensure copy is concise and action-oriented.
- Add unit tests for UI state transitions if feasible.

### Candidate files
- `src/components/ui/OfflineBanner.res`
- `src/utils/NetworkStatus.res`
- `src/utils/NetworkStatus.resi`
- `src/components/ui/LucideIcons.res`

## Track 5 - Telemetry and Operational Metrics
### Objective
Enable empirical tuning and incident triage via structured observability.

### Deliverables
- Add structured logs for throttle lifecycle:
  - trigger, cooldown start, cooldown end, retry success/failure, queue stats.
- Add lightweight counters where feasible for:
  - 429 by scope
  - retry attempts by endpoint class
  - queue paused/resumed counts
- Ensure correlation uses request/operation IDs.

### Candidate files
- `src/utils/Logger.res`
- `src/utils/LoggerTelemetry.res`
- `backend/src/startup.rs` (or middleware logging points)
- `backend/src/middleware/rate_limiter.rs`

## Track 6 - E2E and Reliability Validation
### Objective
Prove end-to-end behavior under synthetic pressure and confirm graceful recovery.

### Deliverables
- Add/extend E2E scenarios that simulate throttling and recovery:
  - user sees accurate banner state
  - retries respect cooldown
  - flows recover after cooldown window
- Keep tests deterministic and non-flaky.
- Include pass/fail criteria for all new paths.

### Candidate files
- `tests/e2e/*` (new or existing robustness specs)
- Shared helpers under `tests/e2e/e2e-helpers.ts`

## Acceptance Criteria
- All six tracks implemented with tests where applicable.
- `npm run res:build` passes.
- `npm run test:frontend` passes (updated tests included).
- `cd backend && cargo test` passes (or known environment-specific failures documented).
- `npm run build` passes.
- No generic offline misclassification when backend is only rate-limiting.

## Verification Commands
- `npm run res:build`
- `npm run test:frontend`
- `cd backend && cargo test`
- `npm run build`
- Targeted E2E throttle suites (`npm run test:e2e ...`)

## Risks
- Over-throttling health/read paths by misconfiguration.
- Retry storms from incorrect fallback order.
- Queue deadlocks on repeated pause events.

## Mitigations
- Route-class tests + config sanity checks.
- Strict retry precedence and max caps.
- Explicit queue state machine assertions.

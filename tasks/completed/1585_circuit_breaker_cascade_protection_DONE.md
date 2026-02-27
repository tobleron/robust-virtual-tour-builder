# Task: Circuit Breaker Cascade Protection & Bulkhead Isolation

## Objective
Extend the existing `CircuitBreaker.res` with per-service isolation (bulkhead pattern) and implement cascade failure protection so that a backend failure in one service (e.g., geocoding) doesn't collapse unrelated services (e.g., image upload).

## Problem Statement
The current `CircuitBreaker.res` is a single generic instance used by `AuthenticatedClient`. All backend calls share one circuit state. If the geocoding provider has a 5-minute outage, the circuit opens and blocks image uploads, project saves, and exports — even though those endpoints are healthy. There is no per-service circuit isolation or health-based routing.

## Acceptance Criteria
- [x] Create a `CircuitBreakerRegistry` that manages named circuit breakers per service domain: `upload`, `export`, `geocoding`, `project`, `telemetry`
- [x] Each circuit breaker has independent failure thresholds and timeout windows, configurable per domain
- [x] Add health-check probing in `HalfOpen` state: send a lightweight health request instead of a real user request
- [x] Add circuit state observability: expose current states via `StateInspector` and `Logger.info` on state transitions
- [x] Implement bulkhead isolation: each domain has its own concurrency limit independent of `RequestQueue.maxConcurrent`
- [x] Add `onCircuitOpen` callback to trigger user-facing notifications (via `NotificationManager`)
- [x] Preserve backward compatibility: existing single-instance usage continues to work as the "default" circuit

## Technical Notes
- **Files**: `src/utils/CircuitBreaker.res`, new `src/utils/CircuitBreakerRegistry.res`, modified `src/systems/Api/AuthenticatedClient.res`
- **Pattern**: Named instances in a `Dict.t<CircuitBreaker.t>` with lazy initialization
- **Risk**: Low — additive; existing breaker becomes the `default` circuit
- **Measurement**: Simulate geocoding timeout; verify upload operations continue uninterrupted

## Verification Log
- `npm run res:build` ✅
- `npx vitest --run tests/unit/CircuitBreaker_v.test.bs.js tests/unit/CircuitBreakerRegistry_v.test.bs.js tests/unit/StateInspector_v.test.bs.js` ✅
- `npm run test:frontend` executed with all test files passing (`179/179`, `897/897`) but reported pre-existing unhandled `window is not defined` errors in `PopOver_v` test runtime.

# Task: Circuit Breaker Cascade Protection & Bulkhead Isolation

## Objective
Extend the existing `CircuitBreaker.res` with per-service isolation (bulkhead pattern) and implement cascade failure protection so that a backend failure in one service (e.g., geocoding) doesn't collapse unrelated services (e.g., image upload).

## Problem Statement
The current `CircuitBreaker.res` is a single generic instance used by `AuthenticatedClient`. All backend calls share one circuit state. If the geocoding provider has a 5-minute outage, the circuit opens and blocks image uploads, project saves, and exports — even though those endpoints are healthy. There is no per-service circuit isolation or health-based routing.

## Acceptance Criteria
- [ ] Create a `CircuitBreakerRegistry` that manages named circuit breakers per service domain: `upload`, `export`, `geocoding`, `project`, `telemetry`
- [ ] Each circuit breaker has independent failure thresholds and timeout windows, configurable per domain
- [ ] Add health-check probing in `HalfOpen` state: send a lightweight health request instead of a real user request
- [ ] Add circuit state observability: expose current states via `StateInspector` and `Logger.info` on state transitions
- [ ] Implement bulkhead isolation: each domain has its own concurrency limit independent of `RequestQueue.maxConcurrent`
- [ ] Add `onCircuitOpen` callback to trigger user-facing notifications (via `NotificationManager`)
- [ ] Preserve backward compatibility: existing single-instance usage continues to work as the "default" circuit

## Technical Notes
- **Files**: `src/utils/CircuitBreaker.res`, new `src/utils/CircuitBreakerRegistry.res`, modified `src/systems/Api/AuthenticatedClient.res`
- **Pattern**: Named instances in a `Dict.t<CircuitBreaker.t>` with lazy initialization
- **Risk**: Low — additive; existing breaker becomes the `default` circuit
- **Measurement**: Simulate geocoding timeout; verify upload operations continue uninterrupted

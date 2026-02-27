# Task: Retry Strategy Hardening with Deadline-Aware Budgets

## Objective
Harden `Retry.res` with per-operation retry budgets, deadline awareness, and circuit breaker integration to prevent retry storms under sustained failures.

## Problem Statement
The current `Retry.res` uses configurable exponential backoff with jitter, which is good. However, it lacks total-deadline awareness: a retry sequence with 3 retries and 30s max delay can take up to ~93s total. If the caller has a 60s timeout (e.g., export), the retry will waste time on attempts that will timeout anyway. Additionally, there is no coordination between the retry module and the circuit breaker — retries continue even when the circuit is open.

## Acceptance Criteria
- [ ] Add `totalDeadlineMs` parameter: retries automatically stop if remaining time < estimated next delay
- [ ] Integrate with `CircuitBreaker`: if the target circuit is `Open`, skip retries immediately and return `Exhausted`
- [ ] Add retry budget tracking: max N retries per endpoint per time window (prevents thundering herd)
- [ ] Add `Retry-After` header parsing: when a 429 response includes `Retry-After`, use that as the delay instead of calculated backoff
- [ ] Add structured retry telemetry: emit `{attempt, delay, error, totalElapsed, remainingBudget}`
- [ ] Add idempotency key support: include `X-Idempotency-Key` header on retried requests so the backend can deduplicate

## Technical Notes
- **Files**: `src/utils/Retry.res`, `src/utils/CircuitBreaker.res`, `src/utils/RequestQueue.res`
- **Pattern**: Deadline = `startTime + totalDeadlineMs`; before each retry, check `now + estimatedDelay < deadline`
- **Risk**: Low — all changes are behavioral refinements to existing retry logic
- **Measurement**: Under sustained backend failure, total retry network traffic should be bounded (not exponential)

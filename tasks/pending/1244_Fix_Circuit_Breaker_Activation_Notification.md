# Task 1244: Fix Circuit Breaker Notification and Persistence

## Objective
Ensure the circuit breaker provides consistent feedback when active and doesn't silently reject subsequent calls.

## Problem Analysis
- `AuthenticatedClient.res` only dispatches a notification when the circuit breaker *transitions* from `Closed` to `Open`.
- Subsequent calls while the breaker is already `Open` are rejected with a log but no user-facing notification.

## Proposed Solution
- Update `AuthenticatedClient.request` to dispatch a notification if a request is blocked while the breaker is `Open`, or ensure the initial error message is persistent enough for the user to understand why buttons are non-responsive.

## Acceptance Criteria
- [ ] Notification "Connection issues" (or similar) appears when the circuit breaker is activated.
- [ ] Corresponding test in `robustness.spec.ts` passes.

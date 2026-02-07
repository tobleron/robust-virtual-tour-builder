# [TEST_FIX/BUG] Connection Issues Notification Not Appearing on Circuit Breaker

## Failure Details
- **Spec File**: `tests/e2e/robustness.spec.ts:275:5` - "Circuit Breaker Activation"
- **Error**: `expect(page.locator('text=/Connection issues/i')).toBeVisible() failed`
- **Timeout**: 30000ms
- **Trace Analysis**: Test simulates repeated network failures to trigger circuit breaker. Circuit breaker activates (subsequent clicks rejected without network call), but "Connection issues" notification never appears

## Behavior Audit
- **Expected (Truth)**: "Notifications: Network failures should trigger specific 'Connection issues' feedback"
- **Observed**: Circuit breaker prevents requests silently - no user notification that connection has failed

## Proposed Solution
- [ ] Check CircuitBreaker.res activation logic - should dispatch ShowNotification("Connection issues")
- [ ] Verify EventBus dispatches notification when circuit breaker trips
- [ ] Check if notification is conditional on specific error patterns
- [ ] Test may need to poll for notification appearance after circuit breaker activation

## Impact
Users don't understand why their clicks stop having effect - looks like app is broken, not network issue.

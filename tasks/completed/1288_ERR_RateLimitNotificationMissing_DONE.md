# [TEST_FIX/BUG] Rate Limit Exceeded Notification Not Appearing

## Failure Details
- **Spec File**: `tests/e2e/robustness.spec.ts:238:5` - "Rate Limiter Notification"
- **Error**: `expect(page.locator('text=/Rate limit exceeded/i')).toBeVisible() failed`
- **Timeout**: 30000ms
- **Trace Analysis**: Test triggers rapid successive API calls to trigger rate limiting. The rate limit is enforced (API calls blocked), but no notification appears to inform user

## Behavior Audit
- **Expected (Truth)**: "Notifications: Network failures should trigger specific 'Connection issues' feedback"
- **Observed**: Rate limit silently blocks requests - no notification to user that they've hit the limit

## Proposed Solution
- [ ] Check CircuitBreaker.res - does it dispatch "Rate limit exceeded" or "Connection issues" notification?
- [ ] Verify rate limit detection logic - should monitor 429 responses and notify user
- [ ] Check EventBus for rate limit event handler
- [ ] Test may need to check for generic "Connection issues" notification instead of specific "Rate limit exceeded"

## Impact
Users don't understand why their requests stopped working - poor UX for rate-limited scenarios.

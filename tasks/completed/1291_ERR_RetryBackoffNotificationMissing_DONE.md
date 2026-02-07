# [TEST_FIX/BUG] Retry Backoff Attempt Notification Not Appearing

## Failure Details
- **Spec File**: `tests/e2e/robustness.spec.ts:329:5` - "Retry with Exponential Backoff"
- **Error**: `expect(page.locator('text=/Retrying request... \(attempt 2\)/i')).toBeVisible() failed`
- **Timeout**: 10000ms
- **Trace Analysis**: Test triggers API failure, expects exponential backoff retry to show "Retrying request... (attempt 2)" notification on second retry attempt. Notification never appears (but retry eventually succeeds).

## Behavior Audit
- **Expected (Truth)**: "Notifications: Retries may show 'Retrying' text"
- **Observed**: Retries happen silently - no attempt counter or "Retrying request" notification shown

## Proposed Solution
- [ ] Check RetryWithBackoff handler - should dispatch ShowNotification with attempt number
- [ ] Verify notification format includes "(attempt N)" text
- [ ] Check if retry is happening but notification is not rendered
- [ ] May need more granular retry notifications vs just final "Retrying" notification

## Impact
Users don't see progress/attempts during retry sequences - looks like app hung.

# [TEST_FIX/BUG] Operation Cancellation Notification Not Appearing

## Failure Details
- **Spec File**: `tests/e2e/robustness.spec.ts:251:5` - "Operation Cancellation"
- **Error**: `expect(page.locator('text=/Cancelled/i')).toBeVisible() failed`
- **Timeout**: 30000ms
- **Trace Analysis**: Test cancels an in-progress operation (e.g., save), expects to see "Cancelled" text in progress indicator, but notification/text never appears

## Behavior Audit
- **Expected (Truth)**: "Notifications: Retries may show 'Retrying' text" (implies cancellation should also show feedback)
- **Observed**: Operation cancellation happens silently - no "Cancelled" state/text shown in progress bar or notification

## Proposed Solution
- [ ] Check OperationJournal.cancelOperation() - should it dispatch ShowNotification("Cancelled")?
- [ ] Verify progress bar component renders "Cancelled" state when operation is cancelled
- [ ] Check EventBus for operation cancellation event handler
- [ ] May need to render "Cancelled" in progress UI instead of (or in addition to) notification

## Impact
Users don't get visual confirmation that their cancellation request was processed.

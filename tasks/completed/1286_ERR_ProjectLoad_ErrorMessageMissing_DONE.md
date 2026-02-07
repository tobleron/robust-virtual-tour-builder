# [TEST_FIX/BUG] Failed Project Load Error Message Not Shown

## Failure Details
- **Spec File**: `tests/e2e/error-recovery.spec.ts:55:5` - "4.3: Invalid JSON in project file should handle gracefully"
- **Error**: `expect(page.locator('text=/Failed to load project/i')).toBeVisible() failed`
- **Timeout**: 10000ms
- **Trace Analysis**: Test uploads a malformed project zip, expects error notification "Failed to load project", but notification never appears. App doesn't crash (sidebar still visible).

## Behavior Audit
- **Expected (Truth)**: "Notifications: Success/Error feedback uses Toast notifications"
- **Observed**: Invalid JSON handled silently - no error toast shown to user, but app remains stable

## Proposed Solution
- [ ] Check ProjectLoader error handling - does it dispatch ShowNotification on JSON parse failure?
- [ ] Verify JsonParsersDecoders handles malformed JSON gracefully
- [ ] Check if error is silently logged but not user-facing
- [ ] Test should verify the silent behavior is intentional OR notification dispatch is missing

## Impact
Users don't get feedback when project files are corrupted - ambiguous what went wrong.

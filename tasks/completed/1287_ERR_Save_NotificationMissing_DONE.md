# [TEST_FIX/BUG] Project Saved Notification Not Appearing

## Failure Details
- **Spec File**: `tests/e2e/robustness.spec.ts:167:5` - "Rapid Saving during Interaction"
- **Error**: `expect(page.locator('text=/Project Saved/i')).toBeVisible() failed`
- **Timeout**: 30000ms
- **Trace Analysis**: Test performs rapid save operations during scene interaction. Save API calls succeed (no 429 errors in this test), but notification never appears in DOM

## Behavior Audit
- **Expected (Truth)**: "Notifications: Success/Error feedback uses Toast notifications" (e.g., "Project Saved")
- **Observed**: Project saves silently - no "Project Saved" toast appears after successful save

## Proposed Solution
- [ ] Check PersistenceLayer - does it dispatch ShowNotification after successful IndexedDB save?
- [ ] Check ProjectSaver - does it dispatch notification after successful API save?
- [ ] Verify EventBus notification rendering queue handles rapid consecutive saves
- [ ] Test may need more aggressive toast visibility wait to catch fast-disappearing notifications

## Impact
Users don't get visual confirmation that their project saved - creates anxiety about data loss.

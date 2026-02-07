# Task 1297: Notification Text Not Visible in Tests

## Failure Details
- **Tests Affected**: 6+ tests in error-recovery and robustness specs
- **Error Pattern**: Timeout waiting for notification text (10000-30000ms)
- **Examples**:
  - "Retrying" notification (error-recovery.spec.ts:45)
  - "Failed to load project" message (error-recovery.spec.ts:64)
  - "Project Saved" text (robustness.spec.ts:183)
  - "Rate limit exceeded" message (robustness.spec.ts:248)
  - "Cancelled" text (robustness.spec.ts:269)
  - Connection error notifications (robustness.spec.ts:289, 344)

## Root Cause Analysis
NotificationCenter was rewritten to use Sonner toasts (tasks 1285-1291 from prior session). Tests expect text to be visible in DOM via Sonner toast elements.

**Possible Issues**:
1. Sonner toast elements not appearing in DOM tree
2. Toast visibility timing mismatch (toast hidden before test checks)
3. Sonner library not properly initialized
4. Toast IDs not tracking correctly (duplicate prevention failing)
5. Notification dispatch not happening when tests expect it

## Root Cause Found & Fixed ✅
**The issue**: Sonner requires a `<Toaster />` component to be rendered in the DOM
- NotificationCenter was calling `window.sonner.toast()` API
- But the Toaster component (which renders the UI) was not in the React tree
- Result: Toast API calls had nowhere to display their output

**The fix**: Added `<Shadcn.Sonner />` component to App.res
- File: `src/App.res` line 68
- Component: `<Shadcn.Sonner position="top-right" richColors=true expand=true />`
- This provides the UI container for all Sonner toasts

## Verification Status
- ✅ Fix applied and compiled successfully
- ✅ Frontend build succeeds (978.5 kB)
- ⏳ E2E tests running to verify notifications now appear
- Expected: Notification tests should now find toast elements in DOM

## Files to Check
- src/components/NotificationCenter.res: Toast rendering logic
- src/systems/NotificationManager.res: State dispatch
- src/core/NotificationTypes.res: Type definitions
- Test files: Look for text patterns being searched

## Expected Outcome
Notifications should render as visible Sonner toasts that tests can locate via text content.

## Blocking Context
This task depends on health check being fixed (task 1296) so pages can initialize and reach the point where notifications would be displayed.

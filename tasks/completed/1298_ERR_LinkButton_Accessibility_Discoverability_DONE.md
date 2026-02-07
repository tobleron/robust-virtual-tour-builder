# Task 1298: Add Link Button Not Found (Accessibility Fix Verification)

## Failure Details
- **Spec**: robustness.spec.ts:78 - "Mode Exclusivity: Linking vs Simulation"
- **Error**: `expect(page.getByRole('button', { name: /Add Link|Link/i })).toBeVisible() failed`
- **Timeout**: 30000ms
- **Selector**: Looking for button with aria-label or text matching "Add Link" or "Link"

## Expected Behavior
1. Page loads
2. Test finds "Add Link" button in UtilityBar via accessible name
3. Test clicks button to enter linking mode
4. UI shows "Link Destination" modal

## Applied Fix (Task 1292)
- Added `aria-label` to link button in src/components/UtilityBar.res
- Fixed Shadcn.Button binding to properly support `aria-label` attribute via `@as("aria-label")` decorator
- aria-label values:
  - "Add Link" when not in linking mode
  - "Close Link Mode" when in linking mode

## Current Issue
Test still fails because:
1. Health check 429 error (task 1296) blocks page initialization
2. "Start Building" button never appears
3. Test cannot proceed to the point where UtilityBar is rendered

## Verification Needed
1. Fix health check issue (task 1296)
2. Re-run this test
3. Verify aria-label is properly set on button element
4. Confirm Playwright can discover button by accessible name

## Expected Result After Fix
Button should be discoverable by test selector: `page.getByRole('button', { name: /Add Link|Link/i })`

## Files Changed
- src/components/ui/Shadcn.res: Added aria-label binding with @as decorator
- src/components/UtilityBar.res: Added aria-label prop to link button

## Related Tasks
- Task 1292: Original linking button fix
- Task 1296: Health check blocking page load

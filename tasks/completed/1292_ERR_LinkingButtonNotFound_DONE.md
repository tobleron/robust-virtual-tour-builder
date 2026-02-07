# [BUG/TEST_FIX] Add Link Button Not Appearing in Editor

## Failure Details
- **Spec File**: `tests/e2e/robustness.spec.ts:78:5` - "Mode Exclusivity: Linking vs Simulation"
- **Error**: `expect(page.getByRole('button', { name: /Add Link|Link/i })).toBeVisible() failed`
- **Timeout**: 30000ms
- **Trace Analysis**: Test loads a project and tries to enter Linking Mode by clicking "Add Link" button, but button never appears in the editor UI

## Behavior Audit
- **Expected (Truth)**: Core Application Truth #3 - "The user CANNOT start 'Simulation' while 'Linking Mode' is active"
- **Observed**: Linking Mode button not visible at all - possibly UI structure changed or button hidden conditionally

## Proposed Solution
- [ ] Check SidebarActions or Editor UI component - is "Add Link" / "Link" button rendered?
- [ ] Verify button visibility conditions - should it always be visible in edit mode?
- [ ] Check if button role/name changed - may need updated selector
- [ ] Inspect test screenshot to see actual button text/location

## Impact
Cannot test Mode Exclusivity behavior if Linking button doesn't appear - entire linking feature may be broken in UI.

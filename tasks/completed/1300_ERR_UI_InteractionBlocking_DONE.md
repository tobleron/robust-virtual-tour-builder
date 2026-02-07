# Task 1300: UI Interaction Blocking and Event Issues

## Failure Details
- **Tests**: robustness.spec.ts (debouncing, rate limiter), simulation-teaser.spec.ts
- **Errors**:
  - Line 235: Save button debouncing - 3 calls instead of expected ≤2
  - Line 40: Simulation button click timeout (sidebar intercepting pointer)
  - Line 248: Rate limiter notification not visible
  - Line 289: Connection error notification not visible

## Save Button Debouncing (robustness.spec.ts:235)
- **Issue**: Save button fires 3 API calls instead of debounced 1-2
- **Expected**: <300ms between clicks should debounce to 1-2 requests
- **Actual**: 3 requests being made
- **Root Cause**: Debounce logic may not be working or test timing may be incorrect
- **Solution**: Verify UseInteraction debounce policy is applied correctly

## Simulation Button Click Blocking (simulation-teaser.spec.ts:40)
- **Issue**: `locator.click` times out waiting for play button in viewer-utility-bar
- **Error Pattern**: "subtree intercepts pointer events" - sidebar div blocking click
- **Root Cause**: Sidebar z-index or positioning blocking viewer utility bar buttons
- **Solution**: Check CSS z-index layering, sidebar overflow, positioning

## Missing Notifications in Robustness Tests
- **Lines 248, 289**: "Rate limit exceeded", "Connection issues" notifications expected but not visible
- **Root Cause**: Same as task 1297 - notification rendering verification needed
- **Blocks**: Rate limiter and circuit breaker test validation

## Impact
- Save button timing tests cannot validate debouncing behavior
- Simulation mode tests cannot run autopilot
- Network resilience tests cannot verify notifications

## Blocked By
- Task 1297: Notification visibility (for lines 248, 289)
- Task 1296: Health check (may be causing broader issues)

## Investigation Path
1. Fix health check (task 1296)
2. Fix notification rendering (task 1297)
3. Run robustness debouncing test - if still fails, debug UseInteraction
4. Run simulation test - debug sidebar CSS/z-index if still fails

## Files to Check
- src/components/UtilityBar.res: Viewer bar positioning/z-index
- src/components/Sidebar.res: Sidebar positioning/overflow
- src/components/Sidebar/SidebarActions.res: Button wrapping
- src/systems/Interaction/UseInteraction.res: Debounce logic

## Expected Outcome
- Save buttons properly debounced
- Simulation buttons clickable
- All notifications visible when dispatched

# Task 1523: Fix Vitest Failures

## Objective
Fix the 14 failing unit tests to ensure all `vitest` tests pass successfully in the project.

## Failing Tests List

### ColorPalette (`tests/unit/ColorPalette_v.test.bs.js`)
- [ ] `ColorPalette > getGroupColor > should return correct color for valid id`
- [ ] `ColorPalette > getGroupColor > should return correct color for id requiring modulo`
- [ ] `ColorPalette > getGroupClass > should return correct class for valid id`
- [ ] `ColorPalette > getGroupClass > should return correct class for id requiring modulo`

### Exporter (`tests/unit/Exporter_v.test.bs.js`)
- [ ] `Exporter > exportTour: success path includes HTML and Library fetch` (Timeout)
- [ ] `Exporter > exportTour: progress callback failure does not stall completion` (Timeout)
- [ ] `Exporter > exportTour: handles XHR error` (Timeout)
- [ ] `Exporter > exportTour: appends custom logo if provided` (Timeout)
- [ ] `Exporter > exportTour: aborts XHR on signal abort` (Timeout)
- [ ] `Exporter > exportTour: retries on network error and succeeds` (Timeout)

### FloorNavigation (`tests/unit/FloorNavigation_v.test.bs.js`)
- [ ] `FloorNavigation > should handle floor button clicks` (AssertionError: expected false to be true)

### Sidebar (`tests/unit/Sidebar_v.test.bs.js`)
- [ ] `Sidebar > should display processing UI when UpdateProcessing is dispatched` (TypeError: Cannot read properties of null)
- [ ] `Sidebar > should call startAutoTeaser when Teaser button is clicked` (AssertionError: expected false to be true)

### ViewerUI (`tests/unit/ViewerUI_v.test.bs.js`)
- [ ] `ViewerUI > should handle floor navigation clicks` (AssertionError: expected false to be true)

## Action Plan
1. Investigate and fix the failing tests in the files listed above.
2. Run `npm run test:frontend` or `npx vitest run` locally after modifying the code.
3. Ensure the test suite resolves with zero failures.

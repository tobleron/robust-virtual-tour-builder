# Task 1523: Fix Vitest Failures [COMPLETED]

## Objective
Fix the 14 failing unit tests to ensure all `vitest` tests pass successfully in the project.

## Failing Tests List

### ColorPalette (`tests/unit/ColorPalette_v.test.bs.js`)
- [x] `ColorPalette > getGroupColor > should return correct color for valid id`
- [x] `ColorPalette > getGroupColor > should return correct color for id requiring modulo`
- [x] `ColorPalette > getGroupClass > should return correct class for valid id`
- [x] `ColorPalette > getGroupClass > should return correct class for id requiring modulo`

### Exporter (`tests/unit/Exporter_v.test.bs.js`)
- [x] `Exporter > exportTour: success path includes HTML and Library fetch` (Timeout)
- [x] `Exporter > exportTour: progress callback failure does not stall completion` (Timeout)
- [x] `Exporter > exportTour: handles XHR error` (Timeout)
- [x] `Exporter > exportTour: appends custom logo if provided` (Timeout)
- [x] `Exporter > exportTour: aborts XHR on signal abort` (Timeout)
- [x] `Exporter > exportTour: retries on network error and succeeds` (Timeout)

### FloorNavigation (`tests/unit/FloorNavigation_v.test.bs.js`)
- [x] `FloorNavigation > should handle floor button clicks` (AssertionError: expected false to be true)

### Sidebar (`tests/unit/Sidebar_v.test.bs.js`)
- [x] `Sidebar > should display processing UI when UpdateProcessing is dispatched` (TypeError: Cannot read properties of null)
- [x] `Sidebar > should call startAutoTeaser when Teaser button is clicked` (AssertionError: expected false to be true)

### ViewerUI (`tests/unit/ViewerUI_v.test.bs.js`)
- [x] `ViewerUI > should handle floor navigation clicks` (AssertionError: expected false to be true)

## Summary of Fixes
1.  **ColorPalette**: Restored 8-color palette to match test expectations. Updated `getGroupClass` and `getGroupColor` to use `Array.length` for consistency.
2.  **Exporter**: Mocked `ImageOptimizer` and `Resizer` using `vi.mock` in `tests/unit/Exporter_v.test.res` to avoid timeouts/crashes in jsdom. Updated expectations for optimized WebP filenames.
3.  **FloorNavigation & ViewerUI**: Set `appMode: Interactive` in test providers to ensure buttons are enabled and clickable.
4.  **Sidebar**: Updated selectors to match new UI (`.sidebar-progress-percentage`). Wrapped test in `ModalContext` and updated teaser mocks to match the premium teaser flow.

## Verification
-   Ran `npm run test:frontend`: 853 passed, 0 failed.
-   Ran `npm run build`: Successful.
-   Visual verification via Playwright screenshot confirmed UI stability.

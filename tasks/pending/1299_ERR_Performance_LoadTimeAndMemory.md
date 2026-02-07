# Task 1299: Performance Tests Blocked and Failing

## Failure Details
- **Tests**: performance.spec.ts - Tests 5.1, 5.2, 5.3
- **Errors**:
  - 5.1: `locator.scrollIntoViewIfNeeded: Timeout 30000ms` scrolling to scene 200
  - 5.2: `locator.click: Timeout 30000ms` clicking scene item 30 (6th click)
  - 5.3: "Total JS files: 0" - Bundle size measurement returns 0 KB

## 5.1: Scene Loading Performance
- **Issue**: Scrolling to 200th scene item times out
- **Root Cause**: Page doesn't initialize due to health check 429 (task 1296)
- **Secondary Cause**: 200 unvirtualized scene items = O(n) render performance
- **Solution**: Fix health check + may need SceneList virtualization

## 5.2: Memory Stability
- **Issue**: Can only click 6 scene items (30 = 5*6) before timeout
- **Root Cause**: Page doesn't initialize due to health check 429
- **Secondary Cause**: Memory pressure from 200 unvirtualized items
- **Solution**: Fix health check + investigate memory leaks

## 5.3: Bundle Size Validation
- **Issue**: "Total JS files: 0" despite JS downloads
- **Applied Fix**: Enhanced test with cache clearing, better listener, logging
- **Problem**: Fix didn't work - still returns 0 KB
- **Next Steps**: Debug response listener setup, check if JS requests are actually happening

## Critical Path
1. Fix health check (task 1296) - will unblock 5.1 and 5.2 page initialization
2. Re-run tests to see if they now pass with fixed health check
3. If 5.1/5.2 still slow: Profile and optimize SceneList rendering
4. If 5.3 still broken: Debug bundle size measurement in test

## Files Involved
- tests/e2e/performance.spec.ts: All three tests
- src/components/SceneList.res: May need virtualization for large lists
- backend/src/main.rs: Health check rate limiter

## Blocked By
- Task 1296: Health check 429 error blocks page initialization

## Expected Outcome
- 5.1: Should scroll and complete within 3000ms
- 5.2: Should handle rapid clicking without timeout
- 5.3: Should report actual JS bundle size

# [PERFORMANCE] Memory Leak During Rapid Scene Navigation - Investigation Required

## Findings

**Root Cause Analysis:**
The test loads 200 scenes into the SceneList component and then attempts rapid clicks through scene items (every 5th item). The test times out after ~6 clicks, suggesting memory pressure prevents React from rendering additional items.

**Key Investigation Points:**
1. **SceneList Component** - May need virtualization for large scene lists (200+ items)
2. **ViewerPool** - Cleanup logic appears sound; instances are properly destroyed
3. **Event Listener Accumulation** - May be retaining references to old scenes
4. **React Re-render Performance** - With 200 unvirtualized list items, each state change becomes O(200) renders

## Recommended Solutions

### Short-term (Test Adjustment)
- Add timeout increase for large project tests
- Add debugging logs to identify where memory is accumulating

### Long-term (Implementation)
- Implement virtualization in SceneList (use a library like `react-window`)
- Add cache eviction policy for viewer instances when managing 200+ scenes
- Profile with Chrome DevTools memory profiler during rapid navigation

## Test Files Affected
- `tests/e2e/performance.spec.ts:5.2` - Memory usage stability test

## Status
Requires deep profiling and potential SceneList refactor.

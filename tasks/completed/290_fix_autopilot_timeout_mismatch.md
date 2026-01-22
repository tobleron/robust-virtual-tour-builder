# Task: Fix AutoPilot Timeout Mismatch

## Objective
Unify timeout constants between SimulationNavigation and ViewerLoader to eliminate race condition where AutoPilot times out 2 seconds before the viewer's actual timeout.

## Problem
- `SimulationNavigation.res:41` uses hardcoded `8000ms` timeout
- `Constants.res:229` defines `sceneLoadTimeout = 10000ms`
- `ViewerLoader.res:267` uses `Constants.sceneLoadTimeout`
- This creates a race condition where simulation gives up waiting before viewer actually times out

## Acceptance Criteria
- [ ] Replace hardcoded `8000.0` in `SimulationNavigation.res:41` with `Float.fromInt(Constants.sceneLoadTimeout)`
- [ ] Verify both systems now use the same timeout value (10000ms)
- [ ] Test AutoPilot with 10+ scene project to ensure no premature timeouts
- [ ] Add comment explaining why centralized constant is used
- [ ] Run `npm run build` to verify compilation

## Technical Notes
**File**: `src/systems/SimulationNavigation.res`
**Line**: 41

**Current Code**:
```rescript
let timeout = 8000.0  // ❌ Hardcoded
```

**Fixed Code**:
```rescript
let timeout = Float.fromInt(Constants.sceneLoadTimeout)  // Use centralized value
```

## Priority
**CRITICAL** - This is causing AutoPilot to fail prematurely

## Estimated Time
5 minutes

## Related Issues
Part of AutoPilot simulation timeout analysis (AUTOPILOT_SIMULATION_ANALYSIS.md)

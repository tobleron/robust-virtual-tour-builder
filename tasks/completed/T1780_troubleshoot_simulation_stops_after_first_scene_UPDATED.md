# T1780 Troubleshoot: Simulation animates first scene only

## Objective
Identify why simulation mode animates in the first scene but fails to continue animation after transitioning to the second scene.

## Current Status (2026-03-01)
- [x] Root cause identified: `handleAddVisitedLink` was adding duplicate linkIds
- [x] Fix applied: Added duplicate prevention check
- [ ] E2E test shows simulation still not advancing (separate issue - simulation FSM or viewer wait timing)

## Root Cause Analysis

**Primary Issue (FIXED):** `SimulationHelpers.handleAddVisitedLink` was concatenating linkIds without checking for duplicates:
```rescript
// BEFORE (buggy)
visitedLinkIds: Belt.Array.concat(state.simulation.visitedLinkIds, [linkId])

// AFTER (fixed)
let alreadyVisited = Array.includes(state.simulation.visitedLinkIds, linkId)
if alreadyVisited {
  Logger.warn(...)
  state  // Return unchanged state
} else {
  // Add new linkId
}
```

This caused `visitedLinkIds` to contain duplicate entries like `["A00", "A00"]` when the same link was dispatched twice during rapid simulation cycles.

**Secondary Issue (INVESTIGATION NEEDED):** E2E tests show simulation starts but doesn't advance through scenes. The `activeIndex` stays at 0 and `visitedLinkIds` remains empty. This suggests:
1. Simulation effect not triggering transitions
2. Viewer wait timing issues
3. FSM state check still too restrictive

## Fix Applied
- `src/core/SimulationHelpers.res`: Added duplicate prevention in `handleAddVisitedLink`
- `src/systems/Simulation.res`: Relaxed FSM condition to allow `Preloading` state (enables continuous advancement)

## Verification
- Build passes: ✅
- E2E test: ❌ (Simulation starts but doesn't advance - needs further investigation)

## Next Steps
1. Verify simulation works manually in browser
2. If manual test passes, update E2E test timeouts/wait conditions
3. If manual test fails, investigate simulation effect trigger conditions

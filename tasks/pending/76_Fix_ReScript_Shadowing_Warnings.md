# Task 76: Fix ReScript Shadowing Warnings

## Priority: 🟡 IMPORTANT

## Context
The ReScript compiler emits Warning 45 (shadowing) in multiple Simulation-related modules. While the code compiles and runs, these warnings indicate potential confusion in type resolution that could lead to subtle bugs.

## Warnings to Fix

### Warning Locations

1. **SimulationChainSkipper.res:2:1-25**
   ```
   open SimulationNavigation
   this open statement shadows the label hotspotIndex (which is later used)
   ```

2. **SimulationPathGenerator.res:2:1-25**
   ```
   open SimulationNavigation
   this open statement shadows the label targetIndex (which is later used)
   ```

3. **SimulationSystem.res:2:1-25**
   ```
   open SimulationNavigation
   this open statement shadows the label targetIndex (which is later used)
   this open statement shadows the label hotspotIndex (which is later used)
   ```

## Root Cause
The `SimulationNavigation` module exports types with record labels like `targetIndex` and `hotspotIndex`. When other modules use `open SimulationNavigation` along with `open Types`, the labels from both modules conflict.

## Solution Approaches

### Option A: Use Qualified Names (Recommended)
Instead of:
```rescript
open SimulationNavigation
// ...
{targetIndex: 5, hotspotIndex: 3}
```

Use:
```rescript
// Remove: open SimulationNavigation
// ...
{SimulationNavigation.targetIndex: 5, SimulationNavigation.hotspotIndex: 3}
```

### Option B: Selective Imports
```rescript
// Instead of open SimulationNavigation
// Import only specific items needed
include {
  type enrichedLink = SimulationNavigation.enrichedLink
  // etc.
}
```

### Option C: Alias Module
```rescript
module SN = SimulationNavigation
// Use SN.targetIndex, SN.hotspotIndex
```

## Acceptance Criteria
- [ ] `npm run res:build` produces NO Warning 45 messages
- [ ] All simulation functionality works unchanged
- [ ] Code is more explicit about which module's types are being used

## Files to Modify
- `src/systems/SimulationChainSkipper.res`
- `src/systems/SimulationPathGenerator.res`
- `src/systems/SimulationSystem.res`

## Testing
1. Run `npm run res:build` - no warnings
2. Start application
3. Test Auto-Pilot simulation mode:
   - Start simulation
   - Verify scene transitions work
   - Stop simulation
4. Test Teaser recording (if applicable)

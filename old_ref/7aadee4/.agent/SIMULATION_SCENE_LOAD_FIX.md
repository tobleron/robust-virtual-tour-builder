# Simulation Mode Fixes - Complete Analysis

## Issue #1: Scene Load Timeout
**Problem**: Simulation mode failed to load the next scene, timing out after 10 seconds.

**Root Cause**: The effect was waiting for the **current** scene (already loaded) instead of the **target** scene after navigation.

**Fix**: Reordered execution to navigate first, then wait for the target scene.

---

## Issue #2: Simulation Loop Stops After First Scene
**Problem**: After successfully loading the next scene, the simulation would stop instead of continuing.

**Root Cause**: The `isAdvancing.current` flag was being reset too early, before the navigation animation completed, causing the waypoint arrow to get stuck.

**Fix**: Moved the flag reset to the end of the async function, allowing the navigation animation to complete.

---

## Issue #3: Wait Interrupted by Effect Re-run
**Problem**: When `activeIndex` changed during navigation, the effect cleanup would set `cancel := true`, interrupting the `waitForViewerScene` call.

**Root Cause**: The wait function was using the effect's `cancel` ref, which gets set to `true` when the effect re-runs.

**Fix**: Changed the wait cancellation check from `() => !cancel.contents` to `() => state.simulation.status == Running`. This ensures the wait only cancels when the simulation is actually stopped, not when the effect re-runs.

---

## Final Implementation

### Key Changes to `SimulationDriver.res`

1. **Reordered Execution** (lines 60-79):
   ```rescript
   // Calculate move
   let move = SimulationLogic.getNextMove(state)
   
   // Navigate
   Navigation.navigateToScene(...)
   
   // Wait for TARGET scene (not current scene)
   let waitResult = await SimulationNavigation.waitForViewerScene(
     targetIndex,  // ← Target scene, not state.activeIndex
     () => state.simulation.status == Running,  // ← Check status, not cancel ref
     (),
   )
   ```

2. **Flag Reset at End** (line 141):
   ```rescript
   // Reset flag at the end, after navigation animation has time to complete
   isAdvancing.current = false
   ```

3. **Guard Inside runTick** (lines 35-36):
   ```rescript
   if isAdvancing.current {
     () // Already advancing, skip to prevent overlapping async operations
   } else {
     // Proceed with simulation tick
   }
   ```

---

## How It Works

```
Scene A (activeIndex = 0):
├─ runTick() starts
├─ isAdvancing.current = true
├─ Wait 800ms delay
├─ Calculate move → Scene B (targetIndex = 1)
├─ Navigate to Scene B
│  └─ SetActiveScene(1) → activeIndex = 1
│  └─ Effect cleanup: cancel := true (doesn't affect wait!)
│  └─ Effect Run #2 queued
├─ Wait for Scene B to load (checks simulation.status)
├─ Scene B loads ✓
├─ isAdvancing.current = false
└─ Effect Run #1 ends

Scene B (activeIndex = 1):
├─ Effect Run #2 starts (was queued)
├─ runTick() starts
├─ Guard check: isAdvancing.current = false ✓
├─ isAdvancing.current = true
├─ Wait 800ms delay
├─ Calculate move → Scene C (targetIndex = 2)
├─ Navigate to Scene C
│  └─ SetActiveScene(2) → activeIndex = 2
│  └─ Effect Run #3 queued
├─ Wait for Scene C to load
└─ ... continues
```

---

## Critical Insights

1. **Don't use effect cleanup for async operations**: The `cancel` ref gets set when the effect re-runs, which can interrupt ongoing async operations. Use a more specific condition like `simulation.status == Running`.

2. **Reset flags at the right time**: Resetting `isAdvancing.current` too early (right after scene load) causes the effect to re-run before the navigation animation completes, leading to stuck waypoints.

3. **Effect dependencies matter**: The effect depends on `(simulation.status, state.activeIndex)`, so it re-runs when `activeIndex` changes during navigation. This is the mechanism that continues the simulation loop.

4. **Guard placement**: The guard should be **inside** the async function (`runTick`), not outside, to allow the effect to re-run but prevent overlapping async operations.

---

## Files Modified

- **`src/systems/SimulationDriver.res`**: Main simulation loop logic
  - Lines 60-86: Reordered execution and changed wait cancellation
  - Line 141: Moved flag reset to end of function
  - Lines 35-36: Guard inside runTick

---

## Testing Checklist

- [x] Scene loads without timeout
- [x] Simulation continues to next scene
- [ ] Waypoint arrow displays correctly (not stuck)
- [ ] Navigation animation completes before next iteration
- [ ] Multiple scenes (3+) navigate successfully
- [ ] Bridge scenes (auto-forward) work correctly
- [ ] Error handling works (invalid scenes)
- [ ] Stop/resume works correctly

---

## Complexity: 9/10

This fix involved:
- React effect lifecycle and cleanup
- Async/await timing and cancellation
- State synchronization across multiple systems
- Dual-viewer architecture
- Navigation animation timing
- Multiple race conditions

The solution required understanding the interaction between:
- Effect dependencies and re-runs
- Async operation cancellation
- Navigation state changes
- Viewer loading lifecycle

# Task 1305: BUG - Simulation Mode Runs Infinitely, Stop Button Disabled

**Priority**: HIGH - User cannot stop autopilot simulation
**Status**: Identified, Ready for Investigation
**Category**: Simulation/AutoPilot System
**Date Reported**: Feb 2026

---

## Problem Statement

The autopilot/simulation mode exhibits two critical issues:

### Issue 1: Infinite Loop
- Simulation starts and runs indefinitely
- Does not stop at natural completion (end of waypoints/scenes)
- Must be forcefully interrupted

### Issue 2: Stop Button Disabled
- The "Stop" button is not clickable during simulation
- User has no way to manually stop the playback
- Only force reload or browser back button can exit

---

## Expected Behavior

1. User clicks "Play" button to start simulation
2. Autopilot plays through the tour sequence
3. Autopilot stops naturally at the end
4. User can click "Stop" button to manually interrupt
5. Both natural and manual stops should cleanly exit simulation mode

## Actual Behavior

1. User clicks "Play" button → simulation starts
2. Simulation runs continuously ❌ (doesn't stop)
3. Stop button is disabled/unresponsive ❌
4. User cannot exit simulation mode without force reload

---

## Root Cause - Unknown (Needs Investigation)

Possible causes to investigate:

### Possibility 1: FSM State Not Transitioning
- `simulation.status` stuck in `Running` state
- Not transitioning to `Idle` on completion

### Possibility 2: Missing Condition for Loop Exit
- Autopilot loop condition not checking for end-of-journey
- Missing waypoint/scene completion detection
- Timeline not advancing properly

### Possibility 3: Stop Button State
- Stop button disabled due to FSM state
- `isSimulationMode` flag not properly managed
- Button click handler not firing

### Possibility 4: Simulation Logic Blocking
- Infinite loop in simulation update logic
- Frame rate issue causing infinite re-renders
- Animation frame callback never completing

---

## Related Code Areas to Investigate

**Simulation State Management:**
- `src/core/State.res` - `simulation` field definition
- `src/core/Reducer.res` - Simulation reducer logic
- `src/systems/Simulation/` - Autopilot/simulation logic

**UI/Button Control:**
- `src/components/ViewerHUD.res` - Viewer controls, Stop button
- `src/systems/Navigation/NavigationRenderer.res` - Button state management
- Button click handlers for play/stop

**AutoPilot Implementation:**
- `src/systems/Simulation/AutoPilot.res` or similar
- Journey/waypoint completion detection
- Frame update loop logic

---

## Investigation Steps

### Phase 1: Diagnose State
1. Check browser console during simulation
2. Inspect `window.store.state.simulation.status` - is it `Running` indefinitely?
3. Check if Stop button is in DOM and clickable
4. Monitor if simulation position advances or stays fixed

### Phase 2: Check Loop Logic
1. Trace the autopilot update loop
2. Verify completion condition (end of waypoints)
3. Check if `StopAutoPilot` action is ever dispatched
4. Monitor if `useEffect` or animation frame is cycling infinitely

### Phase 3: Button State
1. Verify Stop button's disabled state condition
2. Check if button click handler is attached
3. Test if manual `StopAutoPilot` dispatch works

---

## Success Criteria

- [ ] Simulation stops naturally at end of tour
- [ ] Stop button is clickable during simulation
- [ ] Clicking Stop exits simulation cleanly
- [ ] `simulation.status` returns to `Idle`
- [ ] No console errors during simulation
- [ ] Autopilot doesn't block other interactions

---

## Testing Steps

1. Create/load a project with multiple scenes
2. Click "Play" button to start simulation/autopilot
3. Observe if it stops or runs infinitely
4. Try clicking "Stop" button (verify it's enabled)
5. Verify clean exit from simulation mode

---

## Related Tasks

- Task 1304: Linking mode fix (may affect state management)
- Tasks 1299-1300: Performance/UI interaction tests (related to button responsiveness)

---

## Notes

- This issue emerged after the linking mode fix in Task 1304
- Possible regression from recent state management changes
- May be related to AppFSM or simulation state transitions

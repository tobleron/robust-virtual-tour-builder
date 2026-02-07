# Task 1276: Comprehensive Testing Plan for FSM-Lock Synchronization Fixes (v4.30.0)

## Objective
Validate that the FSM-Lock synchronization fixes implemented in v4.30.0 work correctly under various conditions. These fixes address critical race conditions where rapid scene clicks would cause indefinite 15-second freezes.

## Test Categories

### Category 1: Basic Scene Loading (Baseline)
**Test 1.1: Single Scene Load**
- Open a project with multiple scenes
- Click on scene 1
- Observe LockFeedback behavior
- Expected Results:
  - Scene loads within 2-3 seconds
  - "Processing scene transition..." appears at ~3s mark
  - Notification disappears when load completes
  - Lock releases naturally (NOT after 15s timeout)
  - Console shows: LOCK_ACQUIRED → PreloadStarted → TextureLoaded → LOCK_RELEASED (within 5s)

**Test 1.2: Cached Scene Load**
- Click scene 2 (assume cached, loads in <500ms)
- Click scene 3 (also cached)
- Observe timing and notifications
- Expected Results:
  - Both scenes load quickly
  - LockFeedback never shows (lock released before 3s threshold)
  - "Processing..." notification never appears
  - No countdown timer visible

**Test 1.3: Slow Scene Load**
- Click on a scene (artificially slow - use browser DevTools throttling: Fast 3G)
- Hold for 8+ seconds
- Observe notification progression
- Expected Results:
  - 0-3s: Silent (no notification)
  - 3-8s: Blue "Processing scene transition..." shown
  - 8+s: Red "Transition delayed (Xs remaining). System will auto-recover..." with countdown
  - Countdown decrements every ~500ms
  - Scene eventually loads within 15s limit

### Category 2: Rapid Scene Clicks (CRITICAL TEST)
**Test 2.1: Two Rapid Clicks**
- Click scene 1
- Within 100ms, click scene 2
- Observe system behavior
- Expected Results:
  - Scene 2 should load (NOT frozen on scene 1)
  - Lock releases when scene 2 loads (~3-5s total)
  - Console shows LOCK_REJECTED for scene 2, then retry succeeds
  - NO 15-second timeout
  - Final notification clears

**Test 2.2: Three Rapid Clicks**
- Click scene 1
- Within 100ms, click scene 2
- Within 100ms (from step 1), click scene 3
- Observe system behavior
- Expected Results:
  - Scene 3 loads (not scene 1 or 2)
  - Lock releases within 5s
  - Console shows LOCK_REJECTED messages, then final acquire succeeds for scene 3
  - No frozen state, no timeout
  - Notification reflects current lock state

**Test 2.3: Click During Transitioning**
- Click scene 1
- After ~1s (while transitioning), click scene 2
- After ~1s, click scene 3
- Expected Results:
  - System handles interruption smoothly
  - Final scene (3) loads successfully
  - Lock state updates correctly
  - No orphaned locks

### Category 3: Lock State Verification
**Test 3.1: Lock Timeout Should NOT Occur**
- Perform 5 rapid click sequences (each sequence: 3-5 quick clicks)
- Pause 30 seconds between sequences
- Monitor console for "LOCK_TIMEOUT_FORCED_RELEASE"
- Expected Results:
  - LOCK_TIMEOUT_FORCED_RELEASE should NEVER appear
  - Lock always releases naturally when scene finishes loading
  - If timeout appears, it's a regression

**Test 3.2: Lock Phase Matches FSM State**
- Click scene 1
- Open browser DevTools → Console
- Run custom test:
  ```javascript
  // Check that lock phase from telemetry matches FSM state
  // LOCK_ACQUIRED message should show phase (Loading/Swapping/Cleanup)
  // Next FSM transition should match that phase
  ```
- Expected Results:
  - LOCK_ACQUIRED shows phase: "Loading(scene-1)"
  - LOCK_TRANSITION shows FSM moving through Preloading → Transitioning → Stabilizing
  - LOCK_RELEASED shows after final FSM transition
  - No mismatches between lock phase and FSM state in logs

**Test 3.3: TextureLoaded Mismatch Handling**
- Click scene 1 (slow load, 3+ seconds)
- After 1s, click scene 2
- Observe console for "TEXTURE_LOADED_MISMATCH_IGNORED"
- Expected Results:
  - When scene 1's TextureLoaded arrives after clicking scene 2, log shows: "TEXTURE_LOADED_MISMATCH_IGNORED {waitingFor: scene-2, loadedScene: scene-1}"
  - FSM stays in Preloading(scene-2), doesn't transition
  - Scene 2 eventually loads correctly
  - No error state

### Category 4: Notification Behavior
**Test 4.1: Notification Location**
- Click scene 1
- Wait 3+ seconds for "Processing..." notification
- Observe position
- Expected Results:
  - Notification appears at TOP-RIGHT corner (not top-center)
  - Position: `top-4 right-4` (Tailwind classes)
  - Maintains z-index above viewer but below modals
  - Does NOT overlap with scene list

**Test 4.2: Notification Consolidation**
- Click scene 1 and wait for lock to activate (>3s)
- Observe how many notifications appear
- Expected Results:
  - ONLY ONE "Processing scene transition..." notification visible
  - NO additional "System is busy" notification from SceneList
  - NO duplicate toasts from different sources
  - Single source of truth: LockFeedback

**Test 4.3: Recovery Notification**
- Manually trigger timeout (if possible, or wait for it naturally)
- After force-release, observe green "Scene transition recovered" notification
- Expected Results:
  - Green notification appears at top-right
  - Shows "Scene transition recovered"
  - Appears for ~3 seconds, then fades
  - Positioned consistently with other notifications

### Category 5: Regression Tests
**Test 5.1: Throttle Warning Still Works**
- Open SceneItem.res hover menu
- Click same scene button rapidly (3x within 300ms)
- Expected Results:
  - InteractionGuard throttle warning appears: "Switching too fast - Please wait..."
  - Click is rejected
  - This protection still works

**Test 5.2: Modal Notifications Still Work**
- Attempt to delete a scene
- Observe delete confirmation modal
- Expected Results:
  - Modal appears above all notifications
  - Z-index layering correct: Modal (z-30000) > LockFeedback (z-9999)
  - Can interact with modal buttons
  - No notification overlaps with modal

**Test 5.3: User Click Rejection During Lock**
- Click scene 1
- Within 100ms, try clicking scene list (while lock held)
- Observe behavior
- Expected Results:
  - Click on new scene is queued or rejected gracefully
  - No error in console
  - Scene eventually loads when lock releases
  - User sees feedback about lock state via LockFeedback

### Category 6: Edge Cases
**Test 6.1: Same Scene Click While Loading**
- Click scene 1
- At 1s, click scene 1 again
- Expected Results:
  - Second click is ignored (already loading that scene)
  - No duplicate load
  - Lock remains held, releases naturally

**Test 6.2: Rapid Mouse Movement Across Scenes**
- Hover over scene 1 (don't click)
- Move to scene 2 (don't click)
- Quickly click scene 3
- Expected Results:
  - Only scene 3 loads
  - No hover artifacts
  - Lock acquired only for scene 3

**Test 6.3: Zoom While Transitioning**
- Click scene 1
- During transition (1-3s), try to zoom/pan panorama
- Expected Results:
  - Zoom/pan operations may be queued or ignored
  - No errors
  - Scene eventually loads
  - Viewer becomes responsive after lock releases

## Manual Testing Checklist

### Pre-Test Setup
- [ ] Ensure you have a project with 3+ scenes
- [ ] Scenes should include:
  - [ ] One fast-loading scene (cached or small, loads in <500ms)
  - [ ] One slow-loading scene (test with network throttling)
- [ ] Open browser DevTools Console (to monitor Logger output)
- [ ] Clear console before each test
- [ ] Have browser DevTools open to monitor network requests

### Quick Test Flow (10 minutes)
1. [ ] Load project, observe initial state
2. [ ] Click scene 1, wait 5s - should complete within 5s
3. [ ] Click scene 2 immediately, wait 5s - should complete without timeout
4. [ ] Click scene 3 immediately after step 3 - scene 3 should load
5. [ ] Check console: No LOCK_TIMEOUT_FORCED_RELEASE messages
6. [ ] Check notification position: Top-right corner
7. [ ] PASS if all 6 items verified

### Full Test Flow (30 minutes)
1. Run Quick Test Flow
2. Run Test 2.1 (Two Rapid Clicks)
3. Run Test 2.2 (Three Rapid Clicks)
4. Run Test 4.1 (Notification Location)
5. Run Test 5.1 (Throttle Warning)
6. Verify no console errors (red X entries)
7. PASS if all tests succeed and no red errors

## Success Criteria
- [ ] All Category 1 tests pass (basic loading)
- [ ] All Category 2 tests pass (rapid clicks - CRITICAL)
- [ ] Lock never times out unexpectedly (Category 3)
- [ ] Notifications appear in correct location (Category 4)
- [ ] No regressions in existing features (Category 5)
- [ ] Edge cases handled gracefully (Category 6)
- [ ] Console contains no error-level messages (Logger.error)
- [ ] LOCK_TIMEOUT_FORCED_RELEASE never appears during normal usage

## Failure Scenarios to Watch For
1. **Lock Stays Acquired 15+ Seconds**: Indicates FSM-Lock desynchronization
   - Check: Are FSM state and lock phase in sync?
   - Check: Did TextureLoaded arrive for wrong scene?

2. **Multiple Overlapping Notifications**: Indicates notification consolidation failed
   - Check: SceneList is not dispatching "System is busy" notification
   - Check: Only LockFeedback showing countdown

3. **React Rendering Errors**: Indicates hook usage violation
   - Check: useRef calls at component level, not in useEffect
   - Check: useEffect dependencies correct

4. **Scene Never Loads**: Indicates retry mechanism failed
   - Check: Console shows LOCK_ACQUIRE_FAILED_RETRY_SCHEDULED?
   - Check: Retries are happening every 100ms?

## Logging to Monitor
Watch console for these messages (use `./scripts/tail-diagnostics.sh` if available):
- `NavigationFSM: TRANSITION` - Shows FSM state changes
- `TransitionLock: LOCK_ACQUIRED` - Shows lock acquisition with phase and timeout
- `TransitionLock: LOCK_RELEASED` - Shows lock release
- `TransitionLock: LOCK_TIMEOUT_FORCED_RELEASE` - SHOULD NOT APPEAR in normal usage
- `SceneLoader: LOCK_ACQUIRE_FAILED_RETRY_SCHEDULED` - Expected during rapid clicks, followed by success
- `NavigationFSM: TEXTURE_LOADED_MISMATCH_IGNORED` - Expected when TextureLoaded arrives for old scene

## Performance Benchmarks
- Single scene load: <5 seconds (from click to complete)
- Rapid 3-click sequence: <5 seconds (all scenes loaded, lock released)
- Lock acquisition time: <50ms
- Lock release time: <100ms (after TextureLoaded)
- Notification display: 3-8 seconds for processing, up to 15s if delayed

## Report Template
After testing, document:
- [ ] Test name and date
- [ ] Number of test cycles completed
- [ ] Any failures encountered (with reproduction steps)
- [ ] Console errors (if any)
- [ ] Performance observations
- [ ] Regressions noticed
- [ ] Overall stability assessment (Excellent/Good/Fair/Poor)

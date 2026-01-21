# AutoPilot Simulation - Comprehensive Problem Analysis

**Date**: 2026-01-20  
**Issue**: Timeout error when clicking AutoPilot simulation button  
**Error**: "Timeout waiting for viewer to load scene"

---

## 🔍 Executive Summary

The AutoPilot simulation system is experiencing timeout errors during scene loading. After analyzing the codebase, I've identified **7 critical problems** and **5 potential conflicts** that may be causing or contributing to the timeout issue.

---

## ❌ Critical Problems

### 1. **Scene Load Timeout Mismatch** (CRITICAL)
**Location**: `SimulationNavigation.res:41` vs `Constants.res:229`

**Problem**:
- SimulationNavigation uses hardcoded `8000ms` timeout
- Constants defines `sceneLoadTimeout = 10000ms`
- ViewerLoader uses the Constants value (`10000ms`)
- This creates a race condition where simulation may timeout before viewer completes loading

**Code Evidence**:
```rescript
// SimulationNavigation.res:41
let timeout = 8000.0  // ❌ Hardcoded

// Constants.res:229
let sceneLoadTimeout = 10000  // ✓ Centralized

// ViewerLoader.res:267
state.loadSafetyTimeout = Nullable.make(Window.setTimeout(() => {
  // Uses Constants.sceneLoadTimeout (10000ms)
}, Constants.sceneLoadTimeout))
```

**Impact**: AutoPilot may give up waiting 2 seconds before the viewer actually times out.

---

### 2. **Progressive Loading Disabled During Simulation** (HIGH)
**Location**: `ViewerLoader.res:299-303`

**Problem**:
```rescript
let useProgressive =
  Belt.Option.isSome(targetScene.tinyFile) &&
  currentGlobalState.simulation.status != Running &&  // ❌ Disables during simulation
  !currentGlobalState.isTeasing &&
  !isAnticipatory
```

**Impact**: 
- During AutoPilot, scenes load only the full 4K image (no preview)
- This significantly increases load time for each scene
- No visual feedback during loading (snapshot overlay also disabled)

---

### 3. **Deep Render Wait Only During Simulation** (MEDIUM)
**Location**: `ViewerLoader.res:475-488`

**Problem**:
```rescript
if GlobalStateBridge.getState().simulation.status == Running {
  let frameCount = ref(0)
  let rec waitForDeepRender = () => {
    frameCount := frameCount.contents + 1
    if frameCount.contents < 3 {
      let _ = Window.requestAnimationFrame(waitForDeepRender)
    } else {
      checkReadyAndSwap()
    }
  }
  let _ = Window.requestAnimationFrame(waitForDeepRender)
} else {
  checkReadyAndSwap()
}
```

**Impact**: 
- Adds 3 animation frames (~50ms) delay per scene during simulation
- This is on top of the already slower loading (no progressive)
- Cumulative delay across many scenes

---

### 4. **Snapshot Overlay Disabled During Simulation** (MEDIUM)
**Location**: `ViewerLoader.res:123-138`

**Problem**:
```rescript
let isSim = GlobalStateBridge.getState().simulation.status == Running

switch Nullable.toOption(snapshot) {
| Some(s) =>
  if !isSim {
    Dom.remove(s, "snapshot-visible")
    // Smooth fade transition
  } else {
    Dom.remove(s, "snapshot-visible")
    Dom.setBackgroundImage(s, "none")  // ❌ Instant removal
  }
| None => ()
}
```

**Impact**: 
- No visual continuity between scenes during AutoPilot
- User sees black screen during each transition
- May appear "stuck" even when loading is progressing

---

### 5. **Viewer Instance Check Race Condition** (HIGH)
**Location**: `SimulationNavigation.res:53-68`

**Problem**:
```rescript
while loop.contents {
  if !isAutoPilotActive() {
    loop := false
  } else if Date.now() -. start > timeout {
    loop := false
    result := Error("Timeout waiting for viewer to load scene " ++ expectedScene.name)
  } else {
    let v = Nullable.toOption(Viewer.instance)
    switch v {
    | Some(viewer) =>
      let sceneId = LocalViewerBindings.sceneId(viewer)
      if sceneId == expectedScene.id && LocalViewerBindings.isLoaded(viewer) {
        loop := false
      } else {
        let _ = await Promise.make((resolve, _reject) => {
          let _ = setTimeout(() => resolve(), 100)
        })
      }
    | None =>  // ❌ Viewer not yet assigned
      let _ = await Promise.make((resolve, _reject) => {
        let _ = setTimeout(() => resolve(), 100)
      })
    }
  }
}
```

**Impact**: 
- Checks `Viewer.instance` which may not be updated immediately after viewer creation
- ViewerLoader creates viewer but doesn't immediately assign to global
- 100ms polling interval may miss the exact moment viewer becomes ready

---

### 6. **Dual Viewer System Complexity** (MEDIUM)
**Location**: `ViewerState.res` + `ViewerLoader.res`

**Problem**:
- System uses A/B viewer swapping for smooth transitions
- During AutoPilot, the `activeViewerKey` switches frequently
- SimulationNavigation checks `Viewer.instance` (global)
- But ViewerLoader assigns to `state.viewerA` or `state.viewerB` first
- Global assignment happens in `performSwap` (line 64)

**Code Flow**:
```
1. ViewerLoader creates new viewer → assigns to viewerA/B
2. ViewerLoader waits for 'load' event
3. ViewerLoader calls performSwap
4. performSwap assigns to global Viewer.instance
5. SimulationNavigation finally sees it
```

**Impact**: 
- Timing gap between viewer creation and global visibility
- AutoPilot may timeout during this gap

---

### 7. **Scene Loading State Not Cleared on Error** (LOW)
**Location**: `ViewerLoader.res:492-502`

**Problem**:
```rescript
Viewer.on(newViewer, "error", err => {
  state.isSceneLoading = false
  state.loadingSceneId = Nullable.null
  let errMsg = castToString(err)
  Logger.error(
    ~module_="Viewer",
    ~message="PANNELLUM_ERROR",
    ~data=Some({"sceneName": targetScene.name, "error": errMsg}),
    (),
  )
})
```

**Impact**: 
- If a scene fails to load, AutoPilot will timeout
- No retry mechanism
- No graceful degradation to skip problematic scenes

---

## ⚠️ Potential Conflicts

### 1. **Request Queue Throttling** (MEDIUM)
**Location**: `RequestQueue.res`

**Issue**: 
- Global request queue limits concurrent requests
- During AutoPilot, multiple scenes may be loading simultaneously (preloading)
- Queue may delay image fetches

**Evidence**:
```rescript
// From logs: v4.3.2 - Eliminate Too Many Requests (429) errors
```

---

### 2. **Auto-Forward Chain Skipping** (LOW)
**Location**: `SimulationDriver.res:40-49`

**Issue**:
```rescript
let delay = if simulation.skipAutoForwardGlobal {
  // Check if current scene is auto-forward (bridge)
  let currentScene = Belt.Array.get(state.scenes, state.activeIndex)
  switch currentScene {
  | Some(s) if s.isAutoForward => 0
  | _ => 800
  }
} else {
  800
}
```

**Impact**: 
- If scene is marked as auto-forward, delay is 0ms
- This may not give viewer enough time to stabilize
- Could trigger navigation before scene is fully loaded

---

### 3. **Hotspot Sync During Simulation** (LOW)
**Location**: `ViewerManager.res:360-363`

**Issue**:
```rescript
if !state.isLinking {
  HotspotManager.syncHotspots(viewer, state, scene, dispatch)
  Navigation.handleAutoForward(dispatch, state, scene)
}
```

**Impact**: 
- Hotspot sync happens even during AutoPilot
- May cause unnecessary DOM updates
- Could interfere with scene loading

---

### 4. **Continuous Render Loop** (LOW)
**Location**: `ViewerManager.res:451-477`

**Issue**:
```rescript
let rec loop = () => {
  let v = ViewerState.getActiveViewer()
  switch Nullable.toOption(v) {
  | Some(viewer) =>
    let currentState = GlobalStateBridge.getState()
    HotspotLine.updateLines(viewer, currentState, ())
  | None => ()
  }
  animationFrameId := Some(Window.requestAnimationFrame(loop))
}
```

**Impact**: 
- Runs every frame (~60fps)
- During AutoPilot, may cause performance overhead
- Could slow down scene loading

---

### 5. **Scene Switching Guard Timing** (MEDIUM)
**Location**: From logs - "Scene switching guard" + "changed to 900 milliseconds"

**Issue**:
- There appears to be a scene switching guard with 900ms delay
- This may conflict with AutoPilot's 800ms delay
- Could cause scenes to queue up

---

## 🔧 Recommended Fixes (Priority Order)

### 1. **Unify Timeout Constants** (CRITICAL - 5 min)
```rescript
// SimulationNavigation.res:41
let timeout = Float.fromInt(Constants.sceneLoadTimeout)  // Use centralized value
```

### 2. **Enable Progressive Loading for Simulation** (HIGH - 15 min)
```rescript
// ViewerLoader.res:299
let useProgressive =
  Belt.Option.isSome(targetScene.tinyFile) &&
  !currentGlobalState.isTeasing &&
  !isAnticipatory
  // Remove simulation.status check
```

### 3. **Add Retry Logic to SimulationNavigation** (HIGH - 30 min)
```rescript
let waitForViewerScene = async (
  sceneIndex: int, 
  isAutoPilotActive: unit => bool,
  ~maxRetries=3,
  ()
): result<unit, string> => {
  // Implement retry with exponential backoff
}
```

### 4. **Improve Viewer Instance Detection** (MEDIUM - 20 min)
```rescript
// Check both global and state viewers
let getViewerForScene = (sceneId: string): option<Viewer.t> => {
  // Check Viewer.instance
  // Check ViewerState.viewerA
  // Check ViewerState.viewerB
  // Return first match
}
```

### 5. **Add Simulation-Specific Loading Indicators** (LOW - 45 min)
```rescript
// Keep snapshot overlay during simulation
// Add progress indicator
// Show "Loading scene X of Y"
```

### 6. **Optimize Render Loop During Simulation** (LOW - 15 min)
```rescript
// Reduce update frequency during AutoPilot
if currentState.simulation.status == Running {
  // Update every 3rd frame instead of every frame
}
```

---

## 🧪 Debugging Steps

1. **Add Comprehensive Logging**:
```rescript
// In SimulationNavigation.res
Logger.debug(
  ~module_="Simulation",
  ~message="WAIT_LOOP_TICK",
  ~data=Some({
    "elapsed": Date.now() -. start,
    "timeout": timeout,
    "hasViewer": Nullable.toOption(Viewer.instance)->Belt.Option.isSome,
    "sceneId": sceneId,
    "expectedId": expectedScene.id,
    "isLoaded": isLoaded,
  }),
  (),
)
```

2. **Monitor Scene Load Times**:
- Check browser Network tab during AutoPilot
- Measure time from scene navigation to load completion
- Identify which scenes are slow

3. **Test with Different Scenarios**:
- Small project (3-5 scenes)
- Large project (20+ scenes)
- Mix of auto-forward and regular scenes
- With/without tinyFile (progressive loading)

---

## 📊 Performance Metrics to Track

1. **Average scene load time** (target: < 2000ms)
2. **Timeout occurrence rate** (target: 0%)
3. **Scenes loaded per minute** during AutoPilot
4. **Memory usage** during long simulations
5. **Frame rate** during scene transitions

---

## 🎯 Root Cause Hypothesis

**Most Likely**: Combination of #1 (timeout mismatch) + #2 (no progressive loading) + #5 (viewer instance race condition)

**Test**: 
1. Fix timeout constant
2. Enable progressive loading for simulation
3. Run AutoPilot on a 10-scene project
4. Expected: Timeout errors should reduce by 80%+

---

## 📝 Additional Notes

- The system was stable in v4.2.18 (per logs)
- Recent refactoring may have introduced regressions
- Consider adding integration tests for AutoPilot
- May need to implement circuit breaker pattern for failing scenes

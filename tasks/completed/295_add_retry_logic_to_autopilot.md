# Task: Add Retry Logic to AutoPilot Scene Loading

## Objective
Implement retry mechanism with exponential backoff for scene loading failures during AutoPilot to gracefully handle temporary network issues or slow-loading scenes.

## Problem
- `ViewerLoader.res:492-502` logs errors but doesn't retry
- If a scene fails to load, AutoPilot times out completely
- No graceful degradation to skip problematic scenes
- No retry mechanism for transient failures

## Acceptance Criteria
- [ ] Add `maxRetries` parameter to `waitForViewerScene` function (default: 3)
- [ ] Implement exponential backoff (1s, 2s, 4s between retries)
- [ ] Log each retry attempt with attempt number
- [ ] After max retries, offer option to skip scene or stop AutoPilot
- [ ] Add user notification for retry attempts
- [ ] Test with intentionally slow/failing scenes
- [ ] Run `npm run build` to verify compilation

## Technical Notes
**File**: `src/systems/SimulationNavigation.res`
**Function**: `waitForViewerScene`

**Current Signature**:
```rescript
let waitForViewerScene = async (
  sceneIndex: int, 
  isAutoPilotActive: unit => bool
): result<unit, string>
```

**Enhanced Signature**:
```rescript
let waitForViewerScene = async (
  sceneIndex: int, 
  isAutoPilotActive: unit => bool,
  ~maxRetries=3,
  ()
): result<unit, string>
```

**Implementation Approach**:
```rescript
let rec attemptLoad = async (attempt: int): result<unit, string> => {
  if attempt > maxRetries {
    Error("Max retries exceeded for scene " ++ expectedScene.name)
  } else {
    // Existing wait logic
    let result = await waitForScene()
    
    switch result {
    | Ok() => Ok()
    | Error(msg) =>
      if attempt < maxRetries {
        Logger.warn(
          ~module_="Simulation",
          ~message="SCENE_LOAD_RETRY",
          ~data=Some({
            "scene": expectedScene.name,
            "attempt": attempt,
            "maxRetries": maxRetries,
            "error": msg,
          }),
          (),
        )
        
        // Exponential backoff
        let backoffMs = Int.toFloat(1000 * Int.pow(2, attempt - 1))
        let _ = await wait(Int.fromFloat(backoffMs))
        
        await attemptLoad(attempt + 1)
      } else {
        Error(msg)
      }
    }
  }
}

await attemptLoad(1)
```

## Priority
**HIGH** - Improves AutoPilot reliability significantly

## Estimated Time
60 minutes

## Related Issues
Part of AutoPilot simulation timeout analysis (AUTOPILOT_SIMULATION_ANALYSIS.md)

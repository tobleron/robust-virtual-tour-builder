# Simulation Mode Telemetry Guide

## Overview
This document describes the telemetry data captured during Simulation Mode transitions. The data is logged to `logs/telemetry.log` and can be used to analyze and optimize the timing of scene transitions, camera movements, and cross-dissolve effects.

## Telemetry Events

### 1. JOURNEY_START
**Level:** INFO  
**Description:** Logged when a new camera pan journey begins (navigating from one scene to another).

| Field | Type | Description |
|-------|------|-------------|
| `journeyId` | number | Unique incrementing ID for this journey |
| `sourceScene` | string | Name of the scene we're leaving |
| `targetScene` | string | Name of the scene we're going to |
| `hotspot.startYaw` | number | Director's chosen start yaw (Click 1) |
| `hotspot.startPitch` | number | Director's chosen start pitch |
| `hotspot.targetYaw` | number | Hotspot destination yaw (Click 2) |
| `hotspot.targetPitch` | number | Hotspot destination pitch |
| `hotspot.isAutoForward` | boolean | Whether target is an auto-forward scene |
| `camera.initialPosition` | {pitch, yaw} | Camera position before journey starts |
| `camera.momentumStart` | {pitch, yaw} | Position after 10% momentum offset applied |
| `camera.momentumFactor` | number | Momentum percentage (default: 0.10 = 10%) |
| `camera.panTarget` | {pitch, yaw} | Final camera target for pan animation |
| `timing.panDuration` | number | Total animation duration in ms (default: 8000) |
| `timing.crossfadeTriggerAt` | string | Progress percentage to trigger crossfade (default: 80%) |
| `timing.expectedCrossfadeTime` | number | Expected ms when crossfade triggers |
| `delta.yaw` | number | Total yaw rotation in degrees |
| `delta.pitch` | number | Total pitch change in degrees |

### 2. JOURNEY_PROGRESS
**Level:** DEBUG  
**Description:** Logged every 10% of journey progress for tracking animation smoothness.

| Field | Type | Description |
|-------|------|-------------|
| `journeyId` | number | Journey this progress belongs to |
| `progress` | number | Progress percentage (0-100) |
| `elapsed` | number | Milliseconds since journey started |
| `camera.pitch` | number | Current camera pitch |
| `camera.yaw` | number | Current camera yaw |
| `arrowOpacity` | string | Arrow UI fade-in progress (0.00-1.00) |

### 3. CROSSFADE_TRIGGER
**Level:** INFO  
**Description:** Logged when the 80% threshold is reached and scene transition begins.

| Field | Type | Description |
|-------|------|-------------|
| `journeyId` | number | Journey being finalized |
| `triggerProgress` | number | Actual progress when triggered (should be ~80) |
| `actualElapsed` | number | Actual ms elapsed |
| `expectedElapsed` | number | Expected ms (panDuration * 0.8) |
| `timingDelta` | number | Difference between actual and expected (+ = late, - = early) |
| `finalCamera.pitch` | number | Camera pitch at trigger moment |
| `finalCamera.yaw` | number | Camera yaw at trigger moment |

### 4. JOURNEY_CANCELLED
**Level:** WARN  
**Description:** Logged when a journey is aborted because a newer journey started.

| Field | Type | Description |
|-------|------|-------------|
| `journeyId` | number | ID of cancelled journey |
| `reason` | string | Reason for cancellation |

### 5. SWAP_INITIATED (Viewer)
**Level:** INFO  
**Description:** Logged when Viewer.js begins swapping to a new scene.

| Field | Type | Description |
|-------|------|-------------|
| `loadedScene` | string | Name of scene being loaded |
| `isAutoForward` | boolean | Whether scene is auto-forward |
| `isSimulationMode` | boolean | Whether simulation mode is active |
| `activeViewerKey` | string | Current active viewer ('A' or 'B') |
| `inactiveKey` | string | Viewer being swapped to |
| `oldViewerCamera` | {pitch, yaw} | Outgoing viewer camera position |
| `newViewerCamera` | {pitch, yaw} | Incoming viewer camera position |

### 6. AUTOFORWARD_TRIGGERED (Viewer)
**Level:** DEBUG  
**Description:** Logged when handleAutoForward is invoked from Viewer.

| Field | Type | Description |
|-------|------|-------------|
| `scene` | string | Scene being processed |
| `elapsed` | number | Time taken to process auto-forward logic |
| `preSwapDelay` | number | Delay before visual swap (ms) |

### 7. CROSSFADE_STARTED (Viewer)
**Level:** INFO  
**Description:** Logged when CSS opacity transition begins.

| Field | Type | Description |
|-------|------|-------------|
| `scene` | string | Scene fading in |
| `totalSwapTime` | number | Total ms from performSwap start to crossfade |
| `preAnimationDelay` | number | Ms spent waiting for animation to start |
| `cssTransitionDuration` | string | CSS transition duration (currently 5000ms) |
| `newViewerCamera` | {pitch, yaw} | Camera position when crossfade starts |

### 8. AUTOFORWARD_CHAIN
**Level:** INFO  
**Description:** Logged when auto-forward chain progresses to next scene.

| Field | Type | Description |
|-------|------|-------------|
| `currentScene` | string | Scene we're currently on |
| `targetScene` | string | Next scene in chain |
| `chainLength` | number | Number of scenes in chain so far |
| `chainScenes` | string[] | Names of all scenes in chain |
| `hotspot.index` | number | Hotspot index being used |
| `hotspot.targetYaw` | number | Target orientation yaw |
| `hotspot.targetPitch` | number | Target orientation pitch |
| `hotspot.isReturnLink` | boolean | Whether this is a return link |
| `viewerReady` | boolean | Whether viewer reference is valid |

---

## Key Timing Values to Adjust

| Constant | Location | Current Value | Description |
|----------|----------|---------------|-------------|
| `panDuration` | NavigationSystem.js | 8000ms | Camera pan animation duration |
| `momentum` | NavigationSystem.js | 0.10 (10%) | How far along path to start panning |
| `crossfadeTrigger` | NavigationSystem.js | 0.8 (80%) | Progress at which to start scene swap |
| `preSwapDelay` | Viewer.js | 500ms | Delay before revealing new scene |
| `cssTransition` | style.css | 5000ms | Cross-dissolve opacity transition |
| `oldViewerCleanup` | Viewer.js | 5500ms | Delay before destroying old viewer |

---

## How to Analyze

1. **Run simulation mode** with the backend started
2. **Check logs/telemetry.log** for event sequence
3. **Look for patterns:**
   - `timingDelta` in CROSSFADE_TRIGGER should be near 0
   - `preAnimationDelay` should match intended delay (500ms)
   - Camera positions in CROSSFADE_STARTED should already be moving
   - Chain should progress without JOURNEY_CANCELLED warnings

## Optimization Targets

- **Smooth Handover**: `newViewerCamera` in SWAP_INITIATED should match `arrivalYaw/Pitch`
- **No Static Frame**: `preAnimationDelay` should be just enough for animation init
- **Continuous Motion**: Each journey's start camera should continue from previous end
- **No Glitches**: No JOURNEY_CANCELLED with short `elapsed` times

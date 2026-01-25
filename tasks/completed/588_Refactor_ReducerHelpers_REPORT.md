# Task 588: Refactor ReducerHelpers

## 🚨 Trigger
Project "Surgical Edit" Initiative.
File exceeds 360 line limit (507 lines).

## Objective
Split helpers by domain (Scene, UI, Simulation).

## Technical Implementation
Refactored `ReducerHelpers.res` into three distinct modules:

1. **SceneHelpers.res**:
   - Contains: `parseHotspots`, `parseScene`, `parseProject`, `syncSceneNames`, `handleDeleteScene`, `handleRemoveHotspot`, `handleAddScenes`, `handleUpdateSceneMetadata`.
   - References updated in: `SceneReducer.res`, `ProjectReducer.res`, `HotspotReducer.res`.

2. **UiHelpers.res**:
   - Contains: `insertAt`, `decodeFile`, `fileToBlob`, `fileToFile`, and low-level casting bindings.
   - References updated in: `TimelineReducer.res`, `SceneReducer.res`, `Exporter.res`.

3. **SimHelpers.res**:
   - Contains: `parseTimelineItem`, `handleUpdateTimelineStep`.
   - References updated in: `TimelineReducer.res`.

## Verification
- `npm test` passed for new test files:
  - `SceneHelpers_v.test.res`
  - `UiHelpers_v.test.res`
  - `SimHelpers_v.test.res`
- Build verification via implicit watcher compilation (lock file prevented manual build, but tests rely on compiled JS).

## Cleanup
- Deleted `src/core/ReducerHelpers.res`
- Deleted `tests/unit/ReducerHelpers_v.test.res`

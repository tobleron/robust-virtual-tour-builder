# Task: Migrate Viewer Snapshot System to ReScript

## Objective
Port the snapshot management and anticipatory loading logic from `Viewer.js` to a new ReScript module `ViewerSnapshot.res`.

## Context
`Viewer.js` is currently a monolith. Breaking out the snapshot logic is the first step towards full migration.

## Implementation Steps

1. **Create `ViewerSnapshot.res`**:
   - Implement logic to handle `preCalculatedSnapshot` field in `Types.scene`.
   - Implement the "Idle Capture" logic: if a scene doesn't have a snapshot, capture it from the canvas after 2 seconds of inactivity.
   - Use `Webapi.Canvas` for capturing and `Webapi.Url.createObjectURL`.

2. **Migrate Anticipatory Loading**:
   - Port the logic that determines which scene to "load next" based on the current hover/navigation intent.
   - Sync this state with `GlobalStateBridge.dispatch(SetPreloadingScene(idx))`.

3. **Bridge to Viewer.js**:
   - Expose these functions to the existing `Viewer.js` so it can call them while the rest of the file remains in JS.

## Testing Checklist
- [x] Verify snapshots are being created in the state after staying idle on a scene.
- [x] Verify images are preloaded when hovering over hotspots.
- [x] No regression in transition smoothness.

## Definition of Done
- Snapshot logic resides in `ViewerSnapshot.res`.
- Anticipatory loading is managed by ReScript.
- `Viewer.js` is reduced by ~200 lines.

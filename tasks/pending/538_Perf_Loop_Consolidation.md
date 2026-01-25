# Task 538: Performance Optimization - Loop Consolidation

## Objective
Reduce background CPU usage by eliminating the constant 60fps `requestAnimationFrame` (RAF) loop in `ViewerManager` during idle periods. Rely on Pannellum's `viewchange` event and specific simulation triggers for more efficient updates.

## 🛠 Strategic Implementation (Safety First)
- **Reference**: `src/components/ViewerManager.res` and `src/components/ViewerLoader.res`.
- **Action**: Remove/deactivate the global loop in `ViewerManager` effect loop.
- **Action**: Ensure the `viewchange` listener in `ViewerLoader` is robust and handles all necessary updates.
- **Action**: Ensure `SimulationRenderer` (NavigationRenderer) properly takes over the loop during active movements.

## 🛡 Stability Considerations
- **Linking Mode**: The "Yellow Rod" and linking lines currently depend on this loop for fluid movement. We MUST ensure linking still feels responsive (perhaps by re-enabling the loop ONLY during linking mode).
- **Snapshot Timing**: Verify that snapshots captured after movement (IdleSnapshot) still trigger correctly without the constant loop heartbeat.
- **Race conditions**: Ensure that `state` updates (e.g., `activeIndex` changing) still trigger a mandatory "first pass" update of the hotspots.

## ✅ Success Criteria
- [ ] 60fps loop removed from `ViewerManager.res` for idle states.
- [ ] Overlays update correctly during manual panning (via `viewchange`).
- [ ] Linking mode remains fluid and functional.
- [ ] Build passes (`npm run build`).

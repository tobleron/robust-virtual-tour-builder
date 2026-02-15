# 1406: Performance/Architecture - Visual Pipeline Render Path Optimization

## Objective
Remove heavy full-DOM reconstruction from VisualPipeline on every global state update.

## Context
- `src/components/VisualPipeline.res` re-runs pipeline render whenever `appState` changes.
- `src/components/VisualPipelineLogic.res` rebuilds timeline DOM nodes, listeners, and tooltip thumbnails in each render call, with frequent info/debug logging.

## Suggested Action Plan
- [ ] Make VisualPipeline react only to timeline-relevant state (timeline, active timeline step, referenced scene metadata).
- [ ] Replace full rebuild with keyed incremental updates (or convert fully to declarative React rendering).
- [ ] Remove per-render info logging; keep sampled diagnostics only.
- [ ] Ensure event listeners are not reattached unnecessarily per frame/update.

## Verification
- [ ] Profile timeline interactions and camera navigation; no large long-task spikes from VisualPipeline path.
- [ ] Confirm pipeline drag/drop, activation, and delete behavior remain correct.
- [ ] Validate no duplicated listeners or leaked thumbnail object URLs.

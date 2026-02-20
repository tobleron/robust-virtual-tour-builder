# Task 1502: Operation Visibility Threshold Policy by Operation Type

## Objective
Implement app-wide operation visibility thresholds (`visibleAfterMs`) so progress UI appears only when useful, with per-operation behavior instead of one global delay.

## Hard Dependency Gate
- Requires Task `1501` complete first.
- Task `1503` MUST NOT start until this task is marked complete.

## Problem Statement
Progress UI currently appears immediately for active operations selected by lifecycle priority, which causes unnecessary visual noise for short operations (especially navigation).

## Why This Matters
- Avoids progress-bar flicker for quick interactions.
- Preserves user trust by showing progress only when meaningful.
- Improves perceived responsiveness without hiding real long-running work.

## In Scope
- `src/systems/OperationLifecycle.res`
- `src/components/Sidebar/UseSidebarProcessing.res`
- `src/components/Sidebar/SidebarProcessing.res` (presentation-only updates if needed)
- `src/systems/Navigation/NavigationSupervisor.res`
- `src/systems/ProjectSystem.res`
- `src/systems/Exporter.res`
- `src/systems/UploadProcessor.res`
- `src/systems/ThumbnailProjectSystem.res`
- Related unit tests for lifecycle visibility selection

## Out of Scope
- Lock policy/capability matrix redesign (Task `1503`).
- Final race certification sweep (Task `1504`).

## Required Implementation
1. Extend lifecycle metadata with visibility gating (`visibleAfterMs` or equivalent).
2. Apply deterministic default thresholds by operation type and scope.
3. Enforce visibility gate in processing selector logic (not component rendering hacks).
4. Preserve immediate visibility for failures and critical blocking states.
5. Ensure ambient operations remain visible once threshold crossed and while active.

## Policy Baseline (starting point)
- Navigation: 400-500ms
- Project load/export: 0ms
- Upload: 150-250ms
- Ambient thumbnail generation: 600ms+

(Implementer may tune with evidence, but must document final values and rationale.)

## Execution Plan
1. Add lifecycle field and wire through start helpers.
2. Update operation producers to pass explicit thresholds.
3. Update processing selector to honor gate while maintaining priority (`Blocking > Ambient`).
4. Add tests for:
- short navigation op hidden
- long navigation op shown
- blocking long ops always shown appropriately
- ambient op threshold behavior

## Verification Matrix
- Rapid scene navigation with no unnecessary progress flashes.
- Slow/CPU-throttled navigation still surfaces progress.
- Project load/export visibility unchanged where needed.

## Acceptance Criteria
- [ ] Visibility behavior is threshold-driven per operation type.
- [ ] Short navigation actions do not show progress UI.
- [ ] Long operations still surface deterministic progress.
- [ ] Fail/error states remain immediately visible.
- [ ] Tests validate threshold gating behavior.

## Handoff Evidence Required
- Final threshold table (operation type → value).
- Before/after UX trace for rapid scene clicks.
- Test summary for visibility gate cases.

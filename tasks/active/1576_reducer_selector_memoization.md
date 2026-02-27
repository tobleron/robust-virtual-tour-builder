# Task: Reducer Selector Memoization & Dispatch Batching

## Objective
Eliminate unnecessary re-renders and redundant state computations by implementing memoized selectors and intelligent dispatch batching across the core reducer pipeline.

## Problem Statement
The current `Reducer.res` applies **all 8 sub-reducers sequentially** on every dispatched action, regardless of which domain the action belongs to. Each sub-reducer is called even when its pattern-matching returns `None`. While individually cheap, at scale (200+ scenes, rapid interactions) this creates cumulative main-thread pressure. Additionally, the `structuralRevision` check uses physical inequality (`!==`) which is correct but the linear reducer chain means every action touches every sub-module.

## Acceptance Criteria
- [x] Implement action-domain routing so that only relevant sub-reducers are called per action (e.g., `AddHotspot` skips `Simulation`, `Timeline`, `Project`, `Ui` reducers)
- [x] Add selector memoization layer (`useSelector`-style) to `AppContext.res` so React components only re-render when their selected slice changes
- [ ] Introduce `React.memo` wrappers for heavy UI trees (SceneList, HotspotLayer, ViewerUI) with custom equality comparators
- [x] Batch rapid-fire dispatches (e.g., drag operations, hotspot moves) using `requestAnimationFrame` coalescing
- [x] Ensure `structuralRevision` increments are unchanged (no false positives/negatives)
- [ ] Performance budget compliance: navigation long tasks ≤ 15 (baseline)

## Technical Notes
- **Files**: `src/core/Reducer.res`, `src/core/AppContext.res`, `src/core/ReducerModules.res`
- **Pattern**: Create an `actionDomain` variant type and a `classify` function to route actions to minimal reducer subsets
- **Risk**: Low — purely additive optimization with existing reducer semantics preserved
- **Measurement**: Before/after React Profiler flame chart comparison on 200-scene project

# Task: Intelligent Scene Preloading Pipeline with Predictive Prefetch

## Objective
Implement a predictive scene preloading pipeline that pre-fetches and pre-renders adjacent scenes based on navigation graph topology and user interaction patterns, reducing perceived scene-switch latency to near-zero.

## Problem Statement
The current `ViewerPool.res` maintains two viewer instances (active + background) for double-buffering during scene transitions. Scene preloading only occurs reactively during navigation. For a fully-connected tour with 200 scenes, the viewer has no way to predict which scene the user will navigate to next. This causes visible loading spinners on every scene switch (current baseline p95: 1500ms). The navigation graph (`NavigationGraph.res`) already computes link geometry — this data can drive predictive prefetch.

## Acceptance Criteria
- [ ] Implement a `PreloadManager` that tracks the current scene's linked neighbors from the navigation graph
- [ ] Preload top-N (configurable, default: 3) most likely next scenes based on:
  - Direct link count (scenes with more links are more likely targets)
  - Viewport direction (scenes in the user's current look direction are prioritized)
  - History frequency (scenes visited often get higher priority)
- [ ] Preloading is non-blocking and cancels automatically when the user navigates (via AbortSignal)
- [ ] Add a memory-aware guard: skip preloading if `StateDensityMonitor` reports `High` density or memory > 70% used
- [ ] Preloaded scenes are stored in `SceneCache.res` for instant swap during `SceneSwitcher`
- [ ] Target: p95 scene-switch latency ≤ 500ms for preloaded scenes (vs current 1500ms baseline)

## Technical Notes
- **Files**: New `src/systems/PreloadManager.res`, modified `src/systems/Scene/SceneLoader.res`, `src/systems/Navigation/NavigationGraph.res`, `src/core/SceneCache.res`
- **Pattern**: Idle-time preloading via `requestIdleCallback` with resource hints
- **Risk**: Medium — must not overload network or memory; requires integration with LRU cache (task #1578)
- **Dependency**: Should be implemented after task #1578 (SceneCache LRU)

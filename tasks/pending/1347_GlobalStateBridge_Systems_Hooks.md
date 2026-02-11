# [1347] Replace GlobalStateBridge in Systems, Hooks, and View Layer

## Priority: P2 (Medium)

## Context
Several systems (`NavigationRenderer`, `Simulation`, `ViewerSystem`, `LinkEditorLogic`, `UploadProcessorLogic`, and `Exporter`) and view-layer components (`Sidebar`, `Uploader`, `HotspotManager`, `ViewerSnapshot`) still reference `GlobalStateBridge`. These imports span pure helpers, animation loops, and DOM event handlers, preventing removal of the global bridge.

## Objective
1. Refactor the named systems and components to receive `state`/`dispatch` through parameters or context hooks instead of using `GlobalStateBridge` directly.
2. Where a module is pure logic (e.g., `NavigationRenderer.AnimationLoop` or `SimulationNavigation`), allow the caller to pass in a `getState`/`dispatch` pair so the module stays deterministic.
3. Ensure event handlers (viewer clicks, export progress updates) gain access to dispatch via hook props or nearby context rather than the bridge.

## Implementation Steps
1. Audit each module’s `GlobalStateBridge` usages and create `stateGetter`/`dispatcher` parameters in their public APIs. For example, `NavigationRenderer.AnimationLoop.startLoop` should accept a `getState` function instead of calling the bridge internally.
2. Update the calling components (e.g., `NavigationController`, `Simulation`, `ViewerManagerLogic`) to supply the current `stateRef`/`dispatch` from hooks and pass them through to helpers and loops.
3. For reusable hooks (e.g., `useHotspotLineLoop`, `useUploadFlow`, `useSimulationTick`), ensure they accept the dispatcher and slice of state they need, and remove any direct imports of the bridge.
4. After all systems/components are updated, the only remaining `GlobalStateBridge` imports should be in the newly structured helper `stateDispatcher` modules (which themselves will be refactored later if needed).

## Verification
1. `npm run build` passes with zero warnings.
2. Animation loops and event handlers log no warnings about stale state references. `NavigationController` still transitions scenes smoothly.
3. Integration tests around simulation, uploads, and exporting continue to pass locally.


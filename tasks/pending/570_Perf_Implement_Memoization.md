# Task 570: UI Performance - Implement React.memo across UI layers

## Objective
Apply `React.memo` to key UI components to prevent propagation of re-renders from parents, specifically focusing on the Sidebar and ViewerUI.

## Requirements
- Memoize `Sidebar.res` main component.
- Memoize `SceneItem.res` (highly critical for virtualization performance).
- Memoize static sections of `ViewerUI.res`.
- Ensure props passed to these components are stable (use `useMemo`/`useCallback` in parents).

## Success Criteria
- Components only re-render when their specific props change.
- `SceneList` scrolling remains fluid even when background state updates occur.

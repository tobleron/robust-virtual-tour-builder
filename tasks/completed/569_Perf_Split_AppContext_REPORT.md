# Task 569: UI Performance - Split Monolithic AppContext

## Objective
Split the monolithic `AppContext` into specialized domain contexts (Scene, UI, Simulation) to reduce unnecessary re-renders across the application.

## Requirements
- Identify domain boundaries in `State.res`.
- Create specialized Context modules (e.g., `SceneContext`, `UIContext`).
- Update `AppContext.res` to provide these contexts or replace it with a composite provider.
- Update subscribers to use the most specific context available.

## Success Criteria
- Typing in "Project Name" does NOT trigger re-renders in `ViewerManager` or `SceneList`.
- Changing `isLinking` does NOT trigger re-renders in `Sidebar` branding or `Project Name` input.

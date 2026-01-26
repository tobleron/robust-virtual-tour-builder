# Refactor Immutable Scene Record

## Context
The Code Quality Assessment identified a violation of the "Immutability Enforcement" standard in `src/core/Types.res`.
The `scene` record contains a mutable field:
```rescript
mutable preCalculatedSnapshot: option<string>,
```
This violates the core principle of immutable domain records.

## Objective
Remove the `mutable` field from the `scene` record and move this ephemeral caching state to a side-effect isolated location.

## Plan
1.  **Analyze Usage**: Find all references to `preCalculatedSnapshot` to understand where it is read and written.
2.  **Create Cache Module**: Create a new module (e.g., `src/core/SceneCache.res` or usage of `ViewerState`) to store these snapshots using a `Dict` or `Map` keyed by Scene ID.
3.  **Refactor Types**: Remove the field from `src/core/Types.res`.
4.  **Update Logic**: Update all call sites to use the new cache module instead of mutating the scene record.
5.  **Verify**: Ensure no performance regression in snapshot availability.
6.  **Test**: Verify tests pass.

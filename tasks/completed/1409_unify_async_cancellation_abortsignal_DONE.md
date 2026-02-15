# 1409: Unify Async Cancellation with AbortSignal

## Objective
Standardize all long-running asynchronous operations to use the `AbortSignal` pattern established by the `NavigationSupervisor`.

## Context
The `NavigationSupervisor` has modernized navigation concurrency, but systems like the `TeaserRecorder`, `Exporter`, and `ProjectManager` still use older, less robust cancellation mechanisms. Unifying these under `AbortSignal` ensures consistent behavior and prevents "zombie" promises from resolving after a task is cancelled.

## Requirements
- [ ] Update `ProjectManager.saveProject` and `loadProject` to strictly enforce the passed `AbortSignal`.
- [ ] Refactor `TeaserLogic.res` to accept and respect an `AbortSignal` from the `TeaserManager`.
- [ ] Refactor `Exporter.res` to handle cancellation mid-packaging.
- [ ] Ensure all `BackendApi` calls in these modules pass the signal down to the `Fetch` layer.

## Acceptance Criteria
- [ ] Rapidly starting and then cancelling a "Save" or "Teaser" operation immediately halts network and CPU activity.
- [ ] No state updates occur from a promise that was cancelled via `AbortSignal`.
- [ ] Consistent API across all system orchestrators for task management.

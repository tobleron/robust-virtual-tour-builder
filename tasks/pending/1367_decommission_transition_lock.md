# Task: Decommission Deprecated TransitionLock System

## Objective
Remove the legacy `TransitionLock.res` module and its associated artifacts to reduce codebase complexity and "drag".

## Context
`TransitionLock.res` was the previous mechanism for preventing overlapping transitions. It has been completely superseded by the `NavigationSupervisor`'s intent-based concurrency model. Audit confirms it is no longer used in the `src/` directory.

## Requirements
- [ ] Verify zero occurrences of `TransitionLock` in `src/`.
- [ ] Delete `src/core/TransitionLock.res`.
- [ ] Delete any associated tests (e.g., `tests/unit/TransitionLock_test.res` or similar).
- [ ] Clean up any remaining references in `MAP.md` or `DATA_FLOW.md`.

## Acceptance Criteria
- [ ] File `src/core/TransitionLock.res` is removed.
- [ ] Project builds successfully without warnings.
- [ ] `npm test` passes for all remaining modules.

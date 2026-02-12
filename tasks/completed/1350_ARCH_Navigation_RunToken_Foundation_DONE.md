# [1350] Navigation RunToken Foundation

## Objective
Eliminate stale async navigation work by introducing run-token ownership for all navigation intents.

## Scope
1. Add `runId`/epoch model to navigation supervisor lifecycle.
2. Ensure every async callback verifies active run-token before mutating state.
3. Centralize completion/abort authority in supervisor.

## Target Files
- `src/systems/Navigation/NavigationSupervisor.res`
- `src/systems/Navigation/NavigationController.res`
- `src/systems/Navigation/NavigationFSM.res`

## Verification
- `npm run res:build`
- targeted unit tests for rapid re-click and abort/re-request patterns.

## Acceptance Criteria
- Superseded navigation cannot emit completion for active intent.
- Abort followed by immediate new request remains deterministic.
- Navigation lifecycle has one authoritative completion path.

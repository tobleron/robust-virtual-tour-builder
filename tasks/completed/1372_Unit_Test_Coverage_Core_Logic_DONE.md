# Task 1372: Unit Test Coverage - Core Orchestrators and Logic

## Objective
Implement comprehensive unit tests for core state management and logic modules to ensure architectural stability and prevent regressions in state transitions.

## Context
Recent refactorings have moved logic into specialized modules, but some of these lack dedicated unit tests, relying only on integration or E2E tests.

## Targets
- `src/core/AppFSM.res`:
    - Test all valid state transitions (e.g., Idle -> Interactive, Interactive -> Navigation).
    - Verify invalid transitions are handled or ignored correctly.
    - Test mode-specific state initialization.
- `src/core/StateSnapshot.res`:
    - Test capturing the current state as a snapshot.
    - Test rolling back to a specific snapshot.
    - Verify limits on snapshot history (if applicable).
- `src/core/NavigationHelpers.res`:
    - Test `computeTargetView` and other view math.
    - Test transition metadata generation for Link and AutoForward types.
- `src/core/SimulationHelpers.res`:
    - Test `handleStartAutoPilot` logic.
    - Test waypoint generation and path validation.
- `src/core/NavigationState.res`:
    - Test the navigation-specific reducer in isolation.
    - Verify journey ID increments and chain management.

## Acceptance Criteria
- New unit tests created in `tests/unit/` using the `_v.test.res` suffix.
- All new tests pass with `npm test`.
- Code coverage for these modules is significantly improved.
- No regressions in existing functionality.

## Instructions for Jules
- Please create a pull request for these changes.
- Follow the project's ReScript and testing standards.
- Use mocks for complex dependencies where appropriate.

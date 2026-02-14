# Task 1373: Unit Test Coverage - Systems and API

## Objective
Implement unit tests for major system orchestrators and API layers to ensure reliable communication and complex system behaviors.

## Context
Systems like Navigation, Simulation, and the HotspotLine rendering logic are critical to the user experience but have complex internal states that need isolated verification.

## Targets
- `src/systems/Navigation/NavigationSupervisor.res`:
    - Test task coordination and AbortSignal cancellation.
    - Verify that only one navigation task runs at a time.
- `src/systems/SimulationLogic.res` and `src/systems/Simulation/SimulationMainLogic.res`:
    - Test the decision logic for the next move in a simulation.
    - Test path generator algorithm with various scene graphs.
- `src/systems/Exporter.res`:
    - Test the ZIP packaging logic by mocking `JSZip`.
    - Verify that all required files (HTML, JS, CSS, assets) are added to the archive.
- `src/systems/HotspotLine/` (LogicArrow, Drawing, State, Utils):
    - Test coordinate projection from 3D/Spherical to 2D/SVG.
    - Test path interpolation for curved hotspot lines.
- `src/systems/Resizer/` (ResizerLogic.res, ResizerUtils.res):
    - Test image resizing calculations.
    - Verify memory reporting and threshold logic.

## Acceptance Criteria
- New unit tests created in `tests/unit/` using the `_v.test.res` suffix.
- All new tests pass with `npm test`.
- Complex system interactions are verified via mocks.

## Instructions for Jules
- Please create a pull request for these changes.
- Follow the project's ReScript and testing standards.
- Use mocks for external libraries like `pannellum` or `JSZip`.

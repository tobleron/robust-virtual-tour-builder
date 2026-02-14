# Task 1374: Unit Test Coverage - UI Components and Hooks

## Objective
Implement unit tests for critical UI components and React hooks to ensure consistent UI behavior and interaction policies.

## Context
Components like the Sidebar and VisualPipeline handle complex user interactions and asynchronous state updates that should be verified independently of E2E tests.

## Targets
- `src/components/Sidebar/SidebarLogic.res`:
    - Test upload orchestration and state synchronization.
    - Test searching and filtering logic if applicable.
- `src/components/VisualPipeline/VisualPipelineComponent.res`:
    - Test progress percentage rendering.
    - Test status badge colors and icons based on state.
- `src/hooks/UseInteraction.res`:
    - Test interaction policy enforcement (cooldowns, blocking).
    - Test feedback dispatching.
- `src/components/ViewerManagerLogic.res`:
    - Test viewer initialization and cleanup hooks.
    - Verify synchronization between viewer state and global app state.

## Acceptance Criteria
- New unit tests created in `tests/unit/` using the `_v.test.res` suffix.
- All new tests pass with `npm test`.
- React hooks and components are tested using appropriate testing utilities.

## Instructions for Jules
- Please create a pull request for these changes.
- Follow the project's ReScript and testing standards.
- Use mocks for DOM APIs and React context where necessary.

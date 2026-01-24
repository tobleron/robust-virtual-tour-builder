# Task 361: Update Unit Tests for App.res

## 🚨 Trigger
Implementation file `/Users/r2/Desktop/robust-virtual-tour-builder/src/App.res` is newer than its test file `tests/unit/AppTest.res`.

## Objective
Update `tests/unit/AppTest.res` to ensure it covers recent changes in `App.res`.

## Requirements
- Review recent changes in `/Users/r2/Desktop/robust-virtual-tour-builder/src/App.res`.
- Update tests to maintain 100% coverage of new logic.
- Follow /testing-standards.md.

## Completion Report
- **Status**: Completed
- **Action**: Created new Vitest-based test file `tests/unit/App_v.test.res` and removed deprecated `AppTest.res`.
- **Implementation**:
  - Implemented extensive mocking for child components (`Sidebar`, `ViewerUI`, `ModalContext`, etc.) to isolate `App` logic.
  - Mocked `SessionStore` and `GlobalStateBridge` to handle side-effects and ensuring consistent test state.
  - Used `%%raw` and `vi.mock` (without `globalThis` prefix) to ensure mocks are hoisted correctly by Vitest.
  - Verified tests pass: checked for rendering of all major sub-components and the "Ready to build" placeholder state.

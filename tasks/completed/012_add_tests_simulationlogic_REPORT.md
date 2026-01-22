# Task 012: Add Unit Tests for SimulationLogic

## 🎯 Objective
Create a unit test file to verify the logic in `src/systems/SimulationLogic.res` using the Vitest framework.

## 🛠 Technical Implementation
- Created `tests/unit/SimulationLogic_v.test.res` to avoid module name shadowing.
- Implemented tests for `getNextMove` covering:
  - Standard move generation when a valid link is found.
  - Completion logic when returning to the start scene with no new paths.
  - Completion logic when no reachable scenes are available.
- Verified that the new test is automatically picked up by Vitest via the `**/*.test.bs.js` pattern.
- Confirmed that all frontend tests pass and the build is successful.

## 📝 Notes
- Replaced the old `tests/unit/SimulationLogicTest.res` placeholder with functional unit tests.
- Fixed a minor compiler warning regarding an unused open in the test file.
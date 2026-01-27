# Task 1029: Update Unit Tests for SimulationDriver.res

## 🚨 Trigger
Implementation file `src/systems/SimulationDriver.res` is newer than its test file `tests/unit/SimulationDriver_v.test.res`.

## Objective
Update `tests/unit/SimulationDriver_v.test.res` to ensure it covers recent changes in `SimulationDriver.res`.

## Requirements
- Review recent changes in `src/systems/SimulationDriver.res`.
- Update tests to maintain 100% coverage of new logic.
- Follow /testing-standards.md.

## 💡 Implementation Hints for Cloud Agents (Jules)

- **EventBus Integration**: Use `EventBus.dispatch` spies to verify that actions are triggered correctly.

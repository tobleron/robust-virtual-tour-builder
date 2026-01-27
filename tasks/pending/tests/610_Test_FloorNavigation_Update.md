# Task 610: Update Unit Tests for FloorNavigation.res

## 🚨 Trigger
Implementation file `src/components/FloorNavigation.res` is newer than its test file `tests/unit/FloorNavigation_v.test.res`.

## Objective
Update `tests/unit/FloorNavigation_v.test.res` to ensure it covers recent changes in `FloorNavigation.res`.

## Requirements
- Review recent changes in `src/components/FloorNavigation.res`.
- Update tests to maintain 100% coverage of new logic.
- Follow /testing-standards.md.

## 💡 Implementation Hints for Cloud Agents (Jules)

- **EventBus Integration**: Use `EventBus.dispatch` spies to verify that actions are triggered correctly.

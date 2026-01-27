# Task 945: Update Unit Tests for NotificationContext.res

## 🚨 Trigger
Implementation file `src/components/NotificationContext.res` is newer than its test file `tests/unit/NotificationContext_v.test.res`.

## Objective
Update `tests/unit/NotificationContext_v.test.res` to ensure it covers recent changes in `NotificationContext.res`.

## Requirements
- Review recent changes in `src/components/NotificationContext.res`.
- Update tests to maintain 100% coverage of new logic.
- Follow /testing-standards.md.

## 💡 Implementation Hints for Cloud Agents (Jules)

- **EventBus Integration**: Use `EventBus.dispatch` spies to verify that actions are triggered correctly.

# Task 619: Update Unit Tests for NotificationLayer.res

## 🚨 Trigger
Implementation file `src/components/NotificationLayer.res` is newer than its test file `tests/unit/NotificationLayer_v.test.res`.

## Objective
Update `tests/unit/NotificationLayer_v.test.res` to ensure it covers recent changes in `NotificationLayer.res`.

## Requirements
- Review recent changes in `src/components/NotificationLayer.res`.
- Update tests to maintain 100% coverage of new logic.
- Follow /testing-standards.md.

## 💡 Implementation Hints for Cloud Agents (Jules)

- **EventBus Integration**: Use `EventBus.dispatch` spies to verify that actions are triggered correctly.

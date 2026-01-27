# Task 623: Update Unit Tests for PreviewArrow.res

## 🚨 Trigger
Implementation file `src/components/PreviewArrow.res` is newer than its test file `tests/unit/PreviewArrow_v.test.res`.

## Objective
Update `tests/unit/PreviewArrow_v.test.res` to ensure it covers recent changes in `PreviewArrow.res`.

## Requirements
- Review recent changes in `src/components/PreviewArrow.res`.
- Update tests to maintain 100% coverage of new logic.
- Follow /testing-standards.md.

## 💡 Implementation Hints for Cloud Agents (Jules)

- **EventBus Integration**: Use `EventBus.dispatch` spies to verify that actions are triggered correctly.

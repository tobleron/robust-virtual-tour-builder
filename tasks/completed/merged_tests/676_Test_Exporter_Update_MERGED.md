# Task 676: Update Unit Tests for Exporter.res

## 🚨 Trigger
Implementation file `src/systems/Exporter.res` is newer than its test file `tests/unit/Exporter_v.test.res`.

## Objective
Update `tests/unit/Exporter_v.test.res` to ensure it covers recent changes in `Exporter.res`.

## Requirements
- Review recent changes in `src/systems/Exporter.res`.
- Update tests to maintain 100% coverage of new logic.
- Follow /testing-standards.md.

## 💡 Implementation Hints for Cloud Agents (Jules)

- **EventBus Integration**: Use `EventBus.dispatch` spies to verify that actions are triggered correctly.
- **API Mocks**: Mock `fetch` and `RequestQueue.schedule`. Jules should verify that the correct endpoints are called with the expected payloads.

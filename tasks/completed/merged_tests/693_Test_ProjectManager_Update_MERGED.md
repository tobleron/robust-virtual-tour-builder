# Task 693: Update Unit Tests for ProjectManager.res

## 🚨 Trigger
Implementation file `src/systems/ProjectManager.res` is newer than its test file `tests/unit/ProjectManager_v.test.res`.

## Objective
Update `tests/unit/ProjectManager_v.test.res` to ensure it covers recent changes in `ProjectManager.res`.

## Requirements
- Review recent changes in `src/systems/ProjectManager.res`.
- Update tests to maintain 100% coverage of new logic.
- Follow /testing-standards.md.

## 💡 Implementation Hints for Cloud Agents (Jules)

- **EventBus Integration**: Use `EventBus.dispatch` spies to verify that actions are triggered correctly.
- **API Mocks**: Mock `fetch` and `RequestQueue.schedule`. Jules should verify that the correct endpoints are called with the expected payloads.

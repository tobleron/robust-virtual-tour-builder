# Task 669: Update Unit Tests for BackendApi.res

## 🚨 Trigger
Implementation file `src/systems/BackendApi.res` is newer than its test file `tests/unit/BackendApi_v.test.res`.

## Objective
Update `tests/unit/BackendApi_v.test.res` to ensure it covers recent changes in `BackendApi.res`.

## Requirements
- Review recent changes in `src/systems/BackendApi.res`.
- Update tests to maintain 100% coverage of new logic.
- Follow /testing-standards.md.

## 💡 Implementation Hints for Cloud Agents (Jules)

- **API Mocks**: Mock `fetch` and `RequestQueue.schedule`. Jules should verify that the correct endpoints are called with the expected payloads.

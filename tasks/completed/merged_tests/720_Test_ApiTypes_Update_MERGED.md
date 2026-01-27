# Task 720: Update Unit Tests for ApiTypes.res

## 🚨 Trigger
Implementation file `src/systems/api/ApiTypes.res` is newer than its test file `tests/unit/ApiTypes_v.test.res`.

## Objective
Update `tests/unit/ApiTypes_v.test.res` to ensure it covers recent changes in `ApiTypes.res`.

## Requirements
- Review recent changes in `src/systems/api/ApiTypes.res`.
- Update tests to maintain 100% coverage of new logic.
- Follow /testing-standards.md.

## 💡 Implementation Hints for Cloud Agents (Jules)

- **API Mocks**: Mock `fetch` and `RequestQueue.schedule`. Jules should verify that the correct endpoints are called with the expected payloads.

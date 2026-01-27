# Task 1048: Update Unit Tests for MediaApi.res

## 🚨 Trigger
Implementation file `src/systems/api/MediaApi.res` is newer than its test file `tests/unit/MediaApi_v.test.res`.

## Objective
Update `tests/unit/MediaApi_v.test.res` to ensure it covers recent changes in `MediaApi.res`.

## Requirements
- Review recent changes in `src/systems/api/MediaApi.res`.
- Update tests to maintain 100% coverage of new logic.
- Follow /testing-standards.md.

## 💡 Implementation Hints for Cloud Agents (Jules)

- **API Mocks**: Mock `fetch` and `RequestQueue.schedule`. Jules should verify that the correct endpoints are called with the expected payloads.

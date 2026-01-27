# Task 690: Update Unit Tests for PanoramaClusterer.res

## 🚨 Trigger
Implementation file `src/systems/PanoramaClusterer.res` is newer than its test file `tests/unit/PanoramaClusterer_v.test.res`.

## Objective
Update `tests/unit/PanoramaClusterer_v.test.res` to ensure it covers recent changes in `PanoramaClusterer.res`.

## Requirements
- Review recent changes in `src/systems/PanoramaClusterer.res`.
- Update tests to maintain 100% coverage of new logic.
- Follow /testing-standards.md.

## 💡 Implementation Hints for Cloud Agents (Jules)

- **API Mocks**: Mock `fetch` and `RequestQueue.schedule`. Jules should verify that the correct endpoints are called with the expected payloads.

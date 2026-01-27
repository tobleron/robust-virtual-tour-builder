# Task 991: Update Unit Tests for AudioManager.res

## 🚨 Trigger
Implementation file `src/systems/AudioManager.res` is newer than its test file `tests/unit/AudioManager_v.test.res`.

## Objective
Update `tests/unit/AudioManager_v.test.res` to ensure it covers recent changes in `AudioManager.res`.

## Requirements
- Review recent changes in `src/systems/AudioManager.res`.
- Update tests to maintain 100% coverage of new logic.
- Follow /testing-standards.md.

## 💡 Implementation Hints for Cloud Agents (Jules)

- **API Mocks**: Mock `fetch` and `RequestQueue.schedule`. Jules should verify that the correct endpoints are called with the expected payloads.
- **DOM/Window Bindings**: Use `ReBindings` to mock browser-specific properties like `localStorage`, `location`, or `window.innerWidth`.

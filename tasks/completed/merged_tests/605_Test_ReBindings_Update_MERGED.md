# Task 605: Update Unit Tests for ReBindings.res

## 🚨 Trigger
Implementation file `src/ReBindings.res` is newer than its test file `tests/unit/ReBindings_v.test.res`.

## Objective
Update `tests/unit/ReBindings_v.test.res` to ensure it covers recent changes in `ReBindings.res`.

## Requirements
- Review recent changes in `src/ReBindings.res`.
- Update tests to maintain 100% coverage of new logic.
- Follow /testing-standards.md.

## 💡 Implementation Hints for Cloud Agents (Jules)

- **Mock Pannellum**: This module interacts with Pannellum. Mock the global `window.pannellum` object in `tests/node-setup.js` or locally.
- **API Mocks**: Mock `fetch` and `RequestQueue.schedule`. Jules should verify that the correct endpoints are called with the expected payloads.
- **DOM/Window Bindings**: Use `ReBindings` to mock browser-specific properties like `localStorage`, `location`, or `window.innerWidth`.

# Task 931: Update Unit Tests for Main.res

## 🚨 Trigger
Implementation file `src/Main.res` is newer than its test file `tests/unit/Main_v.test.res`.

## Objective
Update `tests/unit/Main_v.test.res` to ensure it covers recent changes in `Main.res`.

## Requirements
- Review recent changes in `src/Main.res`.
- Update tests to maintain 100% coverage of new logic.
- Follow /testing-standards.md.

## 💡 Implementation Hints for Cloud Agents (Jules)

- **Mock Pannellum**: This module interacts with Pannellum. Mock the global `window.pannellum` object in `tests/node-setup.js` or locally.
- **EventBus Integration**: Use `EventBus.dispatch` spies to verify that actions are triggered correctly.
- **DOM/Window Bindings**: Use `ReBindings` to mock browser-specific properties like `localStorage`, `location`, or `window.innerWidth`.

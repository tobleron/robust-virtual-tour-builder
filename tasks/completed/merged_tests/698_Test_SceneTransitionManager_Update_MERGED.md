# Task 698: Update Unit Tests for SceneTransitionManager.res

## 🚨 Trigger
Implementation file `src/systems/SceneTransitionManager.res` is newer than its test file `tests/unit/SceneTransitionManager_v.test.res`.

## Objective
Update `tests/unit/SceneTransitionManager_v.test.res` to ensure it covers recent changes in `SceneTransitionManager.res`.

## Requirements
- Review recent changes in `src/systems/SceneTransitionManager.res`.
- Update tests to maintain 100% coverage of new logic.
- Follow /testing-standards.md.

## 💡 Implementation Hints for Cloud Agents (Jules)

- **Mock Pannellum**: This module interacts with Pannellum. Mock the global `window.pannellum` object in `tests/node-setup.js` or locally.
- **DOM/Window Bindings**: Use `ReBindings` to mock browser-specific properties like `localStorage`, `location`, or `window.innerWidth`.

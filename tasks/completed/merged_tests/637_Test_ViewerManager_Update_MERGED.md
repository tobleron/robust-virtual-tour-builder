# Task 637: Update Unit Tests for ViewerManager.res

## 🚨 Trigger
Implementation file `src/components/ViewerManager.res` is newer than its test file `tests/unit/ViewerManager_v.test.res`.

## Objective
Update `tests/unit/ViewerManager_v.test.res` to ensure it covers recent changes in `ViewerManager.res`.

## Requirements
- Review recent changes in `src/components/ViewerManager.res`.
- Update tests to maintain 100% coverage of new logic.
- Follow /testing-standards.md.

## 💡 Implementation Hints for Cloud Agents (Jules)

- **Mock Pannellum**: This module interacts with Pannellum. Mock the global `window.pannellum` object in `tests/node-setup.js` or locally.
- **DOM/Window Bindings**: Use `ReBindings` to mock browser-specific properties like `localStorage`, `location`, or `window.innerWidth`.

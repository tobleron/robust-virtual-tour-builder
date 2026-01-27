# Task 718: Update Unit Tests for ViewerFollow.res

## 🚨 Trigger
Implementation file `src/systems/ViewerFollow.res` is newer than its test file `tests/unit/ViewerFollow_v.test.res`.

## Objective
Update `tests/unit/ViewerFollow_v.test.res` to ensure it covers recent changes in `ViewerFollow.res`.

## Requirements
- Review recent changes in `src/systems/ViewerFollow.res`.
- Update tests to maintain 100% coverage of new logic.
- Follow /testing-standards.md.

## 💡 Implementation Hints for Cloud Agents (Jules)

- **DOM/Window Bindings**: Use `ReBindings` to mock browser-specific properties like `localStorage`, `location`, or `window.innerWidth`.

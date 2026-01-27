# Task 656: Update Unit Tests for ViewerState.res

## 🚨 Trigger
Implementation file `src/core/ViewerState.res` is newer than its test file `tests/unit/ViewerState_v.test.res`.

## Objective
Update `tests/unit/ViewerState_v.test.res` to ensure it covers recent changes in `ViewerState.res`.

## Requirements
- Review recent changes in `src/core/ViewerState.res`.
- Update tests to maintain 100% coverage of new logic.
- Follow /testing-standards.md.

## 💡 Implementation Hints for Cloud Agents (Jules)

- **DOM/Window Bindings**: Use `ReBindings` to mock browser-specific properties like `localStorage`, `location`, or `window.innerWidth`.

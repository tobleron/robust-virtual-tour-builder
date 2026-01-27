# Task 629: Update Unit Tests for Sidebar.res

## 🚨 Trigger
Implementation file `src/components/Sidebar.res` is newer than its test file `tests/unit/Sidebar_v.test.res`.

## Objective
Update `tests/unit/Sidebar_v.test.res` to ensure it covers recent changes in `Sidebar.res`.

## Requirements
- Review recent changes in `src/components/Sidebar.res`.
- Update tests to maintain 100% coverage of new logic.
- Follow /testing-standards.md.

## 💡 Implementation Hints for Cloud Agents (Jules)

- **EventBus Integration**: Use `EventBus.dispatch` spies to verify that actions are triggered correctly.
- **DOM/Window Bindings**: Use `ReBindings` to mock browser-specific properties like `localStorage`, `location`, or `window.innerWidth`.

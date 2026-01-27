# Task 616: Update Unit Tests for LinkModal.res

## 🚨 Trigger
Implementation file `src/components/LinkModal.res` is newer than its test file `tests/unit/LinkModal_v.test.res`.

## Objective
Update `tests/unit/LinkModal_v.test.res` to ensure it covers recent changes in `LinkModal.res`.

## Requirements
- Review recent changes in `src/components/LinkModal.res`.
- Update tests to maintain 100% coverage of new logic.
- Follow /testing-standards.md.

## 💡 Implementation Hints for Cloud Agents (Jules)

- **EventBus Integration**: Use `EventBus.dispatch` spies to verify that actions are triggered correctly.
- **DOM/Window Bindings**: Use `ReBindings` to mock browser-specific properties like `localStorage`, `location`, or `window.innerWidth`.

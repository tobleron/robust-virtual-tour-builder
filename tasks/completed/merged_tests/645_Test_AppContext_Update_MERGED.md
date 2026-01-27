# Task 645: Update Unit Tests for AppContext.res

## 🚨 Trigger
Implementation file `src/core/AppContext.res` is newer than its test file `tests/unit/AppContext_v.test.res`.

## Objective
Update `tests/unit/AppContext_v.test.res` to ensure it covers recent changes in `AppContext.res`.

## Requirements
- Review recent changes in `src/core/AppContext.res`.
- Update tests to maintain 100% coverage of new logic.
- Follow /testing-standards.md.

## 💡 Implementation Hints for Cloud Agents (Jules)

- **DOM/Window Bindings**: Use `ReBindings` to mock browser-specific properties like `localStorage`, `location`, or `window.innerWidth`.

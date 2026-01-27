# Task 622: Update Unit Tests for Portal.res

## 🚨 Trigger
Implementation file `src/components/Portal.res` is newer than its test file `tests/unit/Portal_v.test.res`.

## Objective
Update `tests/unit/Portal_v.test.res` to ensure it covers recent changes in `Portal.res`.

## Requirements
- Review recent changes in `src/components/Portal.res`.
- Update tests to maintain 100% coverage of new logic.
- Follow /testing-standards.md.

## 💡 Implementation Hints for Cloud Agents (Jules)

- **DOM/Window Bindings**: Use `ReBindings` to mock browser-specific properties like `localStorage`, `location`, or `window.innerWidth`.

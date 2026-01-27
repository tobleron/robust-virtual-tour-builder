# Task 992: Update Unit Tests for CursorPhysics.res

## 🚨 Trigger
Implementation file `src/systems/CursorPhysics.res` is newer than its test file `tests/unit/CursorPhysics_v.test.res`.

## Objective
Update `tests/unit/CursorPhysics_v.test.res` to ensure it covers recent changes in `CursorPhysics.res`.

## Requirements
- Review recent changes in `src/systems/CursorPhysics.res`.
- Update tests to maintain 100% coverage of new logic.
- Follow /testing-standards.md.

## 💡 Implementation Hints for Cloud Agents (Jules)

- **DOM/Window Bindings**: Use `ReBindings` to mock browser-specific properties like `localStorage`, `location`, or `window.innerWidth`.

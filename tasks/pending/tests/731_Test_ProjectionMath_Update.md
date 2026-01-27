# Task 731: Update Unit Tests for ProjectionMath.res

## 🚨 Trigger
Implementation file `src/utils/ProjectionMath.res` is newer than its test file `tests/unit/ProjectionMath_v.test.res`.

## Objective
Update `tests/unit/ProjectionMath_v.test.res` to ensure it covers recent changes in `ProjectionMath.res`.

## Requirements
- Review recent changes in `src/utils/ProjectionMath.res`.
- Update tests to maintain 100% coverage of new logic.
- Follow /testing-standards.md.

## 💡 Implementation Hints for Cloud Agents (Jules)

- **DOM/Window Bindings**: Use `ReBindings` to mock browser-specific properties like `localStorage`, `location`, or `window.innerWidth`.

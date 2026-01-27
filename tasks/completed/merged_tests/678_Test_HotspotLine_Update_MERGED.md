# Task 678: Update Unit Tests for HotspotLine.res

## 🚨 Trigger
Implementation file `src/systems/HotspotLine.res` is newer than its test file `tests/unit/HotspotLine_v.test.res`.

## Objective
Update `tests/unit/HotspotLine_v.test.res` to ensure it covers recent changes in `HotspotLine.res`.

## Requirements
- Review recent changes in `src/systems/HotspotLine.res`.
- Update tests to maintain 100% coverage of new logic.
- Follow /testing-standards.md.

## 💡 Implementation Hints for Cloud Agents (Jules)

- **DOM/Window Bindings**: Use `ReBindings` to mock browser-specific properties like `localStorage`, `location`, or `window.innerWidth`.

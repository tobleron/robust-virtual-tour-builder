# Task 679: Update Unit Tests for HotspotLineLogic.res

## 🚨 Trigger
Implementation file `src/systems/HotspotLineLogic.res` is newer than its test file `tests/unit/HotspotLineLogic_v.test.res`.

## Objective
Update `tests/unit/HotspotLineLogic_v.test.res` to ensure it covers recent changes in `HotspotLineLogic.res`.

## Requirements
- Review recent changes in `src/systems/HotspotLineLogic.res`.
- Update tests to maintain 100% coverage of new logic.
- Follow /testing-standards.md.

## 💡 Implementation Hints for Cloud Agents (Jules)

- **DOM/Window Bindings**: Use `ReBindings` to mock browser-specific properties like `localStorage`, `location`, or `window.innerWidth`.

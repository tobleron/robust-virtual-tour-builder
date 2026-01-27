# Task 781: Add Unit Tests for TeaserRecorderOverlay.res

## 🚨 Trigger
Modifications detected in `src/systems/TeaserRecorderOverlay.res` without established unit tests.

## Objective
Create a Vitest file `tests/unit/TeaserRecorderOverlay_v.test.res` to cover logic in this module.

## Requirements
- Maintain code coverage for all exported functions.
- Follow /testing-standards.md.

## 💡 Implementation Hints for Cloud Agents (Jules)

- **DOM/Window Bindings**: Use `ReBindings` to mock browser-specific properties like `localStorage`, `location`, or `window.innerWidth`.

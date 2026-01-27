# Task 750: Add Unit Tests for SceneListMain.res

## 🚨 Trigger
Modifications detected in `src/components/SceneList/SceneListMain.res` without established unit tests.

## Objective
Create a Vitest file `tests/unit/SceneListMain_v.test.res` to cover logic in this module.

## Requirements
- Maintain code coverage for all exported functions.
- Follow /testing-standards.md.

## 💡 Implementation Hints for Cloud Agents (Jules)

- **EventBus Integration**: Use `EventBus.dispatch` spies to verify that actions are triggered correctly.
- **DOM/Window Bindings**: Use `ReBindings` to mock browser-specific properties like `localStorage`, `location`, or `window.innerWidth`.

# Task 1030: Update Unit Tests for SimulationNavigation.res

## 🚨 Trigger
Implementation file `src/systems/SimulationNavigation.res` is newer than its test file `tests/unit/SimulationNavigation_v.test.res`.

## Objective
Update `tests/unit/SimulationNavigation_v.test.res` to ensure it covers recent changes in `SimulationNavigation.res`.

## Requirements
- Review recent changes in `src/systems/SimulationNavigation.res`.
- Update tests to maintain 100% coverage of new logic.
- Follow /testing-standards.md.

## 💡 Implementation Hints for Cloud Agents (Jules)

- **Mock Pannellum**: This module interacts with Pannellum. Mock the global `window.pannellum` object in `tests/node-setup.js` or locally.
- **EventBus Integration**: Use `EventBus.dispatch` spies to verify that actions are triggered correctly.

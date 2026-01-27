# Task 689: Update Unit Tests for PannellumLifecycle.res

## 🚨 Trigger
Implementation file `src/systems/PannellumLifecycle.res` is newer than its test file `tests/unit/PannellumLifecycle_v.test.res`.

## Objective
Update `tests/unit/PannellumLifecycle_v.test.res` to ensure it covers recent changes in `PannellumLifecycle.res`.

## Requirements
- Review recent changes in `src/systems/PannellumLifecycle.res`.
- Update tests to maintain 100% coverage of new logic.
- Follow /testing-standards.md.

## 💡 Implementation Hints for Cloud Agents (Jules)

- **Mock Pannellum**: This module interacts with Pannellum. Mock the global `window.pannellum` object in `tests/node-setup.js` or locally.

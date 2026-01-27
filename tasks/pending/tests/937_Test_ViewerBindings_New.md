# Task 937: Add Unit Tests for ViewerBindings.res

## 🚨 Trigger
Modifications detected in `src/bindings/ViewerBindings.res` without established unit tests.

## Objective
Create a Vitest file `tests/unit/ViewerBindings_v.test.res` to cover logic in this module.

## Requirements
- Maintain code coverage for all exported functions.
- Follow /testing-standards.md.

## 💡 Implementation Hints for Cloud Agents (Jules)

- **Mock Pannellum**: This module interacts with Pannellum. Mock the global `window.pannellum` object in `tests/node-setup.js` or locally.

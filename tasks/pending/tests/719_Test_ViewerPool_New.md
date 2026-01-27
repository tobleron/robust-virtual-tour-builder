# Task 719: Add Unit Tests for ViewerPool.res

## 🚨 Trigger
Modifications detected in `src/systems/ViewerPool.res` without established unit tests.

## Objective
Create a Vitest file `tests/unit/ViewerPool_v.test.res` to cover logic in this module.

## Requirements
- Maintain code coverage for all exported functions.
- Follow /testing-standards.md.

## 💡 Implementation Hints for Cloud Agents (Jules)

- **Mock Pannellum**: This module interacts with Pannellum. Mock the global `window.pannellum` object in `tests/node-setup.js` or locally.
- **DOM/Window Bindings**: Use `ReBindings` to mock browser-specific properties like `localStorage`, `location`, or `window.innerWidth`.

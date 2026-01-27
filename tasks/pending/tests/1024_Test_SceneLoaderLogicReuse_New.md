# Task 1024: Add Unit Tests for SceneLoaderLogicReuse.res

## 🚨 Trigger
Modifications detected in `src/systems/SceneLoaderLogicReuse.res` without established unit tests.

## Objective
Create a Vitest file `tests/unit/SceneLoaderLogicReuse_v.test.res` to cover logic in this module.

## Requirements
- Maintain code coverage for all exported functions.
- Follow /testing-standards.md.

## 💡 Implementation Hints for Cloud Agents (Jules)

- **Mock Pannellum**: This module interacts with Pannellum. Mock the global `window.pannellum` object in `tests/node-setup.js` or locally.

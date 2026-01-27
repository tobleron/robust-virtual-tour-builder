# Task 772: Add Unit Tests for ProjectManagerLogic.res

## 🚨 Trigger
Modifications detected in `src/systems/ProjectManagerLogic.res` without established unit tests.

## Objective
Create a Vitest file `tests/unit/ProjectManagerLogic_v.test.res` to cover logic in this module.

## Requirements
- Maintain code coverage for all exported functions.
- Follow /testing-standards.md.

## 💡 Implementation Hints for Cloud Agents (Jules)

- **EventBus Integration**: Use `EventBus.dispatch` spies to verify that actions are triggered correctly.
- **API Mocks**: Mock `fetch` and `RequestQueue.schedule`. Jules should verify that the correct endpoints are called with the expected payloads.

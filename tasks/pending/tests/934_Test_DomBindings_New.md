# Task 934: Add Unit Tests for DomBindings.res

## 🚨 Trigger
Modifications detected in `src/bindings/DomBindings.res` without established unit tests.

## Objective
Create a Vitest file `tests/unit/DomBindings_v.test.res` to cover logic in this module.

## Requirements
- Maintain code coverage for all exported functions.
- Follow /testing-standards.md.

## 💡 Implementation Hints for Cloud Agents (Jules)

- **DOM/Window Bindings**: Use `ReBindings` to mock browser-specific properties like `localStorage`, `location`, or `window.innerWidth`.

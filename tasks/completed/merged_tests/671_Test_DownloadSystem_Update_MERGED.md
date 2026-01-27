# Task 671: Update Unit Tests for DownloadSystem.res

## 🚨 Trigger
Implementation file `src/systems/DownloadSystem.res` is newer than its test file `tests/unit/DownloadSystem_v.test.res`.

## Objective
Update `tests/unit/DownloadSystem_v.test.res` to ensure it covers recent changes in `DownloadSystem.res`.

## Requirements
- Review recent changes in `src/systems/DownloadSystem.res`.
- Update tests to maintain 100% coverage of new logic.
- Follow /testing-standards.md.

## 💡 Implementation Hints for Cloud Agents (Jules)

- **DOM/Window Bindings**: Use `ReBindings` to mock browser-specific properties like `localStorage`, `location`, or `window.innerWidth`.

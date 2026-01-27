# Task 611: Update Unit Tests for HotspotActionMenu.res

## 🚨 Trigger
Implementation file `src/components/HotspotActionMenu.res` is newer than its test file `tests/unit/HotspotActionMenu_v.test.res`.

## Objective
Update `tests/unit/HotspotActionMenu_v.test.res` to ensure it covers recent changes in `HotspotActionMenu.res`.

## Requirements
- Review recent changes in `src/components/HotspotActionMenu.res`.
- Update tests to maintain 100% coverage of new logic.
- Follow /testing-standards.md.

## 💡 Implementation Hints for Cloud Agents (Jules)

- **EventBus Integration**: Use `EventBus.dispatch` spies to verify that actions are triggered correctly.

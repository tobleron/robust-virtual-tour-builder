# Task 723: Update Unit Tests for Constants.res

## 🚨 Trigger
Implementation file `src/utils/Constants.res` is newer than its test file `tests/unit/Constants_v.test.res`.

## Objective
Update `tests/unit/Constants_v.test.res` to ensure it covers recent changes in `Constants.res`.

## Requirements
- Review recent changes in `src/utils/Constants.res`.
- Update tests to maintain 100% coverage of new logic.
- Follow /testing-standards.md.

## 💡 Implementation Hints for Cloud Agents (Jules)

- **Mock FFmpeg**: This module uses FFmpeg. Ensure the FFmpeg core is mocked or its promises are resolved instantly.

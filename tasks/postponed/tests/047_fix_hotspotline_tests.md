# Task: Fix HotspotLine Tests in Vitest

## Context
During the migration to Vitest, `tests/unit/HotspotLine_v.test.res` started failing because the mock viewer object lacks the `isLoaded()` method.

## Objective
Update the mock viewer in `HotspotLine_v.test.res` (or `TestUtils.res`) to include `isLoaded: () => true` (or relevant logic).

## Error
```
TypeError: viewer.isLoaded is not a function
```

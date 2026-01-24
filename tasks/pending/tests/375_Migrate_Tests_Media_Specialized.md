# Task 375: Migrate Media & Specialized Services Tests to Vitest

## Objective
Migrate the following legacy unit tests to Vitest and ensure 100% coverage:
- `ImageOptimizerTest.res`
- `VideoEncoderTest.res`
- `AudioManagerTest.res`
- `ServerTeaserTest.res`

## Requirements
1. Create `_v.test.res` versions for each.
2. Use `Vitest` bindings and follow functional testing standards.
3. Remove/Comment out entries from `tests/TestRunner.res`.
4. Delete legacy `.res` files after migration.
5. Verify tests pass with `npm run test:frontend`.

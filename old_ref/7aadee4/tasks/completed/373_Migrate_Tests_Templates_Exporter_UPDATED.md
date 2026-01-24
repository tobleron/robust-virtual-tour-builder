# Task 373: Migrate Templates & Exporter Tests to Vitest

## Objective
Migrate the following legacy unit tests to Vitest and ensure 100% coverage:
- `ExporterTest.res`
- `TourTemplatesTest.res`
- `TourTemplateStylesTest.res`
- `ViewerLoaderTest.res`
- `ProjectDataTest.res`

## Requirements
1. Create `_v.test.res` versions for each.
2. Use `Vitest` bindings and follow functional testing standards.
3. Remove/Comment out entries from `tests/TestRunner.res`.
4. Delete legacy `.res` files after migration.
5. Verify tests pass with `npm run test:frontend`.

## Completion Report
- Migrated `ExporterTest.res` -> `tests/unit/Exporter_v.test.res`
- Migrated `TourTemplatesTest.res` -> `tests/unit/TourTemplates_v.test.res`
- Migrated `TourTemplateStylesTest.res` -> `tests/unit/TourTemplateStyles_v.test.res`
- Migrated `ViewerLoaderTest.res` -> `tests/unit/ViewerLoader_v.test.res`
- Migrated `ProjectDataTest.res` -> `tests/unit/ProjectData_v.test.res`
- Removed legacy test files.
- Updated `tests/TestRunner.res` to remove legacy calls.
- Verified all tests pass with `npm run test:frontend`.

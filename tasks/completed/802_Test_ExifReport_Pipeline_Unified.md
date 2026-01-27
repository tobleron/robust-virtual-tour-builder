# Task: 802 - Test: Exif Report Pipeline Unified Verification (New + Update)

## Objective
Verify the full EXIF extraction and reporting pipeline, from raw file processing to geocoding and report generation.

## Merged Tasks
- 788_Test_ExifReportGeneratorLogicExtraction_New.md
- 789_Test_ExifReportGeneratorLogicGroups_New.md
- 790_Test_ExifReportGeneratorLogicLocation_New.md
- 791_Test_ExifReportGeneratorLogicTypes_New.md
- 770_Test_ExifReportGeneratorTypes_New.md
- 771_Test_ExifReportGeneratorUtils_New.md
- 675_Test_ExifReportGenerator_Update.md

## Technical Context
The `ExifReportGenerator` is complex due to its multi-stage logic (Extraction -> Geo -> Groups -> Utils). Grouping these allows for better mocking of file inputs and coordinate data.

## Implementation Plan
1. **Extraction Logic**: Verify `ExifReader` integration and metadata mapping.
2. **Location Logic**: Test GPS centroid calculation and geocoding fallback paths.
3. **Grouping Logic**: Verify camera device clustering and file sorting.
4. **Utils**: Test project name generation and download triggers.
5. **Main Orchestrator**: Test the high-level response generation in `ExifReportGenerator.res`.

## Verification Criteria
- [ ] All sub-logic modules have passing vitest suites.
- [ ] Mock files with valid/invalid EXIF data are correctly handled.
- [ ] No regressions in the main report UI/logic.

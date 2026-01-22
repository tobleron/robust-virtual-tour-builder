# 🔧 Fix: Project Name "Unknown" Bug (v2)

## Changes Made

### 1. Robust Filtering in UploadProcessor.res
- Switched to an `option<string>` based check for suggested project names.
- Implemented a case-insensitive Regex check (`/Unknown/i`) to prevent any dummy names from being set as the tour name.
- Only sets the name if it is `Some(name)` and passes the "Unknown" filter.

### 2. Architecture Shift in ExifReportGenerator.res
- Changed `generateProjectName` signature to return `option<string>`.
- Instead of returning "Unknown_Location" on failure, it now returns `None`.
- This ensures downstream processors know when a meaningful name could not be generated and can decide on an appropriate fallback (like keeping the field empty).

## Diagnostics
Logs now clearly show whether a name was generated, skipped, or if no location data was found:
- `PROJECT_NAME_GENERATED_FROM_EXIF` - Shows the result (or None)
- `SETTING_PROJECT_NAME` - Confirms a valid name was applied
- `SKIPPING_UNKNOWN_PROJECT_NAME` - Confirms an invalid name was rejected
- `NO_SUGGESTED_PROJECT_NAME` - Logged when no location data was available

## Verification
- Unit tests in `ExifReportGeneratorTest.res` have been updated to verify the new `option` return type behavior.
- Verified that "Unknown_Location" is no longer produced by `generateProjectName`.

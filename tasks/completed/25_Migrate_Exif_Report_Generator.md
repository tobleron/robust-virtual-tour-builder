# Task: Migrate Exif Report Generator

## Objective
Port the `ExifReportGenerator.js` logic to ReScript to handle the detailed formatting of EXIF data into user-friendly reports.

## Context
This module takes raw EXIF JSON and produces a human-readable summary.

## Implementation Steps

1. **Create `ExifReportGenerator.res`**:
   - [x] Port the formatting functions for exposure, focal length, and GPS data.
   - [x] Implement the collapsible sections logic (text-based report).
   - [x] Fixed all compilation errors, including promise wrapping and regex types.

2. **Integration**:
   - [x] Updated `UploadProcessor.res` to call the ReScript module directly.
   - [x] Updates `UploadReport.js` to dynamically import the compiled ReScript output (`.bs.js`).

## Testing Checklist
- [x] EXIF data for a sample image shows correct "Exposure Time".
- [x] GPS coordinates are correctly formatted.
- [x] Project compiles successfully with `npm run res:build`.

## Definition of Done
- [x] `ExifReportGenerator.js` is deleted.
- [x] Report generation is 100% ReScript.

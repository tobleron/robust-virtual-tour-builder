# T1785 - Fix EXIF Fallback Hang (Strict Mode)

## Assignee: Gemini
## Capacity Class: A
## Objective
Implement 'Strict Extraction Mode' to prevent redundant local file re-reading during background project titling.

## Context
Fixed the UI hang by bypassing EXIF report generation in the foreground, but the background task still had a fallback that could cause RAM spikes by re-reading 40MB files if metadata was missing.

## Strategy
1.  **Refactor Extraction**: Update `ExifReportGeneratorLogicExtraction.res` to remove the local file extraction fallback.
2.  **Strict Data**: If metadata JSON is missing from the backend response, return default empty values instead of trying to recover them locally.
3.  **Efficiency**: This ensures the background task is O(1) regarding disk I/O.

## Verification
- Verified that background titling still works when metadata is present.
- Verified that missing metadata returns defaults without hanging or spiking CPU.
- Unit tests updated to verify Strict Mode behavior.

## Result
Complete. All background metadata resolution now uses a zero-disk-I/O path.

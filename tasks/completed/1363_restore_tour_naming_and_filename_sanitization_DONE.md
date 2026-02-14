# Task: Restore Tour Naming and Filename Sanitization

## Objective
Restore and refine legacy features for **Tour Name Auto-Population** and **Filename Sanitization** that were lost in recent updates. The new implementation must align with specific user requirements for "PureShot" filename formats and use a robust fallback mechanism for location services.

## Context & Investigation So Far
The user identified two regressions from v4.0.0:
1.  **Tour Name not auto-populating**: Originally calculated from the average GPS location of uploaded images -> Reverse Geocoded -> "First 3 words" + Timestamp.
    *   *Investigation*: Traced to `ExifParser.res` relying on a backend geocoding endpoint that is currently failing.
    *   *Partial Fix Applied*: Added an **OSM (OpenStreetMap) client-side fallback** in `ExifParser.res` to fetch address data when backend fails.
2.  **Filenames not being sanitized**: User requires a specific "short" format.
    *   *Investigation*: `ResizerLogic.res` had lost the legacy regex extraction logic.
    *   *Partial Fix Applied*: Restored the v4.0.0 regex `_(\d{6})_\d{2}_(\d{3})`.
    *   *Current Gap*: The user provided a specific "PureShot" format example (`IMG_20251223_154407_00_002_PureShot.jpg` -> `IMG_4407_002.jpg`) which requires a **new, specific regex strategy** (extracting last 4 digits of time + sequence).

## Requirements

### 1. Filename Sanitization (Sidebar)
*   **Input Format**: `IMG_YYYYMMDD_HHMMSS_XX_SSS_Suffix.jpg` (e.g., `IMG_20251223_154407_00_002_PureShot.jpg`)
*   **Target Output**: `IMG_{MMSS}_{SSS}.jpg` (e.g., `IMG_4407_002.jpg`)
    *   Extract last 4 digits of the timestamp block (`154407` -> `4407`).
    *   Extract the sequence number (`002`).
    *   Combine: `IMG_` + `4407` + `_` + `002`.
*   **Implementation**: Update `ResizerLogic.res` to handle this specific pattern alongside the legacy pattern if needed.

### 2. Tour Name Auto-Population
*   **Trigger**: On upload completion, if Tour Name is "Untitled" or "Unknown".
*   **Logic**:
    1.  Calculate **Average GPS Location** of all valid images in the upload batch.
    2.  **Reverse Geocode** coordinates to an address string (Backend first -> OSM Fallback).
    3.  **Extract Location Words**: Take the **first 3 words** of the resolved address.
    4.  **Generate Timestamp**: Short format (e.g., `DDMM_HHMM`).
    5.  **Format**: `{Location_Words}_{Timestamp}`.
*   **Implementation**: Verify `ExifReportGenerator.res` and `ExifParser.res` implement this exact "3 word" extraction and formatting logic.

## Acceptance Criteria
- [ ] Uploading "PureShot" style images results in sanitized filenames (e.g., `IMG_4407_002.jpg`) in the Sidebar.
- [ ] Uploading images with GPS data automatically updates the Tour Name (if previously unset).
- [ ] Tour Name format follows: `[First 3 Words of Address]_[Timestamp]`.
- [ ] Location lookup works even if backend geocoding fails (via OSM fallback).
- [ ] "Average Location" calculation correctly handles multiple images.

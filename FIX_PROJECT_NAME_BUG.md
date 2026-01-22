# 🔧 Fix: Project Name "Unknown" Bug

## Changes Made

### 1. Enhanced Logging in UploadProcessor.res
**File**: `src/systems/UploadProcessor.res`

Added comprehensive logging to track project name generation:
- Logs when project name is generated from EXIF report
- Logs current vs suggested name comparison
- **Prevents setting "Unknown_Location" as project name**
- Warns when skipping invalid project names

**Key Change**:
```rescript
// Only set project name if it's meaningful (not Unknown_Location)
if res.suggestedName != "" && !String.includes(res.suggestedName, "Unknown") {
  // Set the name
} else {
  Logger.warn(~module_="Upload", ~message="SKIPPING_UNKNOWN_PROJECT_NAME", ...)
}
```

### 2. Added GPS Detection Logging in ExifReportGenerator.res
**File**: `src/systems/ExifReportGenerator.res`

Added logging to diagnose GPS extraction issues:
- Warns when no GPS data is found in uploaded images
- Logs geocoding success with coordinates and address
- Logs geocoding failures with error details
- Logs final project name generation with all inputs

## Root Cause Analysis

The bug occurs when:
1. **No GPS data** in uploaded images (location services disabled)
2. **Geocoding fails** (backend offline, API error, invalid coordinates)
3. **EXIF stripped** during compression (though we preserve it separately)

When any of these occur, the system generates `"Unknown_Location_DDMMYY_HHMM"` which was being set as the project name.

## Fix Strategy

### Immediate Fix (Implemented)
- **Skip setting project name if it contains "Unknown"**
- This prevents the ugly "Unknown_Location" from appearing in the UI
- User sees empty field with placeholder "New Tour..." instead

### Diagnostic Improvements
- Added logging at every step of the process
- Can now trace exactly where the issue occurs:
  - GPS extraction from EXIF
  - Geocoding API call
  - Project name generation
  - State update

## Testing Instructions

### Test Case 1: Images WITH GPS Data
1. Upload images with GPS EXIF metadata
2. Check browser console for logs:
   - `GEOCODING_SUCCESS` - Should show lat/lon and address
   - `PROJECT_NAME_GENERATED_FROM_EXIF` - Should show meaningful name
   - `SETTING_PROJECT_NAME` - Should set the location-based name
3. **Expected**: Project name shows location + timestamp (e.g., "Beverly_Hills_CA_220122_1430")

### Test Case 2: Images WITHOUT GPS Data
1. Upload images without GPS metadata
2. Check browser console for logs:
   - `NO_GPS_DATA_FOUND` - Should warn about missing GPS
   - `PROJECT_NAME_GENERATED_FROM_EXIF` - Should show "Unknown_Location_..."
   - `SKIPPING_UNKNOWN_PROJECT_NAME` - Should skip setting the name
3. **Expected**: Project name field remains empty, shows placeholder "New Tour..."

### Test Case 3: Geocoding Failure
1. Stop the backend server (to simulate geocoding failure)
2. Upload images with GPS data
3. Check browser console for logs:
   - `GEOCODING_FAILED` - Should show error message
   - `SKIPPING_UNKNOWN_PROJECT_NAME` - Should skip setting the name
4. **Expected**: Project name field remains empty

## Monitoring Logs

Open browser console and filter for these messages:
- `NO_GPS_DATA_FOUND` - No GPS in images
- `GEOCODING_SUCCESS` - Address lookup worked
- `GEOCODING_FAILED` - Address lookup failed
- `PROJECT_NAME_GENERATED_FROM_EXIF` - Final name generated
- `SETTING_PROJECT_NAME` - Name being set
- `SKIPPING_UNKNOWN_PROJECT_NAME` - Name rejected

## Next Steps

### If GPS Data is Present but Geocoding Fails:
1. Check backend logs for geocoding errors
2. Verify Google Maps API key is valid
3. Check network connectivity to geocoding service
4. Verify backend geocoding proxy is working

### If No GPS Data in Images:
1. Verify images were taken with location services enabled
2. Check if EXIF data is being stripped by camera/app
3. Consider using images from a different source
4. Document that GPS is required for auto-naming

### Future Enhancements:
1. Add fallback to use first 3 words of filename if no GPS
2. Add manual location entry option
3. Cache geocoding results to reduce API calls
4. Add progress indicator for geocoding operation

## Files Modified

1. `/src/systems/UploadProcessor.res` - Enhanced name setting logic
2. `/src/systems/ExifReportGenerator.res` - Added diagnostic logging
3. `/BUG_ANALYSIS_PROJECT_NAME.md` - Root cause analysis document

## Verification

Run the development server and test with sample images:
```bash
npm run dev
```

Then upload images and check the console for the new log messages.
